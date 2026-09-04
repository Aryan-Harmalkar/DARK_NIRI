#!/usr/bin/env python3
import sys
import subprocess
import json
import re

def get_bt():
    try:
        show = subprocess.run(['bluetoothctl', 'show'], capture_output=True, text=True, timeout=4).stdout
        powered = 'Powered: yes' in show
        discovering = 'Discovering: yes' in show
        
        # Get audio cards profiles from pactl
        cards_out = subprocess.run(['pactl', 'list', 'cards'], capture_output=True, text=True, timeout=4).stdout
        bt_cards = {}
        for block in cards_out.split('Card #'):
            if 'bluez_card' in block:
                mac_m = re.search(r'bluez_card\.([0-9A-Fa-f_]+)', block)
                if mac_m:
                    mac_formatted = mac_m.group(1).replace('_', ':').upper()
                    active_m = re.search(r'Active Profile:\s*(.+)', block)
                    active_p = active_m.group(1).strip() if active_m else ''
                    profiles = []
                    if 'Profiles:' in block:
                        p_section = block.split('Profiles:')[1].split('Active Profile:')[0]
                        for pline in p_section.strip().split('\n'):
                            p_match = re.match(r'\s*([a-zA-Z0-9_-]+):\s*(.+?)\s*\(', pline)
                            if p_match and p_match.group(1) != 'off':
                                p_id = p_match.group(1)
                                p_label = "High Fidelity (A2DP)" if "a2dp" in p_id else ("Headset / Mic (HSP/HFP)" if "headset" in p_id else p_match.group(2).strip())
                                # Keep unique friendly names
                                if not any(p['name'] == p_label for p in profiles):
                                    profiles.append({'id': p_id, 'name': p_label})
                    bt_cards[mac_formatted] = {'active': active_p, 'profiles': profiles}

        # Get devices
        dev_proc = subprocess.run(['bluetoothctl', 'devices'], capture_output=True, text=True, timeout=4)
        devices = []
        seen = set()
        for line in dev_proc.stdout.strip().split('\n'):
            if not line: continue
            parts = line.split(' ', 2)
            if len(parts) >= 3 and parts[0] == 'Device':
                mac = parts[1].upper()
                name = parts[2]
                seen.add(mac)
                info = subprocess.run(['bluetoothctl', 'info', mac], capture_output=True, text=True, timeout=3).stdout
                connected = 'Connected: yes' in info
                paired = 'Paired: yes' in info
                
                icon_m = re.search(r'Icon:\s*([^\n]+)', info)
                icon = icon_m.group(1).strip() if icon_m else 'generic'
                
                bat_m = re.search(r'Battery Percentage:.*\((\d+)\)', info)
                battery = int(bat_m.group(1)) if bat_m else None
                
                card_data = bt_cards.get(mac, {'active': '', 'profiles': []})
                devices.append({
                    'mac': mac,
                    'name': name,
                    'icon': icon,
                    'connected': connected,
                    'paired': paired,
                    'battery': battery,
                    'active_profile': card_data['active'],
                    'profiles': card_data['profiles']
                })
        return {'enabled': powered, 'discovering': discovering, 'devices': devices}
    except Exception as e:
        return {'enabled': False, 'discovering': False, 'devices': []}

def toggle():
    show = subprocess.run(['bluetoothctl', 'show'], capture_output=True, text=True).stdout
    if 'Powered: yes' in show:
        subprocess.run(['bluetoothctl', 'power', 'off'])
    else:
        subprocess.run(['bluetoothctl', 'power', 'on'])

def scan():
    # Start scan discovery in background
    subprocess.Popen(['bluetoothctl', '--timeout', '8', 'scan', 'on'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def pair(mac):
    subprocess.run(['bluetoothctl', 'pair', mac])
    subprocess.run(['bluetoothctl', 'trust', mac])

def connect(mac):
    subprocess.run(['bluetoothctl', 'trust', mac])
    subprocess.run(['bluetoothctl', 'connect', mac])

def disconnect(mac):
    subprocess.run(['bluetoothctl', 'disconnect', mac])

def forget(mac):
    subprocess.run(['bluetoothctl', 'remove', mac])

def set_profile(mac, profile):
    card_name = f"bluez_card.{mac.replace(':', '_')}"
    subprocess.run(['pactl', 'set-card-profile', card_name, profile])

if __name__ == '__main__':
    action = sys.argv[1] if len(sys.argv) > 1 else 'list'
    if action == 'list':
        print(json.dumps(get_bt()))
    elif action == 'toggle':
        toggle()
    elif action == 'scan':
        scan()
        print(json.dumps(get_bt()))
    elif action == 'pair' and len(sys.argv) > 2:
        pair(sys.argv[2])
    elif action == 'connect' and len(sys.argv) > 2:
        connect(sys.argv[2])
    elif action == 'disconnect' and len(sys.argv) > 2:
        disconnect(sys.argv[2])
    elif action == 'forget' and len(sys.argv) > 2:
        forget(sys.argv[2])
    elif action == 'profile' and len(sys.argv) > 3:
        set_profile(sys.argv[2], sys.argv[3])
