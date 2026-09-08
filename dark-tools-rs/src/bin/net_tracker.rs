#[path = "../common.rs"]
mod common;

use chrono::Local;
use common::{fmt_bytes, get_boot_id, is_physical_interface};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::env;
use std::fs;
use std::path::PathBuf;
use std::process::Command;

#[derive(Serialize, Deserialize, Debug, Default)]
struct UsageData {
    #[serde(default)]
    boot_id: String,
    #[serde(default)]
    date: String,
    #[serde(default)]
    month: String,
    #[serde(default)]
    day_bytes: u64,
    #[serde(default)]
    month_bytes: u64,
    #[serde(default)]
    ifaces: HashMap<String, u64>,
}

fn get_data_dir() -> PathBuf {
    let home = env::var("HOME").unwrap_or_else(|_| "/home/aryan".to_string());
    PathBuf::from(home).join(".local/share/quickshell")
}

fn update_usage() -> (u64, u64) {
    let data_dir = get_data_dir();
    let _ = fs::create_dir_all(&data_dir);
    let usage_file = data_dir.join("network_usage.json");

    let now = Local::now();
    let cur_date = now.format("%Y-%m-%d").to_string();
    let cur_month = now.format("%Y-%m").to_string();
    let boot_id = get_boot_id();

    let mut data: UsageData = if usage_file.exists() {
        fs::read_to_string(&usage_file)
            .ok()
            .and_then(|s| serde_json::from_str(&s).ok())
            .unwrap_or_default()
    } else {
        UsageData::default()
    };

    let is_new_boot = data.boot_id != boot_id;

    // Rollover logic
    if data.date != cur_date {
        data.day_bytes = 0;
        data.date = cur_date.clone();
    }
    if data.month != cur_month {
        data.month_bytes = 0;
        data.month = cur_month.clone();
    }

    let mut total_delta: u64 = 0;

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

            let rx_bytes = fs::read_to_string(path.join("statistics/rx_bytes"))
                .ok()
                .and_then(|s| s.trim().parse::<u64>().ok())
                .unwrap_or(0);
            let tx_bytes = fs::read_to_string(path.join("statistics/tx_bytes"))
                .ok()
                .and_then(|s| s.trim().parse::<u64>().ok())
                .unwrap_or(0);

            let total = rx_bytes + tx_bytes;

            let delta = match data.ifaces.get(&iface) {
                None => {
                    // Newly detected interface: set baseline without adding past uptime
                    data.ifaces.insert(iface.clone(), total);
                    0
                }
                Some(&prev) => {
                    let d = if is_new_boot {
                        // System rebooted: kernel counter started from 0
                        total
                    } else if total >= prev {
                        total - prev
                    } else {
                        // Counter wrapped or interface reconnected
                        total
                    };
                    data.ifaces.insert(iface.clone(), total);
                    d
                }
            };

            total_delta += delta;
        }
    }

    data.boot_id = boot_id;
    data.day_bytes += total_delta;
    data.month_bytes += total_delta;

    // Atomic write
    let tmp_file = data_dir.join("network_usage.json.tmp");
    if let Ok(json_str) = serde_json::to_string_pretty(&data) {
        if fs::write(&tmp_file, json_str).is_ok() {
            let _ = fs::rename(&tmp_file, &usage_file);
        }
    }

    // Trigger daily logger in the background
    trigger_daily_logger();

    (data.day_bytes, data.month_bytes)
}

fn trigger_daily_logger() {
    let home = env::var("HOME").unwrap_or_else(|_| "/home/aryan".to_string());
    
    // Check candidate paths for daily-network-logger binary or script
    let candidates = [
        // 1. Rust compiled binary in quickshell directory
        PathBuf::from(&home).join("DARK_NIRI/quickshell/daily-network-logger"),
        // 2. Binary in current executable's directory
        env::current_exe()
            .ok()
            .and_then(|p| p.parent().map(|dir| dir.join("daily-network-logger")))
            .unwrap_or_else(|| PathBuf::from("daily-network-logger")),
    ];

    for candidate in &candidates {
        if candidate.exists() {
            let _ = Command::new(candidate)
                .arg("--update")
                .spawn();
            break;
        }
    }
}

fn get_active_network() -> (String, String) {
    let output = Command::new("nmcli")
        .args(["-t", "-f", "TYPE,STATE,CONNECTION,DEVICE", "dev"])
        .output();

    if let Ok(out) = output {
        if let Ok(text) = String::from_utf8(out.stdout) {
            for line in text.lines() {
                let line = line.trim();
                if line.is_empty() {
                    continue;
                }
                let parts: Vec<&str> = line.split(':').collect();
                if parts.len() >= 3 && parts[1].contains("connected") {
                    let t = parts[0].to_lowercase();
                    let conn = parts[2].trim();
                    let dev = if parts.len() > 3 { parts[3].trim() } else { "" };

                    if dev == "lo" || t.contains("loopback") {
                        continue;
                    }

                    if t == "wifi" {
                        return ("wifi".to_string(), conn.to_string());
                    } else if t == "ethernet" {
                        let dev_lower = dev.to_lowercase();
                        let conn_lower = conn.to_lowercase();
                        if dev_lower.contains("usb")
                            || dev_lower.contains("enx")
                            || dev_lower.contains("rndis")
                            || conn_lower.contains("usb")
                        {
                            let name = if conn.is_empty() { "USB Tethering" } else { conn };
                            return ("usb".to_string(), name.to_string());
                        } else {
                            let name = if conn.is_empty() { "Ethernet" } else { conn };
                            return ("ethernet".to_string(), name.to_string());
                        }
                    } else if ["gsm", "cdma", "wwan"].contains(&t.as_str()) {
                        let name = if conn.is_empty() { "Cellular" } else { conn };
                        return ("cellular".to_string(), name.to_string());
                    }
                }
            }
        }
    }

    ("none".to_string(), "Disconnected".to_string())
}

fn main() {
    let action = env::args().nth(1).unwrap_or_else(|| "--get".to_string());

    match action.as_str() {
        "--update" => {
            update_usage();
        }
        "--type" => {
            let (net_type, net_name) = get_active_network();
            println!("{}|{}", net_type, net_name);
        }
        _ => {
            let (day_bytes, month_bytes) = update_usage();
            println!("{}|{}", fmt_bytes(day_bytes), fmt_bytes(month_bytes));
        }
    }
}
