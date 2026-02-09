#!/usr/bin/env bash

dir="$HOME/Videos/Recordings"
pidfile="/tmp/wf-recorder.pid"
time=$(date +'%Y_%m_%d_at_%Hh%Mm%Ss')
mp4file="${dir}/Recording_${time}.mp4"
giffile="${dir}/Recording_${time}.gif"

start_recording() {
    if [[ -f "$pidfile" ]]; then
        notify-send -u normal "Screen Recording" "Recording is already in progress"
        exit 1
    fi

    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
    fi

    # Start wf-recorder with area selection and audio (record to MP4 first)
    wf-recorder -g "$(slurp)" -f "$mp4file" &
    echo $! > "$pidfile"
    
    notify-send -u normal "Screen Recording" "Recording started - select area"
}

stop_recording() {
    if [[ ! -f "$pidfile" ]]; then
        notify-send -u critical "Screen Recording" "No recording in progress"
        exit 1
    fi

    pid=$(cat "$pidfile")
    kill -INT "$pid" 2>/dev/null
    rm "$pidfile"
    
    # Wait for wf-recorder to finish writing
    sleep 1
    
    # Convert MP4 to GIF using ffmpeg
    notify-send -u normal "Screen Recording" "Converting to GIF..."
    
    ffmpeg -i "$mp4file" \
        -vf "fps=30,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=bayer" \
        -loop 0 \
        "$giffile" 2>/dev/null
    
    # Copy GIF to clipboard
    if [[ -f "$giffile" ]]; then
        wl-copy < "$giffile"
        notify-send -u normal "Screen Recording" "GIF saved and copied to clipboard!\nLocation: $giffile"
        
        # Remove the temporary MP4 file
        rm "$mp4file"
    else
        notify-send -u critical "Screen Recording" "Failed to create GIF"
    fi
}

if [[ "$1" == "--start" ]]; then
    start_recording
elif [[ "$1" == "--stop" ]]; then
    stop_recording
else
    # Toggle: stop if recording, start if not
    if [[ -f "$pidfile" ]]; then
        stop_recording
    else
        start_recording
    fi
fi

exit 0
