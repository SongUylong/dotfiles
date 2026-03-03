#!/usr/bin/env bash

# Prompt for search query using rofi with clean minimal styling
query=$(rofi -dmenu -p " " -theme-str '
    window {
        width: 800px;
        height: 120px;
        border: 3px;
        border-color: #89b4fa;
        background-color: #1e1e2e;
        location: center;
        anchor: center;
        x-offset: 0;
        y-offset: 0;
        border-radius: 12px;
    }
    mainbox {
        background-color: #1e1e2e;
        children: [inputbar];
    }
    inputbar {
        children: [prompt, entry];
        background-color: #1e1e2e;
        padding: 20px;
        spacing: 15px;
    }
    prompt {
        background-color: #a6e3a1;
        padding: 16px 20px;
        text-color: #1e1e2e;
        font: "Maple Mono Bold 18";
        enabled: true;
        border-radius: 8px;
    }
    entry {
        padding: 16px 20px;
        text-color: #cdd6f4;
        background-color: #181825;
        font: "Maple Mono 18";
        placeholder: "Search the web...";
        placeholder-color: #6c7086;
        border-radius: 8px;
    }
    listview {
        enabled: false;
    }
')

# If user entered something, search with Zen Browser
if [ -n "$query" ]; then
    firefox --search "$query"
fi
