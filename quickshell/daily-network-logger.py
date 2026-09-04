#!/usr/bin/env python3
"""
Daily Internet Data Consumption Tracker by Wi-Fi Network & Physical Interfaces.
Logs daily statistics to monthly Markdown tables in ~/Data Consumption/YYYY-MM.md.
"""

import os
import sys
import glob
import json
import time
import subprocess
from datetime import datetime

HOME_DIR = os.path.expanduser("~")
CONSUMPTION_DIR = os.path.join(HOME_DIR, "Data Consumption")
STATE_DIR = os.path.join(HOME_DIR, ".local", "share", "quickshell")
STATE_FILE = os.path.join(STATE_DIR, "network_logger_state.json")

def get_boot_id():
    try:
        with open("/proc/sys/kernel/random/boot_id", "r") as f:
            return f.read().strip()
    except Exception:
        return "unknown"

def fmt_bytes(b):
    if b >= 1024**3:
        # 3 decimal places for GB (e.g., 1.234 GB)
        return f"{b / (1024**3):.3f} GB"
    elif b >= 1024**2:
        return f"{b / (1024**2):.1f} MB"
    elif b >= 1024:
        return f"{b / 1024:.0f} KB"
    else:
        return f"{b} B"

def is_physical_interface(dev_path):
    iface = os.path.basename(dev_path)
    if iface.startswith(("lo", "docker", "veth", "virbr", "br-", "tun", "wg", "tailscale", "dummy", "zt")):
        return False
    if os.path.exists(os.path.join(dev_path, "device")):
        return True
    if iface.startswith(("wlan", "wlp", "enp", "eth", "eno", "usb", "enx", "wwan", "wwp")):
        return True
    return False

def get_active_network_for_interface(iface):
    """Detects SSID or connection name for a specific interface."""
    try:
        proc = subprocess.run(
            ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "dev"],
            capture_output=True, text=True, timeout=2
        )
        for line in proc.stdout.strip().split("\n"):
            if not line:
                continue
            parts = line.split(":")
            if len(parts) >= 4 and parts[0] == iface and "connected" in parts[2]:
                conn_name = parts[3].strip()
                dev_type = parts[1].strip().lower()
                if conn_name:
                    return conn_name
                if dev_type == "wifi":
                    return "Wi-Fi"
                elif dev_type == "ethernet":
                    return "Ethernet"
    except Exception:
        pass
    
    # Fallback heuristic based on interface name
    if iface.startswith(("wlan", "wlp")):
        try:
            ssid_proc = subprocess.run(["iwgetid", "-r"], capture_output=True, text=True, timeout=1)
            ssid = ssid_proc.stdout.strip()
            if ssid:
                return ssid
        except Exception:
            pass
        return "Wi-Fi"
    elif iface.startswith(("usb", "enx")):
        return "USB Tethering"
    elif iface.startswith(("enp", "eth", "eno")):
        return "Ethernet"
    elif iface.startswith(("wwan", "wwp")):
        return "Cellular"
    return "Network"

def load_state():
    if os.path.exists(STATE_FILE):
        try:
            with open(STATE_FILE, "r") as f:
                return json.load(f)
        except Exception:
            pass
    return {
        "boot_id": get_boot_id(),
        "iface_stats": {},
        "records": {}
    }

def save_state(state):
    os.makedirs(STATE_DIR, exist_ok=True)
    try:
        with open(STATE_FILE + ".tmp", "w") as f:
            json.dump(state, f, indent=2)
        os.replace(STATE_FILE + ".tmp", STATE_FILE)
    except Exception:
        pass

