#!/usr/bin/env python3
import sys
import subprocess
import json
import os

DISMISSED_FILE = '/tmp/qs_dismissed.json'

def get_dismissed():
    if os.path.exists(DISMISSED_FILE):
        try:
            with open(DISMISSED_FILE, 'r') as f:
                return set(json.load(f))
        except Exception:
            return set()
    return set()

def save_dismissed(dismissed):
    try:
        with open(DISMISSED_FILE, 'w') as f:
            json.dump(list(dismissed), f)
    except Exception:
        pass

def get_notifications():
    hist = []
    try:
        hist_out = subprocess.run(['makoctl', 'history', '-j'], capture_output=True, text=True, timeout=3).stdout
        if hist_out.strip():
            hist = json.loads(hist_out)
    except Exception:
        pass
        
    active = []
    try:
        active_out = subprocess.run(['makoctl', 'list', '-j'], capture_output=True, text=True, timeout=3).stdout
        if active_out.strip():
            active = json.loads(active_out)
    except Exception:
        pass

    dismissed = get_dismissed()
    items = []
    seen = set()

    for n in (active + hist):
        nid = n.get('id')
        if nid is None or nid in seen or nid in dismissed:
            continue
        seen.add(nid)
        
        app = n.get('app_name') or 'System'
        summary = n.get('summary') or 'Notification'
        body = n.get('body') or ''
        urgency = n.get('urgency') or 'normal'
        
        items.append({
            'id': nid,
            'app': app,
            'summary': summary,
            'body': body,
            'urgency': urgency
        })
    return items

def dismiss(nid):
    dismissed = get_dismissed()
    try:
        dismissed.add(int(nid))
    except Exception:
        dismissed.add(nid)
    save_dismissed(dismissed)
    subprocess.run(['makoctl', 'dismiss', '-n', str(nid)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def clear_all():
    notifs = get_notifications()
    dismissed = get_dismissed()
    for n in notifs:
        dismissed.add(n['id'])
    save_dismissed(dismissed)
    subprocess.run(['makoctl', 'dismiss', '-a'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

if __name__ == '__main__':
    action = sys.argv[1] if len(sys.argv) > 1 else 'list'
    if action == 'list':
        print(json.dumps(get_notifications()))
    elif action == 'dismiss' and len(sys.argv) > 2:
        dismiss(sys.argv[2])
        print(json.dumps(get_notifications()))
    elif action == 'clear':
        clear_all()
        print(json.dumps([]))
    elif action == 'count':
        print(len(get_notifications()))
