import subprocess
import json

try:
    res = subprocess.run(["/home/aryan/DARK_NIRI/quickshell/wallpaper-engine/wallpaperctl", "list"], capture_output=True, text=True)
    try:
        data = json.loads(res.stdout.strip())
        print("Valid JSON array of length:", len(data))
    except json.JSONDecodeError as e:
        print("JSON Decode Error:", e)
        print("Raw output:", res.stdout)
except Exception as e:
    print("Execution Error:", e)
