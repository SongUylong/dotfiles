#!/usr/bin/env bash

dir="$HOME/Videos/Recordings"
pidfile="/tmp/wf-recorder.pid"
filenamefile="/tmp/wf-recorder-filename.txt"
logfile="/tmp/wf-recorder.log"

# Check if required tools are installed
if ! command -v wf-recorder &> /dev/null; then
    notify-send -u critical "Screen Recording" "wf-recorder is not installed"
    exit 1
fi

if ! command -v slurp &> /dev/null; then
    notify-send -u critical "Screen Recording" "slurp is not installed"
    exit 1
fi

start_recording() {
    if [[ -f "$pidfile" ]]; then
        # Check if the process is actually running
        if kill -0 "$(cat "$pidfile")" 2>/dev/null; then
            notify-send -u normal "Screen Recording" "Recording is already in progress"
            exit 1
        else
            # Clean up stale pid file
            rm -f "$pidfile" "$filenamefile"
        fi
    fi

    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
    fi

    # Get geometry from slurp
    if ! geometry=$(slurp); then
        notify-send -u normal "Screen Recording" "Selection cancelled"
        exit 0
    fi
    
    # Check if geometry is empty
    if [[ -z "$geometry" ]]; then
        notify-send -u normal "Screen Recording" "Selection cancelled"
        exit 0
    fi

    # Generate filename with timestamp
    time=$(date +'%Y_%m_%d_at_%Hh%Mm%Ss')
    mp4file="${dir}/Recording_${time}.mp4"
    
    # Save filename for later use when stopping
    echo "$mp4file" > "$filenamefile"
    
    # Start wf-recorder with the selected geometry and log output
    wf-recorder -g "$geometry" -f "$mp4file" --audio > "$logfile" 2>&1 &
    recorder_pid=$!
    echo $recorder_pid > "$pidfile"
    
    # Give wf-recorder a moment to start and check if it's still running
    sleep 0.5
    if ! kill -0 "$recorder_pid" 2>/dev/null; then
        notify-send -u critical "Screen Recording" "Failed to start wf-recorder. Check $logfile"
        rm -f "$pidfile" "$filenamefile"
        exit 1
    fi
    
    notify-send -u normal "Screen Recording" "Recording started"
}

stop_recording() {
    if [[ ! -f "$pidfile" ]]; then
        notify-send -u critical "Screen Recording" "No recording in progress"
        exit 1
    fi

    # Retrieve the filename from the stored file
    if [[ ! -f "$filenamefile" ]]; then
        notify-send -u critical "Screen Recording" "Recording filename not found"
        rm -f "$pidfile"
        exit 1
    fi
    
    mp4file=$(cat "$filenamefile")
    giffile="${mp4file%.mp4}.gif"

    pid=$(cat "$pidfile")
    
    # Check if process is actually running
    if ! kill -0 "$pid" 2>/dev/null; then
        rm -f "$pidfile" "$filenamefile"
        
        # Check if the file was created anyway
        if [[ -f "$mp4file" ]]; then
            notify-send -u normal "Screen Recording" "Process stopped but file exists, processing..."
        else
            notify-send -u critical "Screen Recording" "Recording process not found. Check $logfile for errors"
            exit 1
        fi
    else
        # Send SIGINT to stop recording gracefully
        kill -INT "$pid" 2>/dev/null
        rm "$pidfile"
        
        # Wait for wf-recorder to finish writing (max 5 seconds)
        for _ in {1..50}; do
            if ! kill -0 "$pid" 2>/dev/null; then
                break
            fi
            sleep 0.1
        done
    fi
    
    # Check if MP4 file was created
    if [[ ! -f "$mp4file" ]]; then
        rm -f "$filenamefile"
        notify-send -u critical "Screen Recording" "Failed to create recording. Check $logfile"
        exit 1
    fi
    
    # Convert MP4 to GIF using ffmpeg
    notify-send -u normal "Screen Recording" "Converting to GIF..."
    
    if ! command -v ffmpeg &> /dev/null; then
        notify-send -u critical "Screen Recording" "ffmpeg is not installed, saving as MP4 only"
        notify-send -u normal "Screen Recording" "MP4 saved (no clipboard copy for video)\nLocation: $mp4file"
        rm -f "$filenamefile"
        exit 0
    fi
    
    if ffmpeg -i "$mp4file" \
        -vf "fps=30,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=bayer" \
        -loop 0 \
        "$giffile" 2>/dev/null; then
        
        # Copy GIF to clipboard as image data
        wl-copy --type image/gif < "$giffile"
        notify-send -u normal "Screen Recording" "GIF saved and copied to clipboard!\nLocation: $giffile"
        
        # Remove the temporary MP4 file
        rm "$mp4file"
    else
        # If GIF conversion fails, keep the MP4
        notify-send -u warning "Screen Recording" "GIF conversion failed, MP4 saved (no clipboard copy for video)\nLocation: $mp4file"
    fi
    
    # Clean up filename file
    rm -f "$filenamefile"
}

case "$1" in
    "--start")
        start_recording
        ;;
    "--stop")
        stop_recording
        ;;
    *)
        # Toggle: stop if recording, start if not
        if [[ -f "$pidfile" ]]; then
            stop_recording
        else
            start_recording
        fi
        ;;
esac

exit 0
