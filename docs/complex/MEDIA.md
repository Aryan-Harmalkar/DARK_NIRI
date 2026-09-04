# 🎵 MPRIS Media Player Subsystem

This document covers the MPRIS media player integration implemented in `quickshell/media.sh` and `quickshell/components/Media.qml`.

---

## 1. MPRIS Architecture

```text
Media Applications (Spotify, Firefox, Chromium, MPV, VLC)
                         | (D-Bus org.mpris.MediaPlayer2)
                         v
                    playerctl
                         |
                         v
               quickshell/media.sh
                         |
                         v (Formatted: status|||artist|||title|||album|||artUrl)
           quickshell/components/Media.qml
```

---

## 2. Metadata Extraction (`media.sh`)

The script executes:
```bash
playerctl metadata --format "{{ status }}|||{{ artist }}|||{{ title }}|||{{ album }}|||{{ mpris:artUrl }}" 2>/dev/null
```
- **Delimiter**: `|||` prevents collisions with track titles containing spaces or punctuation.
- **Empty State**: If no active player is detected, outputs an empty string, causing `Media.qml` to collapse smoothly (`implicitWidth: 0`).

---

## 3. UI Component Features (`Media.qml`)

- **Interactive Pill**: Displays animated equalizer icon, artist, and track title on the top bar.
- **Hover & Popup Card**:
  - Displays high-resolution album art (supports `file://`, `https://`, and `http://` protocols).
  - Playback buttons: Previous (`playerctl previous`), Play/Pause toggle (`playerctl play-pause`), Next (`playerctl next`).
  - Text eliding to prevent overflow on long titles.
