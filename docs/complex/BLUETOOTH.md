# 🔵 Bluetooth Subsystem & Audio Profiles

This document details the Bluetooth management pipeline handled by `quickshell/bluetooth.sh` and rendered in `quickshell/components/Bluetooth.qml` and `Settings.qml`.

---

## 1. Bluetooth Management Architecture

`bluetooth.sh` is a Python 3 backend that orchestrates `bluetoothctl` and `pactl` to provide device discovery, pairing, battery status, and PulseAudio/PipeWire audio profile switching.

### Actions Supported
- `list`: Interrogates `bluetoothctl show`, `bluetoothctl devices`, and `bluetoothctl info <mac>`. Interrogates `pactl list cards` for available audio profiles. Outputs structured JSON.
- `toggle`: Toggles Bluetooth controller power state.
- `scan`: Initiates an 8-second asynchronous background discovery scan.
- `pair <mac>`: Pairs and trusts device.
- `connect <mac>`: Connects to device.
- `disconnect <mac>`: Disconnects device.
- `forget <mac>`: Removes paired device.
- `profile <mac> <profile_id>`: Switches card profile (e.g. `a2dp_sink` vs `headset_head_unit`).

---

## 2. Audio Profile Switching (A2DP vs HSP/HFP)

`bluetooth.sh` parses PulseAudio/PipeWire card profiles matching `bluez_card.<mac>`:
```python
def set_profile(mac, profile):
    card_name = f"bluez_card.{mac.replace(':', '_')}"
    subprocess.run(['pactl', 'set-card-profile', card_name, profile])
```
This allows the user to switch seamlessly between **High Fidelity Playback (A2DP)** and **Headset / Microphone (HSP/HFP)** directly from the QuickShell Control Center.
