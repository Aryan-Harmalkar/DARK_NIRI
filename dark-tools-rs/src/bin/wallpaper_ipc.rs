use serde_json::Value;
use std::env;
use std::fs;
use std::io::{Read, Write};
use std::os::unix::net::UnixStream;
use std::path::PathBuf;
use std::time::Duration;

fn send_ipc(socket_path: &str, payload: &str) -> bool {
    let mut stream = match UnixStream::connect(socket_path) {
        Ok(s) => s,
        Err(_) => return false,
    };
    let _ = stream.set_read_timeout(Some(Duration::from_secs(3)));
    let _ = stream.set_write_timeout(Some(Duration::from_secs(3)));

    if stream.write_all(format!("{}\n", payload).as_bytes()).is_err() {
        return false;
    }

    let mut buf = vec![0u8; 65536];
    match stream.read(&mut buf) {
        Ok(n) if n > 0 => {
            let res = String::from_utf8_lossy(&buf[..n]);
            println!("{}", res.trim());
            true
        }
        _ => false,
    }
}

fn list_items(themes_dir: &str, wall_dir: &str) {
    let mut items = Vec::new();

    // 1. Read themes
    if let Ok(entries) = fs::read_dir(themes_dir) {
        let mut t_names: Vec<String> = entries
            .flatten()
            .filter(|e| e.path().is_dir() && e.file_name() != "image-viewer")
            .filter_map(|e| e.file_name().into_string().ok())
            .collect();
        t_names.sort();

        for t in t_names {
            let name = t.replace('-', " ");
            let title: String = name
                .split_whitespace()
                .map(|w| {
                    let mut c = w.chars();
                    match c.next() {
                        None => String::new(),
                        Some(f) => f.to_uppercase().chain(c).collect(),
                    }
                })
                .collect::<Vec<_>>()
                .join(" ");

            items.push(serde_json::json!({
                "name": title,
                "path": t,
                "thumb": "",
                "type": "theme"
            }));
        }
    }

    // 2. Read wallpapers
    if let Ok(entries) = fs::read_dir(wall_dir) {
        let exts = ["jpg", "jpeg", "png", "webp", "mp4", "webm", "mkv"];
        let mut paths: Vec<PathBuf> = entries
            .flatten()
            .map(|e| e.path())
            .filter(|p| {
                p.extension()
                    .and_then(|e| e.to_str())
                    .map(|e| exts.contains(&e.to_lowercase().as_str()))
                    .unwrap_or(false)
            })
            .collect();
        paths.sort();

        for p in paths {
            if let Some(file_name) = p.file_name().and_then(|n| n.to_str()) {
                let lower = file_name.to_lowercase();
                let is_vid = lower.ends_with(".mp4") || lower.ends_with(".webm") || lower.ends_with(".mkv");
                let p_str = p.to_string_lossy().to_string();
                items.push(serde_json::json!({
                    "name": file_name,
                    "path": p_str,
                    "thumb": p_str,
                    "type": if is_vid { "video" } else { "image" }
                }));
            }
        }
    }

    println!("{}", serde_json::to_string(&items).unwrap_or_else(|_| "[]".to_string()));
}

fn get_active(config_file: &str) {
    if let Ok(content) = fs::read_to_string(config_file) {
        if let Ok(val) = serde_json::from_str::<Value>(&content) {
            if let Some(act) = val.get("active").and_then(|a| a.as_str()) {
                println!("{}", act);
                return;
            }
        }
    }
    println!();
}

fn pick_random(items_json: &str) {
    if let Ok(Value::Array(items)) = serde_json::from_str::<Value>(items_json) {
        if !items.is_empty() {
            let idx = std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .map(|d| (d.as_nanos() as usize) % items.len())
                .unwrap_or(0);
            if let Some(path) = items[idx].get("path").and_then(|p| p.as_str()) {
                println!("{}", path);
            }
        }
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let action = args.get(1).map(|s| s.as_str()).unwrap_or("");

    match action {
        "send" => {
            if let (Some(sock), Some(payload)) = (args.get(2), args.get(3)) {
                if !send_ipc(sock, payload) {
                    std::process::exit(1);
                }
            } else {
                std::process::exit(1);
            }
        }
        "list" => {
            let default_home = env::var("HOME").unwrap_or_else(|_| "/home/aryan".to_string());
            let themes_dir = args.get(2).cloned().unwrap_or_else(|| {
                format!("{}/DARK_NIRI/quickshell/wallpaper-engine/themes", default_home)
            });
            let wall_dir = args.get(3).cloned().unwrap_or_else(|| {
                format!("{}/Pictures/Wallpapers", default_home)
            });
            list_items(&themes_dir, &wall_dir);
        }
        "get-active" => {
            if let Some(cfg) = args.get(2) {
                get_active(cfg);
            }
        }
        "random" => {
            if let Some(items) = args.get(2) {
                pick_random(items);
            }
        }
        _ => {
            eprintln!("Usage: wp-ipc {{send <sock> <payload>|list <themes_dir> <wall_dir>|get-active <cfg>|random <json>}}");
            std::process::exit(1);
        }
    }
}
