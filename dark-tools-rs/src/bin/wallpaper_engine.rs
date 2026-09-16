use std::cell::RefCell;
use std::collections::HashMap;
use std::fs;
use std::io::{BufRead, BufReader, Write};
use std::os::unix::net::{UnixListener, UnixStream};
use std::path::{Path, PathBuf};
use std::rc::Rc;
use std::sync::mpsc;
use std::thread;

use gtk4::glib;
use gtk4::prelude::*;
use gtk4::gio::prelude::ApplicationExt;
use gtk4_layer_shell::{Edge, KeyboardMode, Layer, LayerShell};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use webkit6::prelude::*;

const BRIDGE_USER_SCRIPT: &str = include_str!("bridge.js");

extern "C" {
    fn getuid() -> u32;
}

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Config {
    #[serde(default = "default_active")]
    active: String,
    #[serde(default = "default_active_type")]
    active_type: String,
    #[serde(default = "default_mode")]
    mode: String,
    #[serde(default)]
    monitors: HashMap<String, String>,
    #[serde(default = "default_fps")]
    fps: u32,
    #[serde(default = "default_quality")]
    quality: String,
    #[serde(default = "default_true")]
    battery_saver: bool,
    #[serde(default = "default_true")]
    pause_fullscreen: bool,
    #[serde(default = "default_effects")]
    effects: Value,
}

fn default_active() -> String {
    "cyber-city".to_string()
}
fn default_active_type() -> String {
    "theme".to_string()
}
fn default_mode() -> String {
    "global".to_string()
}
fn default_fps() -> u32 {
    60
}
fn default_quality() -> String {
    "balanced".to_string()
}
fn default_true() -> bool {
    true
}
fn default_effects() -> Value {
    json!({
        "particles": {
            "enabled": true,
            "style": "embers",
            "count": 40,
            "speed": 1.0,
            "color": "#7aa2f7"
        },
        "parallax": {
            "enabled": true,
            "depth": 2.5
        },
        "time_lighting": {
            "enabled": true,
            "mode": "auto",
            "preset": "sunset"
        },
        "weather": {
            "enabled": false,
            "type": "rain",
            "intensity": "medium"
        },
        "clock_hud": {
            "enabled": true,
            "style": "cyber",
            "position": "top-right",
            "format24h": true,
            "showSeconds": true
        },
        "scanlines": {
            "enabled": false,
            "opacity": 0.25
        },
        "vignette": {
            "enabled": true,
            "opacity": 0.35
        },
        "blur": {
            "enabled": false,
            "radius": 0
        },
        "brightness": 100,
        "contrast": 100
    })
}

impl Default for Config {
    fn default() -> Self {
        Config {
            active: default_active(),
            active_type: default_active_type(),
            mode: default_mode(),
            monitors: HashMap::new(),
            fps: default_fps(),
            quality: default_quality(),
            battery_saver: default_true(),
            pause_fullscreen: default_true(),
            effects: default_effects(),
        }
    }
}

struct MonitorWindow {
    win: gtk4::ApplicationWindow,
    view: webkit6::WebView,
    current_url: Option<String>,
}

struct EngineState {
    app: gtk4::Application,
    _hold_guard: gtk4::gio::ApplicationHoldGuard,
    config: Config,
    windows: HashMap<String, MonitorWindow>,
    themes_dir: PathBuf,
    config_path: PathBuf,
    state_file: PathBuf,
    wallpapers_dir: PathBuf,
    last_cpu: Option<(f64, f64)>,
    current_telemetry: Value,
}

struct IpcRequest {
    msg: Value,
    reply: mpsc::Sender<Value>,
}

thread_local! {
    static STATE: RefCell<Option<Rc<RefCell<EngineState>>>> = RefCell::new(None);
    static REQ_RX: RefCell<Option<mpsc::Receiver<IpcRequest>>> = RefCell::new(None);
}

