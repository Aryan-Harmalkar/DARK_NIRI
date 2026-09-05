#!/usr/bin/env python3
import sys
import subprocess
import json
import os

WPS_CACHE_FILE = "/tmp/wps_seen.json"

def notify_wps(ssid):
    try:
        seen = []
        if os.path.exists(WPS_CACHE_FILE):
            with open(WPS_CACHE_FILE, "r") as f:
                seen = json.load(f)
        if ssid not in seen:
            seen.append(ssid)
            with open(WPS_CACHE_FILE, "w") as f:
                json.dump(seen, f)
            subprocess.run(["notify-send", "Wi-Fi WPS", f"WPS ON detected for {ssid}", "-i", "network-wireless"])
    except Exception:
        pass

def get_wifi():
    try:
        # Get wifi status
        status_proc = subprocess.run(['nmcli', 'radio', 'wifi'], capture_output=True, text=True, timeout=5)
        wifi_enabled = status_proc.stdout.strip() == 'enabled'
        
        # Get saved connections
        saved_proc = subprocess.run(['nmcli', '-t', '-f', 'NAME,TYPE', 'connection', 'show'], capture_output=True, text=True, timeout=5)
        saved = set()
        for line in saved_proc.stdout.strip().split('\n'):
            parts = line.split(':')
            if len(parts) >= 2 and 'wireless' in parts[1]:
                saved.add(parts[0])
                
        # Get visible networks (omitting BSSID to avoid colon splits)
        dev_proc = subprocess.run(['nmcli', '-t', '-f', 'SSID,BAND,FREQ,SIGNAL,SECURITY,IN-USE,DBUS-PATH', 'dev', 'wifi', 'list'], capture_output=True, text=True, timeout=8)
        networks = []
        seen = set()
        for line in dev_proc.stdout.strip().split('\n'):
            if not line: continue
            parts = line.split(':')
            if len(parts) >= 6:
                ssid = parts[0].strip()
                if not ssid or ssid in seen:
                    continue
                seen.add(ssid)
                
                band = parts[1].strip() if len(parts) > 1 and parts[1].strip() else "2.4 GHz"
                signal = int(parts[3]) if len(parts) > 3 and parts[3].isdigit() else 0
                sec = parts[4].strip() if len(parts) > 4 else "Open"
                in_use = (len(parts) > 5 and parts[5].strip() == '*')
                dbus_path = parts[6].strip() if len(parts) > 6 else ""
                
                # Strict check for WPS capability on DBus (Flags 0x2=WPS, 0x4=WPS_PBC, 0x8=WPS_PIN)
                has_wps = False
                if dbus_path:
                    try:
                        ap_info = subprocess.run(['gdbus', 'call', '--system', '--dest', 'org.freedesktop.NetworkManager', '--object-path', dbus_path, '--method', 'org.freedesktop.DBus.Properties.Get', 'org.freedesktop.NetworkManager.AccessPoint', 'Flags'], capture_output=True, text=True, timeout=1)
                        if ap_info.returncode == 0 and 'uint32' in ap_info.stdout:
                            flag_str = ap_info.stdout.split('uint32')[1].replace('>', '').replace(')', '').replace(',', '').strip()
                            flag_val = int(flag_str)
                            # True WPS only if bit 0x2 (WPS), 0x4 (WPS_PBC), or 0x8 (WPS_PIN) is set
                            if (flag_val & 0xE) != 0:
                                has_wps = True
                    except Exception:
                        pass
                
                if has_wps:
                    notify_wps(ssid)
                
                networks.append({
                    'ssid': ssid,
                    'band': band,
                    'signal': signal,
                    'security': sec if sec else 'Open',
                    'connected': in_use,
                    'saved': ssid in saved,
                    'wps': has_wps
                })
        return {'enabled': wifi_enabled, 'networks': networks}
    except Exception as e:
        return {'enabled': False, 'networks': []}

def get_wifi_device():
    try:
        dev_proc = subprocess.run(['nmcli', '-t', '-f', 'DEVICE,TYPE', 'dev'], capture_output=True, text=True, timeout=3)
        for line in dev_proc.stdout.strip().split('\n'):
            parts = line.split(':')
            if len(parts) >= 2 and parts[1].strip() == 'wifi':
                return parts[0].strip()
    except Exception:
        pass
    return 'wlan0'

