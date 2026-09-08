use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet};
use std::env;
use std::process::{Command, Stdio};

#[derive(Serialize, Deserialize, Debug, Clone)]
struct ProfileInfo {
    id: String,
    name: String,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
struct DeviceInfo {
    mac: String,
    name: String,
    icon: String,
    connected: bool,
    paired: bool,
    battery: Option<u32>,
    active_profile: String,
    profiles: Vec<ProfileInfo>,
}

#[derive(Serialize, Deserialize, Debug)]
struct BluetoothStatus {
    enabled: bool,
    discovering: bool,
    devices: Vec<DeviceInfo>,
}

struct CardInfo {
    active: String,
    profiles: Vec<ProfileInfo>,
}

fn get_pactl_cards() -> HashMap<String, CardInfo> {
    let mut cards = HashMap::new();
    let out = match Command::new("pactl").args(["list", "cards"]).output() {
        Ok(o) => String::from_utf8_lossy(&o.stdout).to_string(),
        Err(_) => return cards,
    };

    for block in out.split("Card #") {
        if !block.contains("bluez_card") {
            continue;
        }

        let mac = if let Some(start) = block.find("bluez_card.") {
            let rest = &block[start + 11..];
            let end = rest.find(|c: char| !c.is_ascii_hexdigit() && c != '_').unwrap_or(rest.len());
            rest[..end].replace('_', ":").to_uppercase()
        } else {
            continue;
        };

        let mut active_profile = String::new();
        if let Some(pos) = block.find("Active Profile:") {
            let rest = &block[pos + 15..];
            let line = rest.lines().next().unwrap_or("");
            active_profile = line.trim().to_string();
        }

        let mut profiles = Vec::new();
        if let Some(p_start) = block.find("Profiles:") {
            let after_p = &block[p_start + 9..];
            let p_section = if let Some(p_end) = after_p.find("Active Profile:") {
                &after_p[..p_end]
            } else {
                after_p
            };

            for line in p_section.lines() {
                let trimmed = line.trim();
                if let Some(colon_pos) = trimmed.find(':') {
                    let p_id = trimmed[..colon_pos].trim();
                    if p_id == "off" {
                        continue;
                    }

                    let rest = trimmed[colon_pos + 1..].trim();
                    let raw_name = if let Some(paren_pos) = rest.find('(') {
                        rest[..paren_pos].trim()
                    } else {
                        rest
                    };

                    let p_label = if p_id.contains("a2dp") {
                        "High Fidelity (A2DP)".to_string()
                    } else if p_id.contains("headset") {
                        "Headset / Mic (HSP/HFP)".to_string()
                    } else {
                        raw_name.to_string()
                    };

                    if !profiles.iter().any(|p: &ProfileInfo| p.name == p_label) {
                        profiles.push(ProfileInfo {
                            id: p_id.to_string(),
                            name: p_label,
                        });
                    }
                }
            }
        }

        cards.insert(mac, CardInfo {
            active: active_profile,
            profiles,
        });
    }

    cards
}

fn get_bt() -> BluetoothStatus {
    let show_out = Command::new("bluetoothctl")
        .arg("show")
        .output()
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .unwrap_or_default();

    let enabled = show_out.contains("Powered: yes");
    let discovering = show_out.contains("Discovering: yes");

    let bt_cards = get_pactl_cards();

    let mut devices = Vec::new();
    let mut seen = HashSet::new();

    if let Ok(out) = Command::new("bluetoothctl").arg("devices").output() {
        if let Ok(text) = String::from_utf8(out.stdout) {
            for line in text.lines() {
                let trimmed = line.trim();
                if trimmed.is_empty() {
                    continue;
                }
                let parts: Vec<&str> = trimmed.splitn(3, ' ').collect();
                if parts.len() >= 3 && parts[0] == "Device" {
                    let mac = parts[1].to_uppercase();
                    let name = parts[2].to_string();

                    if seen.contains(&mac) {
                        continue;
                    }
                    seen.insert(mac.clone());

                    let info_out = Command::new("bluetoothctl")
                        .args(["info", &mac])
                        .output()
                        .ok()
                        .and_then(|o| String::from_utf8(o.stdout).ok())
                        .unwrap_or_default();

                    let connected = info_out.contains("Connected: yes");
                    let paired = info_out.contains("Paired: yes");

                    let icon = if let Some(pos) = info_out.find("Icon:") {
                        let rest = &info_out[pos + 5..];
                        rest.lines().next().unwrap_or("generic").trim().to_string()
                    } else {
                        "generic".to_string()
                    };

                    let battery = if let Some(pos) = info_out.find("Battery Percentage:") {
                        let rest = &info_out[pos + 19..];
                        if let Some(open_p) = rest.find('(') {
                            if let Some(close_p) = rest[open_p..].find(')') {
                                rest[open_p + 1..open_p + close_p].trim().parse::<u32>().ok()
                            } else {
                                None
                            }
                        } else {
                            None
                        }
                    } else {
                        None
                    };

                    let (active_profile, profiles) = match bt_cards.get(&mac) {
                        Some(card) => (card.active.clone(), card.profiles.clone()),
                        None => (String::new(), Vec::new()),
                    };

                    devices.push(DeviceInfo {
                        mac,
                        name,
                        icon,
                        connected,
                        paired,
                        battery,
                        active_profile,
                        profiles,
                    });
                }
            }
        }
    }

    BluetoothStatus {
        enabled,
        discovering,
        devices,
    }
}

fn toggle() {
    let show_out = Command::new("bluetoothctl")
        .arg("show")
        .output()
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .unwrap_or_default();

    if show_out.contains("Powered: yes") {
        let _ = Command::new("bluetoothctl").args(["power", "off"]).output();
    } else {
        let _ = Command::new("bluetoothctl").args(["power", "on"]).output();
    }
}

fn scan() {
    let _ = Command::new("bluetoothctl")
        .args(["--timeout", "8", "scan", "on"])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn();
}

fn pair(mac: &str) {
    let _ = Command::new("bluetoothctl").args(["pair", mac]).output();
    let _ = Command::new("bluetoothctl").args(["trust", mac]).output();
}

fn connect(mac: &str) {
    let _ = Command::new("bluetoothctl").args(["trust", mac]).output();
    let _ = Command::new("bluetoothctl").args(["connect", mac]).output();
}

fn disconnect(mac: &str) {
    let _ = Command::new("bluetoothctl").args(["disconnect", mac]).output();
}

fn forget(mac: &str) {
    let _ = Command::new("bluetoothctl").args(["remove", mac]).output();
}

fn set_profile(mac: &str, profile: &str) {
    let card_name = format!("bluez_card.{}", mac.replace(':', "_"));
    let _ = Command::new("pactl").args(["set-card-profile", &card_name, profile]).output();
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let action = args.get(1).map(|s| s.as_str()).unwrap_or("list");

    match action {
        "list" => {
            let status = get_bt();
            println!("{}", serde_json::to_string(&status).unwrap_or_else(|_| "{}".to_string()));
        }
        "toggle" => {
            toggle();
        }
        "scan" => {
            scan();
            let status = get_bt();
            println!("{}", serde_json::to_string(&status).unwrap_or_else(|_| "{}".to_string()));
        }
        "pair" => {
            if let Some(mac) = args.get(2) {
                pair(mac);
            }
        }
        "connect" => {
            if let Some(mac) = args.get(2) {
                connect(mac);
            }
        }
        "disconnect" => {
            if let Some(mac) = args.get(2) {
                disconnect(mac);
            }
        }
        "forget" => {
            if let Some(mac) = args.get(2) {
                forget(mac);
            }
        }
        "profile" => {
            if let (Some(mac), Some(prof)) = (args.get(2), args.get(3)) {
                set_profile(mac, prof);
            }
        }
        _ => {
            let status = get_bt();
            println!("{}", serde_json::to_string(&status).unwrap_or_else(|_| "{}".to_string()));
        }
    }
}