impl EngineState {
    fn new(app: gtk4::Application) -> Self {
        let exe_path = std::env::current_exe().unwrap_or_else(|_| PathBuf::from("."));
        let mut engine_dir = exe_path.parent().unwrap_or_else(|| Path::new(".")).to_path_buf();
        if engine_dir.to_string_lossy().contains("target") {
            let user_home = std::env::var("HOME").unwrap_or_else(|_| "/home/aryan".to_string());
            let default_dir = PathBuf::from(format!("{}/DARK_NIRI/quickshell/wallpaper-engine", user_home));
            if default_dir.exists() {
                engine_dir = default_dir;
            }
        }

        let themes_dir = engine_dir.join("themes");
        let config_path = engine_dir.join("config.json");
        let home = std::env::var("HOME").unwrap_or_else(|_| "/home/aryan".to_string());
        let state_file = PathBuf::from(format!("{}/.config/niri/current_wallpaper", home));
        let wallpapers_dir = PathBuf::from(format!("{}/Pictures/Wallpapers", home));

        let config = Self::load_config(&config_path);

        let _hold_guard = app.hold();
        EngineState {
            app,
            _hold_guard,
            config,
            windows: HashMap::new(),
            themes_dir,
            config_path,
            state_file,
            wallpapers_dir,
            last_cpu: None,
            current_telemetry: json!({
                "cpu": 0,
                "memory": 0,
                "battery": {"percentage": 100, "charging": false},
                "workspace": {"id": 1, "idx": 1},
                "media": {"title": "", "artist": "", "status": "Stopped", "artUrl": ""},
                "monitors": [],
                "fullscreen": false
            }),
        }
    }

    fn load_config(path: &Path) -> Config {
        if let Ok(data) = fs::read_to_string(path) {
            if let Ok(cfg) = serde_json::from_str::<Config>(&data) {
                return cfg;
            }
        }
        Config::default()
    }

    fn save_config(&self) {
        if let Ok(json_str) = serde_json::to_string_pretty(&self.config) {
            let _ = fs::write(&self.config_path, json_str);
        }
        if let Some(parent) = self.state_file.parent() {
            let _ = fs::create_dir_all(parent);
        }
        let _ = fs::write(&self.state_file, &self.config.active);
    }

    fn get_target_for_monitor(&self, conn: &str) -> String {
        if self.config.mode == "per-monitor" {
            if let Some(t) = self.config.monitors.get(conn) {
                return t.clone();
            }
        }
        self.config.active.clone()
    }

    fn get_target_url(&self, target: &str) -> String {
        let t = if target.is_empty() { "cyber-city" } else { target };

        if let Some(hex) = t.strip_prefix("color:") {
            return format!(
                "data:text/html,<html><head><style>*{{margin:0;padding:0;overflow:hidden;}}body{{background:{};width:100vw;height:100vh;}}</style></head><body></body></html>",
                hex
            );
        }

        if !Path::new(t).is_absolute() {
            let theme_path = self.themes_dir.join(t);
            if theme_path.is_dir() {
                let index = theme_path.join("index.html");
                if index.exists() {
                    return format!("file://{}", index.to_string_lossy());
                }
            }
        }

        // Wrap in image-viewer
        let viewer_index = self.themes_dir.join("image-viewer").join("index.html");
        format!("file://{}", viewer_index.to_string_lossy())
    }

    fn apply_effects_to_view(&self, view: &webkit6::WebView) {
        if let Ok(cfg_json) = serde_json::to_string(&self.config) {
            let script = format!("if (window.updateWallpaperConfig) window.updateWallpaperConfig({});", cfg_json);
            view.evaluate_javascript(&script, None::<&str>, None::<&str>, None::<&gtk4::gio::Cancellable>, |_| {});
        }
    }

    fn push_state_to_view(&self, view: &webkit6::WebView) {
        let script = format!("if (window.__onWallpaperStateUpdate) window.__onWallpaperStateUpdate({});", self.current_telemetry);
        view.evaluate_javascript(&script, None::<&str>, None::<&str>, None::<&gtk4::gio::Cancellable>, |_| {});
    }

