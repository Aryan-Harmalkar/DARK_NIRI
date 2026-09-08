#[path = "../common.rs"]
mod common;

use chrono::{Local, NaiveDate};
use common::{fmt_bytes, get_boot_id, is_physical_interface};
use serde::{Deserialize, Serialize};
use std::collections::{BTreeMap, HashMap};
use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

#[derive(Serialize, Deserialize, Debug, Clone, Default)]
struct InterfaceStat {
    #[serde(default)]
    rx: u64,
    #[serde(default)]
    tx: u64,
}

#[derive(Serialize, Deserialize, Debug, Clone, Default)]
struct TrafficStat {
    #[serde(default)]
    rx: u64,
    #[serde(default)]
    tx: u64,
}

#[derive(Serialize, Deserialize, Debug, Default)]
struct LoggerState {
    #[serde(default)]
    boot_id: String,
    #[serde(default)]
    iface_stats: HashMap<String, InterfaceStat>,
    #[serde(default)]
    records: BTreeMap<String, BTreeMap<String, BTreeMap<String, TrafficStat>>>,
}

fn get_home_dir() -> PathBuf {
    let home = env::var("HOME").unwrap_or_else(|_| "/home/aryan".to_string());
    PathBuf::from(home)
}

fn get_active_network_for_interface(iface: &str) -> String {
    if let Ok(out) = Command::new("nmcli")
        .args(["-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "dev"])
        .output()
    {
        if let Ok(text) = String::from_utf8(out.stdout) {
            for line in text.lines() {
                let line = line.trim();
                if line.is_empty() {
                    continue;
                }
                let parts: Vec<&str> = line.split(':').collect();
                if parts.len() >= 4 && parts[0] == iface && parts[2].contains("connected") {
                    let conn_name = parts[3].trim();
                    let dev_type = parts[1].trim().to_lowercase();
                    if !conn_name.is_empty() {
                        return conn_name.to_string();
                    }
                    if dev_type == "wifi" {
                        return "Wi-Fi".to_string();
                    } else if dev_type == "ethernet" {
                        return "Ethernet".to_string();
                    }
                }
            }
        }
    }

    // Fallback heuristic based on interface name
    if iface.starts_with("wlan") || iface.starts_with("wlp") {
        if let Ok(out) = Command::new("iwgetid").arg("-r").output() {
            if let Ok(ssid) = String::from_utf8(out.stdout) {
                let s = ssid.trim();
                if !s.is_empty() {
                    return s.to_string();
                }
            }
        }
        return "Wi-Fi".to_string();
    } else if iface.starts_with("usb") || iface.starts_with("enx") {
        return "USB Tethering".to_string();
    } else if iface.starts_with("enp") || iface.starts_with("eth") || iface.starts_with("eno") {
        return "Ethernet".to_string();
    } else if iface.starts_with("wwan") || iface.starts_with("wwp") {
        return "Cellular".to_string();
    }

    "Network".to_string()
}

fn render_month_markdown(
    month_str: &str,
    month_records: &BTreeMap<String, BTreeMap<String, TrafficStat>>,
    consumption_dir: &Path,
) {
    let _ = fs::create_dir_all(consumption_dir);
    let md_file = consumption_dir.join(format!("{}.md", month_str));

    let month_name = NaiveDate::parse_from_str(&format!("{}-01", month_str), "%Y-%m-%d")
        .map(|d| d.format("%B %Y").to_string())
        .unwrap_or_else(|_| month_str.to_string());

    let mut lines = Vec::new();
    lines.push(format!("# Internet Data Consumption - {}", month_name));
    lines.push(String::new());
    lines.push("| Date | Wi-Fi / Network | Downloaded | Uploaded | Total |".to_string());
    lines.push("| :--- | :--- | :--- | :--- | :--- |".to_string());

    let mut total_month_rx: u64 = 0;
    let mut total_month_tx: u64 = 0;

    let has_records = !month_records.is_empty();

    for (date, networks) in month_records {
        for (net, stats) in networks {
            let total = stats.rx + stats.tx;
            total_month_rx += stats.rx;
            total_month_tx += stats.tx;
            lines.push(format!(
                "| {} | {} | {} | {} | {} |",
                date,
                net,
                fmt_bytes(stats.rx),
                fmt_bytes(stats.tx),
                fmt_bytes(total)
            ));
        }
    }

    if !has_records {
        let today = Local::now().format("%Y-%m-%d").to_string();
        lines.push(format!("| {} | No active traffic | 0 B | 0 B | 0 B |", today));
    }

    lines.push(String::new());
    lines.push("### Monthly Summary".to_string());
    lines.push(format!("- **Total Downloaded**: `{}`", fmt_bytes(total_month_rx)));
    lines.push(format!("- **Total Uploaded**: `{}`", fmt_bytes(total_month_tx)));
    lines.push(format!(
        "- **Grand Total**: `{}`",
        fmt_bytes(total_month_rx + total_month_tx)
    ));
    lines.push(String::new());
    lines.push(format!(
        "*Last updated: {}*",
        Local::now().format("%Y-%m-%d %H:%M:%S")
    ));
    lines.push(String::new());

    let content = lines.join("\n");
    let tmp_file = consumption_dir.join(format!("{}.md.tmp", month_str));
    if fs::write(&tmp_file, content).is_ok() {
        let _ = fs::rename(&tmp_file, &md_file);
    }
}

fn update_data_consumption() {
    let home = get_home_dir();
    let consumption_dir = home.join("Data Consumption");
    let state_dir = home.join(".local/share/quickshell");
    let _ = fs::create_dir_all(&state_dir);
    let state_file = state_dir.join("network_logger_state.json");

    let now = Local::now();
    let cur_month = now.format("%Y-%m").to_string();
    let cur_date = now.format("%Y-%m-%d").to_string();
    let cur_boot_id = get_boot_id();

    let mut state: LoggerState = if state_file.exists() {
        fs::read_to_string(&state_file)
            .ok()
            .and_then(|s| serde_json::from_str(&s).ok())
            .unwrap_or_default()
    } else {
        LoggerState::default()
    };

    let is_new_boot = state.boot_id != cur_boot_id;

    if let Ok(entries) = fs::read_dir("/sys/class/net") {
        for entry in entries.flatten() {
            let path = entry.path();
            if !is_physical_interface(&path) {
                continue;
            }

            let iface = match path.file_name().and_then(|n| n.to_str()) {
                Some(name) => name.to_string(),
                None => continue,
            };

            let rx = fs::read_to_string(path.join("statistics/rx_bytes"))
                .ok()
                .and_then(|s| s.trim().parse::<u64>().ok())
                .unwrap_or(0);
            let tx = fs::read_to_string(path.join("statistics/tx_bytes"))
                .ok()
                .and_then(|s| s.trim().parse::<u64>().ok())
                .unwrap_or(0);

            let (delta_rx, delta_tx) = match state.iface_stats.get(&iface) {
                None => {
                    // Newly detected interface
                    state.iface_stats.insert(iface.clone(), InterfaceStat { rx, tx });
                    (0, 0)
                }
                Some(prev) => {
                    let drx = if is_new_boot {
                        rx
                    } else if rx >= prev.rx {
                        rx - prev.rx
                    } else {
                        rx
                    };
                    let dtx = if is_new_boot {
                        tx
                    } else if tx >= prev.tx {
                        tx - prev.tx
                    } else {
                        tx
                    };
                    state.iface_stats.insert(iface.clone(), InterfaceStat { rx, tx });
                    (drx, dtx)
                }
            };

            if delta_rx > 0 || delta_tx > 0 {
                let net_name = get_active_network_for_interface(&iface);
                let month_map = state.records.entry(cur_month.clone()).or_default();
                let day_map = month_map.entry(cur_date.clone()).or_default();
                let stat = day_map.entry(net_name).or_default();
                stat.rx += delta_rx;
                stat.tx += delta_tx;
            }
        }
    }

    state.boot_id = cur_boot_id;

    // Atomic write state
    let tmp_state = state_dir.join("network_logger_state.json.tmp");
    if let Ok(json_str) = serde_json::to_string_pretty(&state) {
        if fs::write(&tmp_state, json_str).is_ok() {
            let _ = fs::rename(&tmp_state, &state_file);
        }
    }

    // Render markdown table
    let empty_records = BTreeMap::new();
    let month_records = state.records.get(&cur_month).unwrap_or(&empty_records);
    render_month_markdown(&cur_month, month_records, &consumption_dir);
}

fn show_current_month() {
    let home = get_home_dir();
    let cur_month = Local::now().format("%Y-%m").to_string();
    let md_file = home.join("Data Consumption").join(format!("{}.md", cur_month));
    if let Ok(content) = fs::read_to_string(&md_file) {
        print!("{}", content);
    } else {
        println!("No records found yet for {}.", cur_month);
    }
}

fn main() {
    let action = env::args().nth(1).unwrap_or_else(|| "--update".to_string());

    if action == "--show" {
        update_data_consumption();
        show_current_month();
    } else {
        update_data_consumption();
    }
}
