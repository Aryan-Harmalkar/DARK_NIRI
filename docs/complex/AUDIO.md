# 🔊 Audio Subsystem & PipeWire Integration

This document details audio volume management, sink/source muting, and OSD integration across Dark Niri.

---

## 1. Audio Architecture

Dark Niri relies on **PipeWire** with **WirePlumber** as the session manager.

### 1.1 Volume & Muting Commands
- **Master Sink Volume**: `wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ <val>%`
- **Master Sink Mute Toggle**: `wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle`
- **Microphone Source Mute Toggle**: `wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle`
- **Volume Query**: `wpctl get-volume @DEFAULT_AUDIO_SINK@`

---

## 2. On-Screen Display (`niri/osd.sh`)

`osd.sh` provides in-place visual feedback for volume and brightness keypresses:
```bash
HINT="string:x-canonical-private-synchronous:sys-osd"
notify-send -h "$HINT" -h int:value:$VOL "Volume" "Volume: ${VOL}%" -i audio-volume-high
```
- **Synchronous Replacement Hint**: `x-canonical-private-synchronous:sys-osd` tells Mako to replace the active notification in-place instead of stacking multiple notifications.
- **Progress Gauge Hint**: `-h int:value:<percentage>` displays a native progress bar inside Mako.