    fn load_target_into_view(&mut self, connector: &str) {
        let target = self.get_target_for_monitor(connector);
        let target_url = self.get_target_url(&target);

        if let Some(info) = self.windows.get_mut(connector) {
            info.current_url = Some(target_url.clone());
            let view = &info.view;

            if target_url.starts_with("file://") && target_url.contains("image-viewer") {
                let file_uri = if target.starts_with("file://") {
                    target.clone()
                } else {
                    format!("file://{}", target)
                };

                let current_uri = view.uri().map(|s| s.to_string()).unwrap_or_default();
                if current_uri.contains("image-viewer") {
                    let script = format!(
                        "if (window.setWallpaperImage) window.setWallpaperImage({});",
                        json!(file_uri)
                    );
                    view.evaluate_javascript(&script, None::<&str>, None::<&str>, None::<&gtk4::gio::Cancellable>, |_| {});
                    return;
                } else {
                    view.load_uri(&format!("{}#{}", target_url, file_uri));
                    return;
                }
            }

            view.load_uri(&target_url);
        }
    }

    fn apply_all(&mut self) {
        let conns: Vec<String> = self.windows.keys().cloned().collect();
        for conn in conns {
            self.load_target_into_view(&conn);
        }
    }

    fn create_window_for_monitor(state_rc: &Rc<RefCell<EngineState>>, monitor: &gtk4::gdk::Monitor, connector: String) {
        let (app, fallback_uri) = {
            let s = state_rc.borrow();
            let fallback = format!("file://{}/fallback/index.html", s.themes_dir.to_string_lossy());
            (s.app.clone(), fallback)
        };

        let win = gtk4::ApplicationWindow::new(&app);
        win.init_layer_shell();
        win.set_layer(Layer::Background);
        win.set_keyboard_mode(KeyboardMode::None);
        win.set_namespace("dark-niri-wallpaper");
        win.set_anchor(Edge::Top, true);
        win.set_anchor(Edge::Bottom, true);
        win.set_anchor(Edge::Left, true);
        win.set_anchor(Edge::Right, true);
        win.set_exclusive_zone(-1);
        win.set_monitor(monitor);

        let view = webkit6::WebView::new();
        if let Some(settings) = webkit6::prelude::WebViewExt::settings(&view) {
            settings.set_enable_javascript(true);
            settings.set_enable_webgl(true);
            settings.set_hardware_acceleration_policy(webkit6::HardwareAccelerationPolicy::Always);
            settings.set_enable_media(true);
            settings.set_media_playback_allows_inline(true);
            settings.set_enable_page_cache(false);
            settings.set_allow_file_access_from_file_urls(true);
            settings.set_allow_universal_access_from_file_urls(true);
        }
        view.set_is_muted(true);

        if let Some(ucm) = view.user_content_manager() {
            let script = webkit6::UserScript::new(
                BRIDGE_USER_SCRIPT,
                webkit6::UserContentInjectedFrames::AllFrames,
                webkit6::UserScriptInjectionTime::Start,
                &[],
                &[],
            );
            ucm.add_script(&script);
        }

        let state_weak = Rc::downgrade(state_rc);
        let conn_clone = connector.clone();
        view.connect_load_changed(move |wv, event| {
            if event == webkit6::LoadEvent::Finished {
                if let Some(st) = state_weak.upgrade() {
                    let s = st.borrow();
                    s.apply_effects_to_view(wv);
                    s.push_state_to_view(wv);

                    let target = s.get_target_for_monitor(&conn_clone);
                    if !target.starts_with("color:") && (Path::new(&target).is_absolute() || Path::new(&target).exists()) {
                        let file_uri = if target.starts_with("file://") {
                            target
                        } else {
                            format!("file://{}", target)
                        };
                        let script = format!("if (window.setWallpaperImage) window.setWallpaperImage({});", json!(file_uri));
                        wv.evaluate_javascript(&script, None::<&str>, None::<&str>, None::<&gtk4::gio::Cancellable>, |_| {});
                    }
                }
            }
        });

        let fb = fallback_uri.clone();
        view.connect_load_failed(move |wv, _event, uri, err| {
            eprintln!("[Engine] Load failed for {}: {}. Using fallback.", uri, err);
            wv.load_uri(&fb);
            true
        });

        win.set_child(Some(&view));

        let info = MonitorWindow {
            win: win.clone(),
            view,
            current_url: None,
        };

        {
            let mut s = state_rc.borrow_mut();
            s.windows.insert(connector.clone(), info);
            s.load_target_into_view(&connector);
        }

        win.present();
    }

