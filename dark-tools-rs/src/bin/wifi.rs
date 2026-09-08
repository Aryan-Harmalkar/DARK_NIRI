use serde::{Deserialize, Serialize};
use std::collections::HashSet;
use std::env;
use std::fs;
use std::process::Command;

const WPS_CACHE_FILE: &str = "/tmp/wps_seen.json";

#[derive(Serialize, Deserialize, Debug)]
struct NetworkInfo {
    ssid: String,
    band: String,
    signal: u32,
    security: String,
    connected: bool,
    saved: bool,
    wps: bool,
}

#[derive(Serialize, Deserialize, Debug)]
struct WifiStatus {
    enabled: bool,
    networks: Vec<NetworkInfo>,
}

fn notify(summary: &str, body: &str, icon: &str, critical: bool) {
    let mut cmd = Command::new("notify-send");
    cmd.arg(summary).arg(body).arg("-i").arg(icon);
    if critical {
        cmd.arg("-u").arg("critical");
    }
    let _ = cmd.spawn();
}

fn notify_wps(ssid: &str) {
    let mut seen: Vec<String> = if let Ok(data) = fs::read_to_string(WPS_CACHE_FILE) {
        serde_json::from_str(&data).unwrap_or_default()
    } else {
        Vec::new()
    };

    if !seen.contains(&ssid.to_string()) {
        seen.push(ssid.to_string());
        if let Ok(json_str) = serde_json::to_string(&seen) {
            let _ = fs::write(WPS_CACHE_FILE, json_str);
        }
        notify("Wi-Fi WPS", &format!("WPS ON detected for {}", ssid), "network-wireless", false);
    }
}

fn get_wifi_device() -> String {
    if let Ok(out) = Command::new("nmcli").args(["-t", "-f", "DEVICE,TYPE", "dev"]).output() {
        if let Ok(text) = String::from_utf8(out.stdout) {
            for line in text.lines() {
                let parts: Vec<&str> = line.split(':').collect();
                if parts.len() >= 2 && parts[1].trim() == "wifi" {
                    return parts[0].trim().to_string();
                }
            }
        }
    }
    "wlan0".to_string()
}

