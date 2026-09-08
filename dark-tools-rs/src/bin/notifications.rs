use serde::{Deserialize, Serialize};
use std::collections::HashSet;
use std::env;
use std::fs;
use std::process::{Command, Stdio};

const DISMISSED_FILE: &str = "/tmp/qs_dismissed.json";

#[derive(Serialize, Deserialize, Debug, Clone)]
struct NotificationItem {
    id: i64,
    app: String,
    summary: String,
    body: String,
    urgency: String,
}

#[derive(Deserialize, Debug)]
struct MakoNotification {
    id: Option<MakoId>,
    app_name: Option<MakoField>,
    summary: Option<MakoField>,
    body: Option<MakoField>,
    urgency: Option<MakoField>,
}

#[derive(Deserialize, Debug)]
#[serde(untagged)]
enum MakoId {
    Int(i64),
    Obj { data: i64 },
}

impl MakoId {
    fn as_i64(&self) -> i64 {
        match self {
            MakoId::Int(n) => *n,
            MakoId::Obj { data } => *data,
        }
    }
}

#[derive(Deserialize, Debug)]
#[serde(untagged)]
enum MakoField {
    Str(String),
    Obj { data: String },
}

impl MakoField {
    fn as_str(&self) -> &str {
        match self {
            MakoField::Str(s) => s.as_str(),
            MakoField::Obj { data } => data.as_str(),
        }
    }
}

fn get_dismissed() -> HashSet<i64> {
    if let Ok(data) = fs::read_to_string(DISMISSED_FILE) {
        if let Ok(list) = serde_json::from_str::<Vec<i64>>(&data) {
            return list.into_iter().collect();
        }
    }
    HashSet::new()
}

fn save_dismissed(dismissed: &HashSet<i64>) {
    let list: Vec<i64> = dismissed.iter().copied().collect();
    if let Ok(json_str) = serde_json::to_string(&list) {
        let _ = fs::write(DISMISSED_FILE, json_str);
    }
}

fn fetch_mako_list(arg: &str) -> Vec<MakoNotification> {
    let out = Command::new("makoctl")
        .args([arg, "-j"])
        .output()
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .unwrap_or_default();

    let trimmed = out.trim();
    if trimmed.is_empty() {
        return Vec::new();
    }

    // makoctl history -j and list -j usually return an array of notifications or array of arrays
    if let Ok(list) = serde_json::from_str::<Vec<MakoNotification>>(trimmed) {
        return list;
    }

    if let Ok(nested) = serde_json::from_str::<Vec<Vec<MakoNotification>>>(trimmed) {
        return nested.into_iter().flatten().collect();
    }

    Vec::new()
}

fn get_notifications() -> Vec<NotificationItem> {
    let mut all = fetch_mako_list("list");
    let hist = fetch_mako_list("history");
    all.extend(hist);

    let dismissed = get_dismissed();
    let mut items = Vec::new();
    let mut seen = HashSet::new();

    for n in all {
        let nid = match n.id {
            Some(ref id) => id.as_i64(),
            None => continue,
        };

        if seen.contains(&nid) || dismissed.contains(&nid) {
            continue;
        }
        seen.insert(nid);

        let app = n.app_name.as_ref().map(|f| f.as_str()).unwrap_or("System").to_string();
        let summary = n.summary.as_ref().map(|f| f.as_str()).unwrap_or("Notification").to_string();
        let body = n.body.as_ref().map(|f| f.as_str()).unwrap_or("").to_string();
        let urgency = n.urgency.as_ref().map(|f| f.as_str()).unwrap_or("normal").to_string();

        items.push(NotificationItem {
            id: nid,
            app,
            summary,
            body,
            urgency,
        });
    }

    items
}

fn dismiss(nid: i64) {
    let mut dismissed = get_dismissed();
    dismissed.insert(nid);
    save_dismissed(&dismissed);

    let _ = Command::new("makoctl")
        .args(["dismiss", "-n", &nid.to_string()])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn();
}

fn clear_all() {
    let notifs = get_notifications();
    let mut dismissed = get_dismissed();
    for n in notifs {
        dismissed.insert(n.id);
    }
    save_dismissed(&dismissed);

    let _ = Command::new("makoctl")
        .args(["dismiss", "-a"])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn();
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let action = args.get(1).map(|s| s.as_str()).unwrap_or("list");

    match action {
        "list" => {
            let notifs = get_notifications();
            println!("{}", serde_json::to_string(&notifs).unwrap_or_else(|_| "[]".to_string()));
        }
        "dismiss" => {
            if let Some(id_str) = args.get(2) {
                if let Ok(nid) = id_str.parse::<i64>() {
                    dismiss(nid);
                }
            }
            let notifs = get_notifications();
            println!("{}", serde_json::to_string(&notifs).unwrap_or_else(|_| "[]".to_string()));
        }
        "clear" => {
            clear_all();
            println!("[]");
        }
        "count" => {
            let notifs = get_notifications();
            println!("{}", notifs.len());
        }
        _ => {
            let notifs = get_notifications();
            println!("{}", serde_json::to_string(&notifs).unwrap_or_else(|_| "[]".to_string()));
        }
    }
}