    fn setup_monitors(state_rc: &Rc<RefCell<EngineState>>) {
        let display = match gtk4::gdk::Display::default() {
            Some(d) => d,
            None => return,
        };
        let monitors = display.monitors();
        let mut active_conns = std::collections::HashSet::new();

        for i in 0..monitors.n_items() {
            if let Some(item) = monitors.item(i) {
                if let Ok(mon) = item.downcast::<gtk4::gdk::Monitor>() {
                    let conn = mon.connector().map(|s| s.to_string()).unwrap_or_else(|| format!("mon-{}", i));
                    active_conns.insert(conn.clone());

                    let exists = state_rc.borrow().windows.contains_key(&conn);
                    if !exists {
                        Self::create_window_for_monitor(state_rc, &mon, conn);
                    }
                }
            }
        }

        // Remove disconnected monitors
        let mut to_remove = Vec::new();
        {
            let s = state_rc.borrow();
            for conn in s.windows.keys() {
                if !active_conns.contains(conn) {
                    to_remove.push(conn.clone());
                }
            }
        }

        for conn in to_remove {
            if let Some(info) = state_rc.borrow_mut().windows.remove(&conn) {
                info.win.destroy();
            }
        }
    }

    fn set_target(&mut self, target_opt: Option<&str>, monitor_opt: Option<&str>) -> Value {
        let target_str = match target_opt {
            Some(t) if !t.is_empty() => t,
            _ => return json!({"status": "error", "message": "Empty target"}),
        };

        let mut target = target_str.to_string();

        if !target.starts_with("color:") && !self.themes_dir.join(&target).exists() {
            if !Path::new(&target).exists() {
                let cand = self.wallpapers_dir.join(&target);
                if cand.exists() {
                    target = cand.to_string_lossy().to_string();
                } else {
                    return json!({"status": "error", "message": format!("File not found: {}", target)});
                }
            }
        }

        if let Some(mon) = monitor_opt {
            if self.windows.contains_key(mon) {
                self.config.mode = "per-monitor".to_string();
                self.config.monitors.insert(mon.to_string(), target.clone());
            } else {
                self.config.active = target.clone();
            }
        } else {
            self.config.active = target.clone();
            if target.starts_with("color:") {
                self.config.active_type = "color".to_string();
            } else if !Path::new(&target).is_absolute() && self.themes_dir.join(&target).is_dir() {
                self.config.active_type = "theme".to_string();
            } else {
                self.config.active_type = "image".to_string();
            }
        }

        self.save_config();
        self.apply_all();

        json!({
            "status": "ok",
            "active": target,
            "type": self.config.active_type
        })
    }

    fn set_effect(&mut self, key: &str, value_str: &str) -> Value {
        let val: Value = if value_str.eq_ignore_ascii_case("true") {
            Value::Bool(true)
        } else if value_str.eq_ignore_ascii_case("false") {
            Value::Bool(false)
        } else if let Ok(n) = value_str.parse::<i64>() {
            json!(n)
        } else if let Ok(f) = value_str.parse::<f64>() {
            json!(f)
        } else {
            json!(value_str)
        };

        let top_level = ["fps", "quality", "battery_saver", "pause_fullscreen", "mode", "active", "active_type"];
        if top_level.contains(&key) {
            match key {
                "fps" => if let Some(n) = val.as_u64() { self.config.fps = n as u32; },
                "quality" => if let Some(s) = val.as_str() { self.config.quality = s.to_string(); },
                "battery_saver" => if let Some(b) = val.as_bool() { self.config.battery_saver = b; },
                "pause_fullscreen" => if let Some(b) = val.as_bool() { self.config.pause_fullscreen = b; },
                "mode" => if let Some(s) = val.as_str() { self.config.mode = s.to_string(); },
                _ => {}
            }
        } else {
            let key_path = key.strip_prefix("effects.").unwrap_or(key);
            let parts: Vec<&str> = key_path.split('.').collect();
            if let Value::Object(ref mut map) = self.config.effects {
                if parts.len() == 1 {
                    map.insert(parts[0].to_string(), val.clone());
                } else if parts.len() == 2 {
                    let sub = map.entry(parts[0].to_string()).or_insert_with(|| json!({}));
                    if let Value::Object(ref mut sub_map) = sub {
                        sub_map.insert(parts[1].to_string(), val.clone());
                    }
                }
            }
        }

        self.save_config();

        for info in self.windows.values() {
            self.apply_effects_to_view(&info.view);
        }

        json!({"status": "ok", "key": key, "value": val})
    }