def update_data_consumption():
    os.makedirs(CONSUMPTION_DIR, exist_ok=True)
    now = datetime.now()
    cur_month = now.strftime("%Y-%m")
    cur_date = now.strftime("%Y-%m-%d")
    cur_boot_id = get_boot_id()

    state = load_state()
    saved_boot_id = state.get("boot_id", "")
    is_new_boot = (cur_boot_id != saved_boot_id)
    saved_ifaces = state.get("iface_stats", {})
    records = state.get("records", {})

    if cur_month not in records:
        records[cur_month] = {}
    if cur_date not in records[cur_month]:
        records[cur_month][cur_date] = {}

    for dev_path in glob.glob("/sys/class/net/*"):
        if not is_physical_interface(dev_path):
            continue
        iface = os.path.basename(dev_path)
        try:
            with open(os.path.join(dev_path, "statistics/rx_bytes")) as f:
                rx = int(f.read().strip())
            with open(os.path.join(dev_path, "statistics/tx_bytes")) as f:
                tx = int(f.read().strip())
            
            if iface not in saved_ifaces:
                # Newly detected interface: initialize baseline
                saved_ifaces[iface] = {"rx": rx, "tx": tx}
                delta_rx = 0
                delta_tx = 0
            elif is_new_boot:
                delta_rx = rx
                delta_tx = tx
                saved_ifaces[iface] = {"rx": rx, "tx": tx}
            else:
                prev = saved_ifaces[iface]
                delta_rx = rx - prev.get("rx", 0) if rx >= prev.get("rx", 0) else rx
                delta_tx = tx - prev.get("tx", 0) if tx >= prev.get("tx", 0) else tx
                saved_ifaces[iface] = {"rx": rx, "tx": tx}

            if delta_rx > 0 or delta_tx > 0:
                net_name = get_active_network_for_interface(iface)
                if net_name not in records[cur_month][cur_date]:
                    records[cur_month][cur_date][net_name] = {"rx": 0, "tx": 0}
                records[cur_month][cur_date][net_name]["rx"] += delta_rx
                records[cur_month][cur_date][net_name]["tx"] += delta_tx
        except Exception:
            pass

    state["boot_id"] = cur_boot_id
    state["iface_stats"] = saved_ifaces
    state["records"] = records
    save_state(state)

    # Render Markdown table for the current month
    render_month_markdown(cur_month, records.get(cur_month, {}))

def render_month_markdown(month_str, month_records):
    os.makedirs(CONSUMPTION_DIR, exist_ok=True)
    md_file = os.path.join(CONSUMPTION_DIR, f"{month_str}.md")
    
    # Month Title
    try:
        month_dt = datetime.strptime(month_str, "%Y-%m")
        month_name = month_dt.strftime("%B %Y")
    except Exception:
        month_name = month_str

    lines = [
        f"# Internet Data Consumption - {month_name}",
        "",
        "| Date | Wi-Fi / Network | Downloaded | Uploaded | Total |",
        "| :--- | :--- | :--- | :--- | :--- |"
    ]

    total_month_rx = 0
    total_month_tx = 0

    # Sort dates chronologically
    sorted_dates = sorted(month_records.keys())
    for d in sorted_dates:
        networks = month_records[d]
        sorted_nets = sorted(networks.keys())
        for net in sorted_nets:
            rx = networks[net].get("rx", 0)
            tx = networks[net].get("tx", 0)
            total = rx + tx
            total_month_rx += rx
            total_month_tx += tx
            lines.append(f"| {d} | {net} | {fmt_bytes(rx)} | {fmt_bytes(tx)} | {fmt_bytes(total)} |")

    # If no data yet, provide a placeholder row
    if not sorted_dates:
        lines.append(f"| {datetime.now().strftime('%Y-%m-%d')} | No active traffic | 0 B | 0 B | 0 B |")

    lines.append("")
    lines.append("### Monthly Summary")
    lines.append(f"- **Total Downloaded**: `{fmt_bytes(total_month_rx)}`")
    lines.append(f"- **Total Uploaded**: `{fmt_bytes(total_month_tx)}`")
    lines.append(f"- **Grand Total**: `{fmt_bytes(total_month_rx + total_month_tx)}`")
    lines.append("")
    lines.append(f"*Last updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}*")
    lines.append("")

    content = "\n".join(lines)
    try:
        with open(md_file + ".tmp", "w") as f:
            f.write(content)
        os.replace(md_file + ".tmp", md_file)
    except Exception:
        pass

def show_current_month():
    cur_month = datetime.now().strftime("%Y-%m")
    md_file = os.path.join(CONSUMPTION_DIR, f"{cur_month}.md")
    if os.path.exists(md_file):
        with open(md_file, "r") as f:
            print(f.read())
    else:
        print(f"No records found yet for {cur_month}.")

if __name__ == "__main__":
    action = sys.argv[1] if len(sys.argv) > 1 else "--update"
    if action == "--show":
        update_data_consumption()
        show_current_month()
    else:
        update_data_consumption()
