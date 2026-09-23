#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  mute-spotify-ads.sh
#  Automatically mutes Spotify's PulseAudio/PipeWire stream
#  while an advertisement is playing, and unmutes when music
#  resumes.  Uses playerctl --follow (no polling loop).
#
#  Ad detection uses multiple signals since Spotify's MPRIS
#  implementation is inconsistent:
#    1. trackid contains "/com/spotify/ad/"
#    2. xesam:url is empty or doesn't contain "open.spotify.com/track"
#    3. xesam:artist is empty or literally "Spotify"
# ─────────────────────────────────────────────────────────────

set -euo pipefail

RETRY_INTERVAL=5   # seconds to wait before retrying when Spotify isn't running
MUTED=0            # track current mute state to avoid redundant pactl calls

# ── Helpers ──────────────────────────────────────────────────

get_spotify_sink_input_id() {
    # Returns the PulseAudio/PipeWire sink-input index whose
    # application.name matches "spotify" (case-insensitive).
    pactl list sink-inputs 2>/dev/null \
        | awk '
            /^Sink Input #/ { idx = $3; sub(/#/, "", idx) }
            /application\.name/ {
                val = $0; sub(/.*= "/, "", val); sub(/".*/, "", val)
                if (tolower(val) == "spotify") { print idx; exit }
            }
        '
}

set_spotify_mute() {
    local mute_flag="$1"   # 1 = mute, 0 = unmute
    local sink_id
    sink_id=$(get_spotify_sink_input_id)
    if [[ -n "$sink_id" ]]; then
        pactl set-sink-input-mute "$sink_id" "$mute_flag"
    fi
}

is_ad() {
    # Check multiple metadata fields to reliably detect ads.
    # Returns 0 (true) if an ad is detected, 1 (false) otherwise.
    local trackid="$1"
    local url="$2"
    local artist="$3"

    # If all fields are empty, Spotify is closing/pausing — not an ad
    if [[ -z "$trackid" && -z "$url" && -z "$artist" ]]; then
        return 1
    fi

    # Signal 1: trackid contains the ad path (most reliable)
    if [[ "$trackid" == */com/spotify/ad/* ]]; then
        return 0
    fi

    # Signal 2: URL contains /ad/ instead of /track/
    if [[ -n "$url" && "$url" == *"open.spotify.com/ad/"* ]]; then
        return 0
    fi

    # Signal 3: URL is missing AND artist is generic/empty (both together = likely ad)
    local artist_lower
    artist_lower=$(echo "$artist" | tr '[:upper:]' '[:lower:]')
    if [[ -z "$url" && ( -z "$artist" || "$artist_lower" == "spotify" ) ]]; then
        return 0
    fi

    return 1
}

# ── Main loop ────────────────────────────────────────────────

while true; do
    # If playerctl can't find Spotify, wait and retry.
    if ! playerctl -p spotify status &>/dev/null; then
        MUTED=0
        sleep "$RETRY_INTERVAL"
        continue
    fi

    # Follow metadata changes. Output all fields we need in a parseable format.
    # This blocks until Spotify exits or the stream ends,
    # then the outer while-loop retries.
    MUTED=0
    playerctl -p spotify metadata --follow \
        --format '{{mpris:trackid}}	{{xesam:url}}	{{artist}}	{{title}}' 2>/dev/null \
        | while IFS=$'\t' read -r trackid url artist title; do
            if is_ad "$trackid" "$url" "$artist"; then
                if [[ "$MUTED" -eq 0 ]]; then
                    echo "[mute-spotify-ads] AD detected (trackid=$trackid url=$url artist=$artist) — muting"
                    set_spotify_mute 1
                    MUTED=1
                fi
            else
                if [[ "$MUTED" -eq 1 ]]; then
                    echo "[mute-spotify-ads] Music resumed: $artist - $title — unmuting"
                    set_spotify_mute 0
                    MUTED=0
                else
                    # First track or track change during music — ensure unmuted
                    set_spotify_mute 0
                fi
            fi
        done

    # playerctl exited (Spotify closed) — wait before retrying
    MUTED=0
    sleep "$RETRY_INTERVAL"
done