    fn set_config_json(&mut self, new_cfg: Value) -> Value {
        if let Ok(cfg) = serde_json::from_value::<Config>(new_cfg) {
            self.config = cfg;
            self.save_config();
            self.apply_all();
            json!({"status": "ok"})
        } else {
            json!({"status": "error", "message": "Failed to parse config"})
        }
    }

    fn get_list(&self) -> Value {
        let mut list = Vec::new();

        // 1. HTML Themes
        if let Ok(entries) = fs::read_dir(&self.themes_dir) {
            let mut dirs: Vec<_> = entries.filter_map(|e| e.ok()).collect();
            dirs.sort_by_key(|e| e.file_name());

            for entry in dirs {
                let name = entry.file_name().to_string_lossy().to_string();
                if entry.path().is_dir() && name != "image-viewer" && name != "fallback" {
                    let manifest_path = entry.path().join("wallpaper.json");
                    let mut meta_name = name.replace('-', " ");
                    let mut desc = "Interactive HTML Wallpaper".to_string();
                    let mut interactive = false;
                    let mut audio_reactive = false;

                    if let Ok(mf_data) = fs::read_to_string(&manifest_path) {
                        if let Ok(mf) = serde_json::from_str::<Value>(&mf_data) {
                            if let Some(n) = mf.get("name").and_then(|v| v.as_str()) {
                                meta_name = n.to_string();
                            }
                            if let Some(d) = mf.get("description").and_then(|v| v.as_str()) {
                                desc = d.to_string();
                            }
                            interactive = mf.get("interactive").and_then(|v| v.as_bool()).unwrap_or(false);
                            audio_reactive = mf.get("audioReactive").and_then(|v| v.as_bool()).unwrap_or(false);
                        }
                    }

                    list.push(json!({
                        "name": meta_name,
                        "path": name,
                        "thumb": "",
                        "type": "theme",
                        "description": desc,
                        "interactive": interactive,
                        "audioReactive": audio_reactive
                    }));
                }
            }
        }

        // 2. Wallpapers dir
        if let Ok(entries) = fs::read_dir(&self.wallpapers_dir) {
            let mut files: Vec<_> = entries.filter_map(|e| e.ok()).collect();
            files.sort_by_key(|e| e.file_name());

            for entry in files {
                let path = entry.path();
                if path.is_file() {
                    let ext = path.extension().and_then(|s| s.to_str()).unwrap_or("").to_lowercase();
                    let is_img = ["jpg", "jpeg", "png", "webp"].contains(&ext.as_str());
                    let is_vid = ["mp4", "webm", "mkv", "gif"].contains(&ext.as_str());
                    if is_img || is_vid {
                        let fname = path.file_name().unwrap_or_default().to_string_lossy().to_string();
                        let p_str = path.to_string_lossy().to_string();
                        list.push(json!({
                            "name": fname,
                            "path": p_str,
                            "thumb": p_str,
                            "type": if is_vid { "video" } else { "image" },
                            "description": if is_vid { "Live Video Wallpaper" } else { "Static Image" }
                        }));
                    }
                }
            }
        }

        json!(list)
    }

    fn update_telemetry(&mut self) {
        let cpu_pct = self.calc_cpu();
        let mem_pct = self.calc_memory();
        let bat_info = self.get_battery();
        let ws_info = self.get_niri_workspace();
        let media_info = self.get_media();
        let is_fullscreen = self.check_niri_fullscreen();
        let monitors: Vec<String> = self.windows.keys().cloned().collect();

        self.current_telemetry = json!({
            "cpu": cpu_pct,
            "memory": mem_pct,
            "battery": bat_info,
            "workspace": ws_info,
            "media": media_info,
            "monitors": monitors,
            "fullscreen": is_fullscreen
        });

        for info in self.windows.values() {
            self.push_state_to_view(&info.view);
        }
    }

