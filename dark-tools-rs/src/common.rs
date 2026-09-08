use std::fs;
use std::path::Path;

pub fn get_boot_id() -> String {
    fs::read_to_string("/proc/sys/kernel/random/boot_id")
        .map(|s| s.trim().to_string())
        .unwrap_or_else(|_| "unknown".to_string())
}

pub fn fmt_bytes(b: u64) -> String {
    const KB: f64 = 1024.0;
    const MB: f64 = 1024.0 * 1024.0;
    const GB: f64 = 1024.0 * 1024.0 * 1024.0;

    let fb = b as f64;
    if fb >= GB {
        format!("{:.3} GB", fb / GB)
    } else if fb >= MB {
        format!("{:.1} MB", fb / MB)
    } else if fb >= KB {
        format!("{:.0} KB", fb / KB)
    } else {
        format!("{} B", b)
    }
}

pub fn is_physical_interface(dev_path: &Path) -> bool {
    let iface = match dev_path.file_name().and_then(|n| n.to_str()) {
        Some(name) => name,
        None => return false,
    };

    // Exclude virtual / container / VPN tunnels
    let virtual_prefixes = [
        "lo", "docker", "veth", "virbr", "br-", "tun", "wg", "tailscale", "dummy", "zt",
    ];
    for prefix in &virtual_prefixes {
        if iface.starts_with(prefix) {
            return false;
        }
    }

    // Check if sysfs reports a hardware device link
    if dev_path.join("device").exists() {
        return true;
    }

    // Fallback to physical naming schemes (Wi-Fi, Ethernet, USB tethering, WWAN)
    let physical_prefixes = [
        "wlan", "wlp", "enp", "eth", "eno", "usb", "enx", "wwan", "wwp",
    ];
    for prefix in &physical_prefixes {
        if iface.starts_with(prefix) {
            return true;
        }
    }

    false
}
