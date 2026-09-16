use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;
use std::process::Command;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Theme {
    pub id: String,
    pub name: String,
    pub description: String,
    pub wallpaper: String,
    // Backgrounds & Surfaces
    pub bg: String,
    pub bg_alpha: String,
    pub bg_alt: String,
    pub surface: String,
    pub surface_hover: String,
    pub surface_card: String,
    // Accents
    pub accent: String,
    pub accent_secondary: String,
    pub accent_tertiary: String,
    // Borders
    pub border: String,
    pub border_active: String,
    // Text
    pub fg: String,
    pub fg_secondary: String,
    pub fg_muted: String,
    // Status
    pub success: String,
    pub warning: String,
    pub danger: String,
    // Subsystems
    pub niri_focus: String,
    pub niri_border: String,
    pub rofi_selection: String,
}

fn get_themes() -> Vec<Theme> {
    vec![
        Theme {
            id: "tokyo-night".into(),
            name: "Tokyo Night".into(),
            description: "Signature dark cyberpunk neon with cyan, deep blue, and violet".into(),
            wallpaper: "cyber-city".into(),
            bg: "#1a1b26".into(),
            bg_alpha: "#E61a1b26".into(),
            bg_alt: "#24283b".into(),
            surface: "#1f2335".into(),
            surface_hover: "#292e42".into(),
            surface_card: "#24283b".into(),
            accent: "#7aa2f7".into(),
            accent_secondary: "#bb9af7".into(),
            accent_tertiary: "#7dcfff".into(),
            border: "#292e42".into(),
            border_active: "#7aa2f7".into(),
            fg: "#c0caf5".into(),
            fg_secondary: "#a9b1d6".into(),
            fg_muted: "#565f89".into(),
            success: "#9ece6a".into(),
            warning: "#e0af68".into(),
            danger: "#f7768e".into(),
            niri_focus: "#7aa2f7".into(),
            niri_border: "#3b4261".into(),
            rofi_selection: "#33467c".into(),
        },
        Theme {
            id: "catppuccin-mocha".into(),
            name: "Catppuccin Mocha".into(),
            description: "Soothing pastel palette with mauve, sapphire, and lavender".into(),
            wallpaper: "waves".into(),
            bg: "#1e1e2e".into(),
            bg_alpha: "#E61e1e2e".into(),
            bg_alt: "#313244".into(),
            surface: "#181825".into(),
            surface_hover: "#45475a".into(),
            surface_card: "#313244".into(),
            accent: "#cba6f7".into(),
            accent_secondary: "#89b4fa".into(),
            accent_tertiary: "#f5c2e7".into(),
            border: "#45475a".into(),
            border_active: "#cba6f7".into(),
            fg: "#cdd6f4".into(),
            fg_secondary: "#a6adc8".into(),
            fg_muted: "#6c7086".into(),
            success: "#a6e3a1".into(),
            warning: "#f9e2af".into(),
            danger: "#f38ba8".into(),
            niri_focus: "#cba6f7".into(),
            niri_border: "#585b70".into(),
            rofi_selection: "#585b70".into(),
        },
        Theme {
            id: "cyberpunk-2077".into(),
            name: "Cyberpunk 2077".into(),
            description: "High-voltage neon yellow, hot magenta, and electric cyan".into(),
            wallpaper: "cyber-city".into(),
            bg: "#0d0d15".into(),
            bg_alpha: "#E60d0d15".into(),
            bg_alt: "#1a1a2e".into(),
            surface: "#121220".into(),
            surface_hover: "#25253e".into(),
            surface_card: "#18182b".into(),
            accent: "#fee801".into(),
            accent_secondary: "#00f0ff".into(),
            accent_tertiary: "#ff003c".into(),
            border: "#2c2c44".into(),
            border_active: "#fee801".into(),
            fg: "#f3f3f3".into(),
            fg_secondary: "#00f0ff".into(),
            fg_muted: "#717182".into(),
            success: "#00ff9f".into(),
            warning: "#fee801".into(),
            danger: "#ff003c".into(),
            niri_focus: "#fee801".into(),
            niri_border: "#ff003c".into(),
            rofi_selection: "#2c2c44".into(),
        },
        Theme {
            id: "nord-frost".into(),
            name: "Nord Frost".into(),
            description: "Clean arctic dark slate, frost cyan, and glacial ice blue".into(),
            wallpaper: "aurora".into(),
            bg: "#2e3440".into(),
            bg_alpha: "#E62e3440".into(),
            bg_alt: "#3b4252".into(),
            surface: "#242933".into(),
            surface_hover: "#434c5e".into(),
            surface_card: "#3b4252".into(),
            accent: "#88c0d0".into(),
            accent_secondary: "#81a1c1".into(),
            accent_tertiary: "#8fbcbb".into(),
            border: "#434c5e".into(),
            border_active: "#88c0d0".into(),
            fg: "#eceff4".into(),
            fg_secondary: "#e5e9f0".into(),
            fg_muted: "#7b88a1".into(),
            success: "#a3be8c".into(),
            warning: "#ebcb8b".into(),
            danger: "#bf616a".into(),
            niri_focus: "#88c0d0".into(),
            niri_border: "#4c566a".into(),
            rofi_selection: "#434c5e".into(),
        },
        Theme {
            id: "dracula".into(),
            name: "Dracula".into(),
            description: "Gothic vampire dark with luminous purple, pink, and lime".into(),
            wallpaper: "particles".into(),
            bg: "#282a36".into(),
            bg_alpha: "#E6282a36".into(),
            bg_alt: "#343746".into(),
            surface: "#21222c".into(),
            surface_hover: "#44475a".into(),
            surface_card: "#343746".into(),
            accent: "#bd93f9".into(),
            accent_secondary: "#ff79c6".into(),
            accent_tertiary: "#8be9fd".into(),
            border: "#44475a".into(),
            border_active: "#bd93f9".into(),
            fg: "#f8f8f2".into(),
            fg_secondary: "#e2e2dc".into(),
            fg_muted: "#6272a4".into(),
            success: "#50fa7b".into(),
            warning: "#f1fa8c".into(),
            danger: "#ff5555".into(),
            niri_focus: "#bd93f9".into(),
            niri_border: "#6272a4".into(),
            rofi_selection: "#44475a".into(),
        },
        Theme {
            id: "rose-pine".into(),
            name: "Rose Pine".into(),
            description: "Warm ethereal pine, rose, and gold minimal aesthetic".into(),
            wallpaper: "waves".into(),
            bg: "#191724".into(),
            bg_alpha: "#E6191724".into(),
            bg_alt: "#26233a".into(),
            surface: "#1f1d2e".into(),
            surface_hover: "#2a283e".into(),
            surface_card: "#26233a".into(),
            accent: "#ebbcba".into(),
            accent_secondary: "#c4a7e7".into(),
            accent_tertiary: "#9ccfd8".into(),
            border: "#312f44".into(),
            border_active: "#ebbcba".into(),
            fg: "#e0def4".into(),
            fg_secondary: "#908caa".into(),
            fg_muted: "#6e6a86".into(),
            success: "#31748f".into(),
            warning: "#f6c177".into(),
            danger: "#eb6f92".into(),
            niri_focus: "#ebbcba".into(),
            niri_border: "#524f67".into(),
            rofi_selection: "#312f44".into(),
        },
        Theme {
            id: "gruvbox-dark".into(),
            name: "Gruvbox Dark".into(),
            description: "Warm retro amber, forest green, and earthy terracotta".into(),
            wallpaper: "fallback".into(),
            bg: "#282828".into(),
            bg_alpha: "#E6282828".into(),
            bg_alt: "#3c3836".into(),
            surface: "#1d2021".into(),
            surface_hover: "#504945".into(),
            surface_card: "#3c3836".into(),
            accent: "#fabd2f".into(),
            accent_secondary: "#fe8019".into(),
            accent_tertiary: "#8ec07c".into(),
            border: "#504945".into(),
            border_active: "#fabd2f".into(),
            fg: "#ebdbb2".into(),
            fg_secondary: "#d5c4a1".into(),
            fg_muted: "#928374".into(),
            success: "#b8bb26".into(),
            warning: "#fabd2f".into(),
            danger: "#fb4934".into(),
            niri_focus: "#fabd2f".into(),
            niri_border: "#665c54".into(),
            rofi_selection: "#504945".into(),
        },
    ]
}