    fn calc_cpu(&mut self) -> u32 {
        if let Ok(stat) = fs::read_to_string("/proc/stat") {
            if let Some(line) = stat.lines().next() {
                let parts: Vec<f64> = line
                    .split_whitespace()
                    .skip(1)
                    .take(7)
                    .filter_map(|s| s.parse().ok())
                    .collect();
                if parts.len() >= 4 {
                    let idle = parts[3];
                    let total: f64 = parts.iter().sum();
                    let pct = if let Some((last_idle, last_total)) = self.last_cpu {
                        let idle_delta = idle - last_idle;
                        let total_delta = total - last_total;
                        if total_delta > 0.0 {
                            (100.0 * (1.0 - (idle_delta / total_delta))).round() as u32
                        } else {
                            0
                        }
                    } else {
                        0
                    };
                    self.last_cpu = Some((idle, total));
                    return pct.min(100);
                }
            }
        }
        0
    }

    fn calc_memory(&self) -> u32 {
        if let Ok(mem) = fs::read_to_string("/proc/meminfo") {
            let mut total = 0.0;
            let mut avail = 0.0;
            for line in mem.lines() {
                if line.starts_with("MemTotal:") {
                    total = line.split_whitespace().nth(1).and_then(|s| s.parse().ok()).unwrap_or(0.0);
                } else if line.starts_with("MemAvailable:") {
                    avail = line.split_whitespace().nth(1).and_then(|s| s.parse().ok()).unwrap_or(0.0);
                }
            }
            if total > 0.0 {
                return (((total - avail) / total) * 100.0_f64).round() as u32;
            }
        }
        0
    }

    fn get_battery(&self) -> Value {
        let bat_dir = Path::new("/sys/class/power_supply");
        if let Ok(entries) = fs::read_dir(bat_dir) {
            for entry in entries.flatten() {
                let name = entry.file_name().to_string_lossy().to_string();
                if name.starts_with("BAT") {
                    let cap = fs::read_to_string(entry.path().join("capacity"))
                        .ok()
                        .and_then(|s| s.trim().parse::<u32>().ok())
                        .unwrap_or(100);
                    let stat = fs::read_to_string(entry.path().join("status"))
                        .unwrap_or_else(|_| "Discharging".to_string());
                    let charging = stat.trim().eq_ignore_ascii_case("charging");
                    return json!({"percentage": cap, "charging": charging});
                }
            }
        }
        json!({"percentage": 100, "charging": false})
    }

    fn get_niri_workspace(&self) -> Value {
        if let Ok(out) = std::process::Command::new("niri")
            .args(["msg", "--json", "workspaces"])
            .output()
        {
            if out.status.success() {
                if let Ok(workspaces) = serde_json::from_slice::<Vec<Value>>(&out.stdout) {
                    for w in workspaces {
                        let is_focused = w.get("is_focused").and_then(|v| v.as_bool()).unwrap_or(false);
                        let is_active = w.get("is_active").and_then(|v| v.as_bool()).unwrap_or(false);
                        if is_focused || is_active {
                            return json!({
                                "id": w.get("id").unwrap_or(&json!(1)),
                                "idx": w.get("idx").unwrap_or(&json!(1))
                            });
                        }
                    }
                }
            }
        }
        json!({"id": 1, "idx": 1})
    }