fn get_wifi() -> WifiStatus {
    let wifi_enabled = Command::new("nmcli")
        .args(["radio", "wifi"])
        .output()
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .map(|s| s.trim() == "enabled")
        .unwrap_or(false);

    let mut saved = HashSet::new();
    if let Ok(out) = Command::new("nmcli").args(["-t", "-f", "NAME,TYPE", "connection", "show"]).output() {
        if let Ok(text) = String::from_utf8(out.stdout) {
            for line in text.lines() {
                let parts: Vec<&str> = line.split(':').collect();
                if parts.len() >= 2 && parts[1].contains("wireless") {
                    saved.insert(parts[0].to_string());
                }
            }
        }
    }

    let mut networks = Vec::new();
    let mut seen = HashSet::new();

    if let Ok(out) = Command::new("nmcli")
        .args(["-t", "-f", "SSID,BAND,FREQ,SIGNAL,SECURITY,IN-USE,DBUS-PATH", "dev", "wifi", "list"])
        .output()
    {
        if let Ok(text) = String::from_utf8(out.stdout) {
            for line in text.lines() {
                let line = line.trim();
                if line.is_empty() {
                    continue;
                }
                let parts: Vec<&str> = line.split(':').collect();
                if parts.len() >= 6 {
                    let ssid = parts[0].trim();
                    if ssid.is_empty() || seen.contains(ssid) {
                        continue;
                    }
                    seen.insert(ssid.to_string());

                    let band = if parts.len() > 1 && !parts[1].trim().is_empty() {
                        parts[1].trim()
                    } else {
                        "2.4 GHz"
                    };

                    let signal: u32 = if parts.len() > 3 {
                        parts[3].trim().parse().unwrap_or(0)
                    } else {
                        0
                    };

                    let sec_raw = if parts.len() > 4 { parts[4].trim() } else { "" };
                    let security = if sec_raw.is_empty() { "Open" } else { sec_raw };

                    let connected = parts.len() > 5 && parts[5].trim() == "*";
                    let dbus_path = if parts.len() > 6 { parts[6].trim() } else { "" };

                    let mut has_wps = false;
                    if !dbus_path.is_empty() {
                        if let Ok(ap_out) = Command::new("gdbus")
                            .args([
                                "call",
                                "--system",
                                "--dest",
                                "org.freedesktop.NetworkManager",
                                "--object-path",
                                dbus_path,
                                "--method",
                                "org.freedesktop.DBus.Properties.Get",
                                "org.freedesktop.NetworkManager.AccessPoint",
                                "Flags",
                            ])
                            .output()
                        {
                            if ap_out.status.success() {
                                if let Ok(s) = String::from_utf8(ap_out.stdout) {
                                    if let Some(pos) = s.find("uint32") {
                                        let clean_num: String = s[pos + 6..]
                                            .chars()
                                            .filter(|c| c.is_ascii_digit())
                                            .collect();
                                        if let Ok(val) = clean_num.parse::<u32>() {
                                            if (val & 0xE) != 0 {
                                                has_wps = true;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if has_wps {
                        notify_wps(ssid);
                    }

                    networks.push(NetworkInfo {
                        ssid: ssid.to_string(),
                        band: band.to_string(),
                        signal,
                        security: security.to_string(),
                        connected,
                        saved: saved.contains(ssid),
                        wps: has_wps,
                    });
                }
            }
        }
    }

    WifiStatus {
        enabled: wifi_enabled,
        networks,
    }
}

fn connect(ssid: &str, password: Option<&str>) -> bool {
    let mut cmd = Command::new("nmcli");
    cmd.args(["dev", "wifi", "connect", ssid]);
    if let Some(pwd) = password {
        cmd.args(["password", pwd]);
    }

    let res = cmd.output();
    match res {
        Ok(out) if out.status.success() => {
            notify("Wi-Fi", &format!("Connected to {}", ssid), "network-wireless", false);
            true
        }
        Ok(out) => {
            let stderr = String::from_utf8_lossy(&out.stderr);
            let stdout = String::from_utf8_lossy(&out.stdout);
            let raw_err = if !stderr.trim().is_empty() {
                stderr.trim()
            } else if !stdout.trim().is_empty() {
                stdout.trim()
            } else {
                "Failed to connect"
            };
            let mut err_msg = raw_err.replace("Error: ", "");
            if err_msg.len() > 90 {
                err_msg.truncate(87);
                err_msg.push_str("...");
            }
            notify("Wi-Fi Connection Failed", &err_msg, "network-wireless-offline", true);
            false
        }
        Err(_) => {
            notify("Wi-Fi Connection Failed", "Command execution failed", "network-wireless-offline", true);
            false
        }
    }
}

fn connect_wps(ssid: &str) -> bool {
    let res = Command::new("nmcli").args(["dev", "wifi", "connect", ssid]).output();
    match res {
        Ok(out) if out.status.success() => {
            notify("Wi-Fi", &format!("Connected to {}", ssid), "network-wireless", false);
            true
        }
        Ok(out) => {
            let stderr = String::from_utf8_lossy(&out.stderr);
            let stdout = String::from_utf8_lossy(&out.stdout);
            let raw_err = if !stderr.trim().is_empty() {
                stderr.trim()
            } else if !stdout.trim().is_empty() {
                stdout.trim()
            } else {
                "Connection failed"
            };
            let mut err_msg = raw_err.replace("Error: ", "");
            if err_msg.len() > 90 {
                err_msg.truncate(87);
                err_msg.push_str("...");
            }
            notify("Wi-Fi Connection Failed", &err_msg, "network-wireless-offline", true);
            false
        }
        Err(_) => {
            notify("Wi-Fi Connection Failed", "Command execution failed", "network-wireless-offline", true);
            false
        }
    }
}

fn connect_rofi(ssid: &str) -> bool {
    let home = env::var("HOME").unwrap_or_else(|_| "/home/aryan".to_string());
    let rofi_theme = format!("{}/DARK_NIRI/rofi/config.rasi", home);

    if let Ok(out) = Command::new("rofi")
        .args(["-dmenu", "-password", "-p", &format!("Wi-Fi: {}", ssid), "-theme", &rofi_theme])
        .output()
    {
        if let Ok(pwd) = String::from_utf8(out.stdout) {
            let pwd_trimmed = pwd.trim();
            if !pwd_trimmed.is_empty() {
                return connect(ssid, Some(pwd_trimmed));
            }
        }
    }
    false
}

fn disconnect() -> bool {
    let dev = get_wifi_device();
    let res = Command::new("nmcli").args(["dev", "disconnect", &dev]).output();
    if let Ok(out) = res {
        if out.status.success() {
            notify("Wi-Fi", "Disconnected from Wi-Fi", "network-wireless-disconnected", false);
            return true;
        }
    }
    false
}

fn forget(ssid: &str) -> bool {
    let res = Command::new("nmcli").args(["connection", "delete", ssid]).output();
    if let Ok(out) = res {
        if out.status.success() {
            notify("Wi-Fi", &format!("Forgot network {}", ssid), "edit-delete", false);
            return true;
        }
    }
    false
}

fn toggle() {
    let status = Command::new("nmcli")
        .args(["radio", "wifi"])
        .output()
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .map(|s| s.trim().to_string())
        .unwrap_or_default();

    let new_state = if status == "enabled" { "off" } else { "on" };
    let _ = Command::new("nmcli").args(["radio", "wifi", new_state]).output();
    let state_str = if new_state == "on" { "Enabled" } else { "Disabled" };
    notify("Wi-Fi Radio", &format!("Wi-Fi has been {}", state_str), "network-wireless", false);
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let action = args.get(1).map(|s| s.as_str()).unwrap_or("list");

    match action {
        "list" => {
            let status = get_wifi();
            println!("{}", serde_json::to_string(&status).unwrap_or_else(|_| "{}".to_string()));
        }
        "toggle" => {
            toggle();
        }
        "disconnect" => {
            disconnect();
        }
        "forget" => {
            if let Some(ssid) = args.get(2) {
                forget(ssid);
            }
        }
        "connect" => {
            if let Some(ssid) = args.get(2) {
                let pwd = args.get(3).map(|s| s.as_str());
                connect(ssid, pwd);
            }
        }
        "connect-rofi" => {
            if let Some(ssid) = args.get(2) {
                connect_rofi(ssid);
            }
        }
        "wps" => {
            if let Some(ssid) = args.get(2) {
                connect_wps(ssid);
            }
        }
        "rescan" => {
            let _ = Command::new("nmcli").args(["dev", "wifi", "rescan"]).output();
            let status = get_wifi();
            println!("{}", serde_json::to_string(&status).unwrap_or_else(|_| "{}".to_string()));
        }
        _ => {
            let status = get_wifi();
            println!("{}", serde_json::to_string(&status).unwrap_or_else(|_| "{}".to_string()));
        }
    }
}