fn home_dir() -> PathBuf {
    std::env::var("HOME").map(PathBuf::from).unwrap_or_else(|_| PathBuf::from("/home/aryan"))
}

fn dark_niri_dir() -> PathBuf {
    home_dir().join("DARK_NIRI")
}

fn get_active_theme_id() -> String {
    let state_file = home_dir().join(".config/niri/current_theme.json");
    if let Ok(content) = fs::read_to_string(&state_file) {
        if let Ok(val) = serde_json::from_str::<serde_json::Value>(&content) {
            if let Some(id) = val.get("id").and_then(|v| v.as_str()) {
                return id.to_string();
            }
        }
    }
    "tokyo-night".to_string()
}

fn apply_theme(theme: &Theme) -> Result<(), Box<dyn std::error::Error>> {
    let home = home_dir();
    let root = dark_niri_dir();

    // 1. Save state to ~/.config/niri/current_theme.json
    let config_dir = home.join(".config/niri");
    fs::create_dir_all(&config_dir)?;
    let theme_json = serde_json::to_string_pretty(theme)?;
    fs::write(config_dir.join("current_theme.json"), &theme_json)?;

    // 2. Write quickshell/theme.json
    let qs_theme = root.join("quickshell/theme.json");
    fs::write(&qs_theme, &theme_json)?;

    // 3. Write rofi/theme.rasi
    let rofi_theme = format!(
        r#"/* Generated by theme-manager for {} */
* {{
    bg: {};
    bg-alt: {};
    fg: {};
    accent: {};
    border-color: {};
    selected-bg: {};
}}
"#,
        theme.name, theme.bg_alpha, theme.bg_alt, theme.fg, theme.accent, theme.border, theme.rofi_selection
    );
    fs::write(root.join("rofi/theme.rasi"), rofi_theme)?;

    // 4. Write fuzzel/fuzzel.ini
    let clean_hex = |c: &str| c.trim_start_matches('#').to_string();
    let fuzzel_ini = format!(
        r#"[main]
font=Inter:size=12
terminal=alacritty
prompt="> "
icon-theme=Papirus-Dark
icons-enabled=yes
lines=10
width=40
horizontal-pad=40
vertical-pad=20
inner-pad=10

[colors]
background={}ff
text={}ff
match={}ff
selection={}ff
selection-text={}ff
border={}ff

[border]
width=2
radius=10
"#,
        clean_hex(&theme.bg),
        clean_hex(&theme.fg_secondary),
        clean_hex(&theme.accent),
        clean_hex(&theme.rofi_selection),
        clean_hex(&theme.fg),
        clean_hex(&theme.accent)
    );
    fs::write(root.join("fuzzel/fuzzel.ini"), fuzzel_ini)?;

    // 5. Write mako/config & reload
    let mako_config = format!(
        r#"background-color={}
text-color={}
border-color={}
border-size=2
border-radius=10
width=320
height=110
margin=12,12,12,12
padding=12
font=Inter 11
default-timeout=5000
"#,
        theme.bg, theme.fg, theme.accent
    );
    fs::write(root.join("mako/config"), mako_config)?;
    let _ = Command::new("makoctl").arg("reload").spawn();

    // 6. Write niri/theme.kdl & reload
    let niri_theme = format!(
        r#"// Generated by theme-manager for {}
layout {{
    focus-ring {{
        off
        width 2
        active-color "{}"
        inactive-color "{}"
    }}
    border {{
        off
        width 1
        active-color "{}"
        inactive-color "{}"
    }}
}}
"#,
        theme.name, theme.niri_focus, theme.border, theme.niri_focus, theme.niri_border
    );
    fs::write(root.join("niri/theme.kdl"), niri_theme)?;
    let _ = Command::new("niri").args(["msg", "action", "load-config-file"]).spawn();

    // 7. Update Wallpaper Engine
    let wp_ctl = root.join("quickshell/wallpaper-engine/wallpaperctl");
    if wp_ctl.exists() && !theme.wallpaper.is_empty() {
        let _ = Command::new(&wp_ctl).args(["set", &theme.wallpaper]).spawn();
    }

    // 8. Send desktop notification
    let _ = Command::new("notify-send")
        .args([
            "Dark Niri",
            &format!("Theme applied: {}", theme.name),
            "-i",
            "preferences-desktop-theme",
        ])
        .spawn();

    Ok(())
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BarStyle {
    pub id: String,
    pub name: String,
    pub description: String,
    pub icon: String,
}

fn get_bar_styles() -> Vec<BarStyle> {
    vec![
        BarStyle {
            id: "floating".into(),
            name: "Floating".into(),
            description: "Unified neo-glass floating island dock with rounded corners".into(),
            icon: "󰹬".into(),
        },
        BarStyle {
            id: "islands".into(),
            name: "Islands".into(),
            description: "Modular split 3-piece floating capsules for Left, Center, and Right".into(),
            icon: "󰮊".into(),
        },
        BarStyle {
            id: "normal".into(),
            name: "Normal".into(),
            description: "Classic edge-to-edge status bar docked flush to top".into(),
            icon: "󰵊".into(),
        },
        BarStyle {
            id: "compact".into(),
            name: "Compact".into(),
            description: "Ultra-slim sleek floating profile with minimal padding".into(),
            icon: "󰍹".into(),
        },
    ]
}

fn get_bar_style_path() -> PathBuf {
    if let Ok(home) = std::env::var("HOME") {
        PathBuf::from(home).join(".config/niri/bar_style.json")
    } else {
        PathBuf::from("/tmp/bar_style.json")
    }
}

fn get_active_bar_style_id() -> String {
    let path = get_bar_style_path();
    if let Ok(content) = fs::read_to_string(&path) {
        if let Ok(val) = serde_json::from_str::<serde_json::Value>(&content) {
            if let Some(s) = val.get("style").and_then(|v| v.as_str()) {
                return s.to_string();
            }
        }
    }
    // Fallback: check quickshell/bar_style.json
    if let Ok(home) = std::env::var("HOME") {
        let qs_path = PathBuf::from(home).join("DARK_NIRI/quickshell/bar_style.json");
        if let Ok(content) = fs::read_to_string(qs_path) {
            if let Ok(val) = serde_json::from_str::<serde_json::Value>(&content) {
                if let Some(s) = val.get("style").and_then(|v| v.as_str()) {
                    return s.to_string();
                }
            }
        }
    }
    "floating".to_string()
}

fn set_active_bar_style(style: &str) -> std::io::Result<()> {
    let path = get_bar_style_path();
    if let Some(parent) = path.parent() {
        let _ = fs::create_dir_all(parent);
    }
    let data = serde_json::json!({
        "style": style
    });
    fs::write(&path, serde_json::to_string_pretty(&data)?)?;

    if let Ok(home) = std::env::var("HOME") {
        let qs_path = PathBuf::from(home).join("DARK_NIRI/quickshell/bar_style.json");
        let _ = fs::write(qs_path, serde_json::to_string_pretty(&data)?);
    }

    Ok(())
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let themes = get_themes();
    let active_id = get_active_theme_id();

    let cmd = args.get(1).map(|s| s.as_str()).unwrap_or("current");

    match cmd {
        "list" => {
            #[derive(Serialize)]
            struct ThemeItem<'a> {
                #[serde(flatten)]
                theme: &'a Theme,
                is_active: bool,
            }

            let items: Vec<ThemeItem> = themes
                .iter()
                .map(|t| ThemeItem {
                    theme: t,
                    is_active: t.id == active_id,
                })
                .collect();

            println!("{}", serde_json::to_string(&items).unwrap());
        }
        "current" => {
            if let Some(t) = themes.iter().find(|t| t.id == active_id) {
                println!("{}", serde_json::to_string(t).unwrap());
            } else if let Some(t) = themes.first() {
                println!("{}", serde_json::to_string(t).unwrap());
            }
        }
        "apply" => {
            let target_id = args.get(2).map(|s| s.as_str()).unwrap_or("tokyo-night");
            if let Some(t) = themes.iter().find(|t| t.id == target_id) {
                if let Err(e) = apply_theme(t) {
                    eprintln!("Error applying theme: {}", e);
                    std::process::exit(1);
                }
                println!("Successfully applied theme: {}", t.name);
            } else {
                eprintln!("Unknown theme: {}. Available: {:?}", target_id, themes.iter().map(|t| &t.id).collect::<Vec<_>>());
                std::process::exit(1);
            }
        }
        "next" => {
            let idx = themes.iter().position(|t| t.id == active_id).unwrap_or(0);
            let next_idx = (idx + 1) % themes.len();
            let next_theme = &themes[next_idx];
            if let Err(e) = apply_theme(next_theme) {
                eprintln!("Error applying theme: {}", e);
                std::process::exit(1);
            }
            println!("Switched to: {}", next_theme.name);
        }
        "bar-style" => {
            let sub = args.get(2).map(|s| s.as_str()).unwrap_or("get");
            match sub {
                "get" => {
                    let active = get_active_bar_style_id();
                    println!("{}", serde_json::json!({"style": active}));
                }
                "set" => {
                    let style = args.get(3).map(|s| s.as_str()).unwrap_or("floating");
                    let valid_styles = ["floating", "islands", "normal", "compact"];
                    if !valid_styles.contains(&style) {
                        eprintln!("Unknown bar style: {}. Available: {:?}", style, valid_styles);
                        std::process::exit(1);
                    }
                    if let Err(e) = set_active_bar_style(style) {
                        eprintln!("Error saving bar style: {}", e);
                        std::process::exit(1);
                    }
                    println!("Set bar style to: {}", style);
                }
                "list" => {
                    #[derive(Serialize)]
                    struct BarStyleItem<'a> {
                        #[serde(flatten)]
                        style: &'a BarStyle,
                        is_active: bool,
                    }
                    let styles = get_bar_styles();
                    let active = get_active_bar_style_id();
                    let items: Vec<BarStyleItem> = styles
                        .iter()
                        .map(|s| BarStyleItem {
                            style: s,
                            is_active: s.id == active,
                        })
                        .collect();
                    println!("{}", serde_json::to_string(&items).unwrap());
                }
                _ => {
                    println!("Usage: theme-manager bar-style <get|set <style>|list>");
                }
            }
        }
        _ => {
            println!("Usage: theme-manager <list|current|apply <id>|next|bar-style <get|set|list>>");
        }
    }
}