    fn check_niri_fullscreen(&self) -> bool {
        if !self.config.pause_fullscreen {
            return false;
        }
        if let Ok(out) = std::process::Command::new("niri")
            .args(["msg", "--json", "windows"])
            .output()
        {
            if out.status.success() {
                if let Ok(windows) = serde_json::from_slice::<Vec<Value>>(&out.stdout) {
                    for w in windows {
                        let is_focused = w.get("is_focused").and_then(|v| v.as_bool()).unwrap_or(false);
                        let is_floating = w.get("is_floating").and_then(|v| v.as_bool()).unwrap_or(false);
                        if is_focused && !is_floating {
                            if let Some(size) = w.get("layout").and_then(|l| l.get("window_size")).and_then(|s| s.as_array()) {
                                if size.len() >= 2 {
                                    let width = size[0].as_i64().unwrap_or(0);
                                    let height = size[1].as_i64().unwrap_or(0);
                                    if width >= 1900 && height >= 1000 {
                                        return true;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        false
    }

    fn get_media(&self) -> Value {
        if let Ok(out) = std::process::Command::new("playerctl")
            .args([
                "metadata",
                "--format",
                r#"{"title": "{{title}}", "artist": "{{artist}}", "status": "{{status}}", "artUrl": "{{mpris:artUrl}}"}"#,
            ])
            .output()
        {
            if out.status.success() {
                if let Ok(val) = serde_json::from_slice::<Value>(&out.stdout) {
                    return val;
                }
            }
        }
        json!({"title": "", "artist": "", "status": "Stopped", "artUrl": ""})
    }

    fn dispatch_ipc(&mut self, msg: &Value) -> Value {
        let cmd = msg.get("cmd").and_then(|v| v.as_str()).unwrap_or("");
        match cmd {
            "set" => {
                let target = msg.get("target").or_else(|| msg.get("value")).and_then(|v| v.as_str());
                let mon = msg.get("monitor").and_then(|v| v.as_str());
                self.set_target(target, mon)
            }
            "color" => {
                let mut hex = msg.get("hex").or_else(|| msg.get("target")).or_else(|| msg.get("value")).and_then(|v| v.as_str()).unwrap_or("").to_string();
                if !hex.is_empty() && !hex.starts_with('#') {
                    hex = format!("#{}", hex);
                }
                let mon = msg.get("monitor").and_then(|v| v.as_str());
                self.set_target(Some(&format!("color:{}", hex)), mon)
            }
            "set_effect" => {
                let key = msg.get("key").and_then(|v| v.as_str()).unwrap_or("");
                let val = msg.get("value").map(|v| match v {
                    Value::String(s) => s.clone(),
                    _ => v.to_string(),
                }).unwrap_or_default();
                self.set_effect(key, &val)
            }
            "set_config" => {
                if let Some(cfg_val) = msg.get("config") {
                    self.set_config_json(cfg_val.clone())
                } else {
                    json!({"status": "error", "message": "Config must be provided"})
                }
            }
            "get_config" => {
                json!(self.config)
            }
            "get" => {
                json!({"active": self.config.active})
            }
            "list" => {
                self.get_list()
            }
            "monitors" => {
                let mons: Vec<String> = self.windows.keys().cloned().collect();
                json!({"monitors": mons, "mode": self.config.mode})
            }
            "status" => {
                let mons: Vec<String> = self.windows.keys().cloned().collect();
                json!({
                    "running": true,
                    "pid": std::process::id(),
                    "monitors": mons,
                    "active": self.config.active,
                    "active_type": self.config.active_type,
                    "mode": self.config.mode,
                    "quality": self.config.quality,
                    "fps": self.config.fps,
                    "pause_fullscreen": self.config.pause_fullscreen,
                    "battery_saver": self.config.battery_saver,
                    "effects": self.config.effects
                })
            }
            "reload" => {
                self.apply_all();
                json!({"status": "reloaded"})
            }
            "stop" => {
                self.app.quit();
                json!({"status": "stopping"})
            }
            _ => json!({"status": "unknown_command"}),
        }
    }
}

fn drain_ipc_requests() {
    STATE.with(|st| {
        REQ_RX.with(|rx_cell| {
            if let Some(ref rx) = *rx_cell.borrow() {
                while let Ok(req) = rx.try_recv() {
                    if let Some(ref state_rc) = *st.borrow() {
                        let res = state_rc.borrow_mut().dispatch_ipc(&req.msg);
                        let _ = req.reply.send(res);
                    }
                }
            }
        });
    });
}

fn handle_client(mut stream: UnixStream, ipc_tx: mpsc::Sender<IpcRequest>) {
    let mut reader = BufReader::new(stream.try_clone().unwrap());
    let mut line = String::new();
    if reader.read_line(&mut line).is_err() || line.trim().is_empty() {
        return;
    }

    let raw = line.trim();
    let msg: Value = match serde_json::from_str(raw) {
        Ok(v) => v,
        Err(_) => {
            let mut parts = raw.splitn(2, ' ');
            let cmd = parts.next().unwrap_or("");
            let arg = parts.next().unwrap_or("");
            json!({"cmd": cmd, "target": arg, "value": arg})
        }
    };

    let cmd = msg.get("cmd").and_then(|v| v.as_str()).unwrap_or("").to_string();

    let (reply_tx, reply_rx) = mpsc::channel::<Value>();

    if ipc_tx.send(IpcRequest { msg, reply: reply_tx }).is_ok() {
        glib::idle_add_once(|| {
            drain_ipc_requests();
        });

        if let Ok(res_val) = reply_rx.recv_timeout(std::time::Duration::from_secs(5)) {
            if cmd == "get" {
                let active = res_val.get("active").and_then(|v| v.as_str()).unwrap_or("");
                let _ = writeln!(stream, "{}", active);
            } else {
                let _ = writeln!(stream, "{}", res_val);
            }
        }
    }
}

fn start_ipc_server(socket_path: PathBuf, ipc_tx: mpsc::Sender<IpcRequest>) {
    if socket_path.exists() {
        let _ = fs::remove_file(&socket_path);
    }

    let listener = match UnixListener::bind(&socket_path) {
        Ok(l) => l,
        Err(e) => {
            eprintln!("[Engine] Failed to bind IPC socket {}: {}", socket_path.display(), e);
            return;
        }
    };

    thread::spawn(move || {
        for stream in listener.incoming() {
            if let Ok(s) = stream {
                let tx_clone = ipc_tx.clone();
                thread::spawn(move || {
                    handle_client(s, tx_clone);
                });
            }
        }
    });
}

fn main() {
    let app = gtk4::Application::builder()
        .application_id("org.darkniri.wallpaperengine")
        .build();

    let uid = unsafe { getuid() };
    let socket_path = PathBuf::from(format!("/tmp/qs-wallpaper-{}.sock", uid));

    let (ipc_tx, ipc_rx) = mpsc::channel::<IpcRequest>();
    REQ_RX.with(|rx_cell| {
        *rx_cell.borrow_mut() = Some(ipc_rx);
    });

    let socket_path_activate = socket_path.clone();

    app.connect_activate(move |app| {
        let state = Rc::new(RefCell::new(EngineState::new(app.clone())));
        STATE.with(|st| {
            *st.borrow_mut() = Some(state.clone());
        });

        // Setup monitors & windows
        EngineState::setup_monitors(&state);

        // Connect monitors dynamic update
        let state_mon_cb = state.clone();
        if let Some(disp) = gtk4::gdk::Display::default() {
            let mons = disp.monitors();
            mons.connect_items_changed(move |_, _, _, _| {
                EngineState::setup_monitors(&state_mon_cb);
            });
        }

        // Start IPC server
        start_ipc_server(socket_path_activate.clone(), ipc_tx.clone());

        // Telemetry loop (every 2 seconds)
        let state_telemetry = state.clone();
        glib::timeout_add_seconds_local(2, move || {
            state_telemetry.borrow_mut().update_telemetry();
            glib::ControlFlow::Continue
        });
    });

    // Ignore SIGHUP so daemon survives parent terminal exit
    glib::unix_signal_add_local(1, move || {
        glib::ControlFlow::Continue
    });

    // Handle clean termination
    let sp_sigint = socket_path.clone();
    glib::unix_signal_add_local(2, move || {
        let _ = fs::remove_file(&sp_sigint);
        std::process::exit(0);
    });

    let sp_sigterm = socket_path.clone();
    glib::unix_signal_add_local(15, move || {
        let _ = fs::remove_file(&sp_sigterm);
        std::process::exit(0);
    });

    let args: Vec<String> = std::env::args().collect();
    app.run_with_args(&args);

    if socket_path.exists() {
        let _ = fs::remove_file(&socket_path);
    }
}
