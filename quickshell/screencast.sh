#!/bin/bash
PID_FILE="/tmp/screencast.pid"
STATUS_FILE="/tmp/screencast.status"

case "$1" in
    start)
        if [ -f "$PID_FILE" ]; then
            notify-send "Screen Recording" "Recording already in progress"
            exit 1
        fi
        
        exec > /tmp/screencast.log 2>&1
        
        # Area selection
        AREA=$(slurp)
        if [ -z "$AREA" ]; then
            echo "slurp failed or was cancelled"
            exit 1
        fi
        
        echo "Area selected: $AREA"
        
        # Get internal audio monitor sink
        AUDIO_SINK=$(pactl get-default-sink).monitor
        echo "Audio sink: $AUDIO_SINK"
        mkdir -p "$HOME/SCREEN/screen-recording"
        FILE="$HOME/SCREEN/screen-recording/recording_$(date +%Y%m%d_%H%M%S).mp4"
        
        # Start wf-recorder
        wf-recorder -g "$AREA" -a"$AUDIO_SINK" -f "$FILE" &
        PID=$!
        echo "wf-recorder PID: $PID"
        echo $PID > "$PID_FILE"
        echo "recording" > "$STATUS_FILE"
        notify-send "Screen Recording" "Started recording..." -i media-record
        ;;
    pause)
        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            STATUS=$(cat "$STATUS_FILE")
            if [ "$STATUS" = "recording" ]; then
                kill -STOP $PID
                echo "paused" > "$STATUS_FILE"
                notify-send "Screen Recording" "Paused" -i media-playback-pause
            elif [ "$STATUS" = "paused" ]; then
                kill -CONT $PID
                echo "recording" > "$STATUS_FILE"
                notify-send "Screen Recording" "Resumed" -i media-record
            fi
        fi
        ;;
    stop)
        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            kill -SIGINT $PID
            rm -f "$PID_FILE" "$STATUS_FILE"
            notify-send "Screen Recording" "Saved to Videos" -i media-playback-stop
        fi
        ;;
    status)
        if [ -f "$STATUS_FILE" ]; then
            PID=$(cat "$PID_FILE" 2>/dev/null)
            if [ -n "$PID" ] && kill -0 $PID 2>/dev/null; then
                cat "$STATUS_FILE"
            else
                echo "idle"
                rm -f "$PID_FILE" "$STATUS_FILE"
            fi
        else
            echo "idle"
        fi
        ;;
    *)
        echo "Usage: $0 {start|pause|stop|status}"
        exit 1
        ;;
esac