def connect(ssid, password=None):
    if password:
        cmd = ['nmcli', 'dev', 'wifi', 'connect', ssid, 'password', password]
    else:
        cmd = ['nmcli', 'dev', 'wifi', 'connect', ssid]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode == 0:
        subprocess.run(['notify-send', 'Wi-Fi', f'Connected to {ssid}', '-i', 'network-wireless'])
        return True
    else:
        err_msg = res.stderr.strip() or res.stdout.strip() or 'Failed to connect'
        # Filter out common nmcli boilerplate
        err_msg = err_msg.replace('Error: ', '')
        if len(err_msg) > 90:
            err_msg = err_msg[:90] + '...'
        subprocess.run(['notify-send', 'Wi-Fi Connection Failed', err_msg, '-i', 'network-wireless-offline', '-u', 'critical'])
        return False

def connect_wps(ssid):
    # Connect directly using WPS / NetworkManager
    cmd = ['nmcli', 'dev', 'wifi', 'connect', ssid]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode == 0:
        subprocess.run(['notify-send', 'Wi-Fi', f'Connected to {ssid}', '-i', 'network-wireless'])
    else:
        err_msg = res.stderr.strip() or res.stdout.strip() or 'Connection failed'
        subprocess.run(['notify-send', 'Wi-Fi Connection Failed', err_msg.replace('Error: ', '')[:90], '-i', 'network-wireless-offline', '-u', 'critical'])
    return res.returncode == 0

def connect_rofi(ssid):
    home = os.environ.get('HOME', '/home/aryan')
    rofi_theme = f"{home}/DARK_NIRI/rofi/config.rasi"
    try:
        rofi_cmd = ['rofi', '-dmenu', '-password', '-p', f'Wi-Fi: {ssid}', '-theme', rofi_theme]
        rofi_proc = subprocess.run(rofi_cmd, capture_output=True, text=True)
        pwd = rofi_proc.stdout.strip()
        if pwd:
            return connect(ssid, pwd)
    except Exception as e:
        pass
    return False

def disconnect():
    dev = get_wifi_device()
    res = subprocess.run(['nmcli', 'dev', 'disconnect', dev], capture_output=True, text=True)
    if res.returncode == 0:
        subprocess.run(['notify-send', 'Wi-Fi', 'Disconnected from Wi-Fi', '-i', 'network-wireless-disconnected'])
    return res.returncode == 0

def forget(ssid):
    res = subprocess.run(['nmcli', 'connection', 'delete', ssid], capture_output=True, text=True)
    if res.returncode == 0:
        subprocess.run(['notify-send', 'Wi-Fi', f'Forgot network {ssid}', '-i', 'edit-delete'])
    return res.returncode == 0

def toggle():
    # Toggle wifi radio
    status_proc = subprocess.run(['nmcli', 'radio', 'wifi'], capture_output=True, text=True)
    new_state = 'off' if status_proc.stdout.strip() == 'enabled' else 'on'
    subprocess.run(['nmcli', 'radio', 'wifi', new_state])
    state_str = "Enabled" if new_state == "on" else "Disabled"
    subprocess.run(['notify-send', 'Wi-Fi Radio', f'Wi-Fi has been {state_str}', '-i', 'network-wireless'])

if __name__ == '__main__':
    action = sys.argv[1] if len(sys.argv) > 1 else 'list'
    if action == 'list':
        print(json.dumps(get_wifi()))
    elif action == 'toggle':
        toggle()
    elif action == 'disconnect':
        disconnect()
    elif action == 'forget' and len(sys.argv) > 2:
        forget(sys.argv[2])
    elif action == 'connect' and len(sys.argv) > 2:
        pwd = sys.argv[3] if len(sys.argv) > 3 else None
        connect(sys.argv[2], pwd)
    elif action == 'connect-rofi' and len(sys.argv) > 2:
        connect_rofi(sys.argv[2])
    elif action == 'wps' and len(sys.argv) > 2:
        connect_wps(sys.argv[2])
    elif action == 'rescan':
        subprocess.run(['nmcli', 'dev', 'wifi', 'rescan'])
        print(json.dumps(get_wifi()))
