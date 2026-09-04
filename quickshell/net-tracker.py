#!/usr/bin/env python3
import sys
import os
import glob
import json
import time
import subprocess

DATA_DIR = os.path.expanduser("~/.local/share/quickshell")
USAGE_FILE = os.path.join(DATA_DIR, "network_usage.json")

def get_boot_id():
    try:
        with open("/proc/sys/kernel/random/boot_id", "r") as f:
            return f.read().strip()
    except Exception:
        return "unknown"

def fmt_bytes(b):
    if b >= 1024**3:
        return f"{b / (1024**3):.1f} GB"
    elif b >= 1024**2:
        return f"{b / (1024**2):.1f} MB"
    elif b >= 1024:
        return f"{b / 1024:.0f} KB"
    else:
        return f"{b} B"

def is_physical_interface(dev_path):
    iface = os.path.basename(dev_path)
    # Exclude virtual / container / VPN tunnels
    if iface.startswith(("lo", "docker", "veth", "virbr", "br-", "tun", "wg", "tailscale", "dummy", "zt")):
        return False
    # Check if sysfs reports a hardware device link
    if os.path.exists(os.path.join(dev_path, "device")):
        return True
    # Fallback to physical naming schemes (Wi-Fi, Ethernet, USB tethering, WWAN)
    if iface.startswith(("wlan", "wlp", "enp", "eth", "eno", "usb", "enx", "wwan", "wwp")):
        return True
    return False

def update_usage():
    os.makedirs(DATA_DIR, exist_ok=True)
    cur_date = time.strftime("%Y-%m-%d")
    cur_month = time.strftime("%Y-%m")
    boot_id = get_boot_id()

    data = {}
    if os.path.exists(USAGE_FILE):
        try:
            with open(USAGE_FILE, "r") as f:
                data = json.load(f)
        except Exception:
            data = {}

    saved_boot_id = data.get("boot_id", "")
    saved_date = data.get("date", cur_date)
    saved_month = data.get("month", cur_month)
    day_bytes = data.get("day_bytes", 0)
    month_bytes = data.get("month_bytes", 0)
    saved_ifaces = data.get("ifaces", {})

    # Rollover logic
    if cur_date != saved_date:
        day_bytes = 0
        saved_date = cur_date
    if cur_month != saved_month:
        month_bytes = 0
        saved_month = cur_month

    is_new_boot = (boot_id != saved_boot_id)

    curr_ifaces = {}
    total_delta = 0

    for dev_path in glob.glob("/sys/class/net/*"):
        if not is_physical_interface(dev_path):
            continue
        iface = os.path.basename(dev_path)
        try:
            with open(os.path.join(dev_path, "statistics/rx_bytes")) as f:
                rx = int(f.read().strip())
            with open(os.path.join(dev_path, "statistics/tx_bytes")) as f:
                tx = int(f.read().strip())
            total = rx + tx
            curr_ifaces[iface] = total

            prev = saved_ifaces.get(iface, 0)
            if not data:
                # Initial baseline
                delta = 0
            elif is_new_boot:
                # New boot: kernel counters restarted from 0
                delta = total
            else:
                if total >= prev:
                    delta = total - prev
                else:
                    # Interface reconnected/reset
                    delta = total
            total_delta += delta
        except Exception:
            pass

    day_bytes += total_delta
    month_bytes += total_delta
    saved_ifaces.update(curr_ifaces)

    data = {
        "boot_id": boot_id,
        "date": cur_date,
        "month": cur_month,
        "day_bytes": day_bytes,
        "month_bytes": month_bytes,
        "ifaces": saved_ifaces
    }

    try:
        with open(USAGE_FILE + ".tmp", "w") as f:
            json.dump(data, f)
        os.replace(USAGE_FILE + ".tmp", USAGE_FILE)
    except Exception:
        pass

    return day_bytes, month_bytes

def get_active_network():
    try:
        proc = subprocess.run(
            ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION,DEVICE", "dev"],
            capture_output=True, text=True, timeout=2
        )
        for line in proc.stdout.strip().split("\n"):
            if not line:
                continue
            parts = line.split(":")
            if len(parts) >= 3 and "connected" in parts[1]:
                t, conn, dev = parts[0].lower(), parts[2], parts[3] if len(parts) > 3 else ""
                if dev == "lo" or "loopback" in t:
                    continue
                if t == "wifi":
                    return "wifi", conn
                elif t == "ethernet":
                    if "usb" in dev.lower() or "enx" in dev.lower() or "rndis" in dev.lower() or "usb" in conn.lower():
                        return "usb", (conn if conn else "USB Tethering")
                    else:
                        return "ethernet", (conn if conn else "Ethernet")
                elif t in ["gsm", "cdma", "wwan"]:
                    return "cellular", (conn if conn else "Cellular")
        return "none", "Disconnected"
    except Exception:
        return "none", "Disconnected"

if __name__ == "__main__":
    action = sys.argv[1] if len(sys.argv) > 1 else "--get"
    if action == "--update":
        update_usage()
    elif action == "--type":
        net_type, net_name = get_active_network()
        print(f"{net_type}|{net_name}")
    else:
        d_bytes, m_bytes = update_usage()
        print(f"{fmt_bytes(d_bytes)}|{fmt_bytes(m_bytes)}")
