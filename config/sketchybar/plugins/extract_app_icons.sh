#!/usr/bin/env bash
export PATH="/opt/homebrew/bin:$PATH"

ICON_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}/app_icons"
mkdir -p "$ICON_DIR"

extract() {
  local app_name="$1" out_name="$2" app_path="${3:-/Applications/${app_name}.app}"
  local out="$ICON_DIR/${out_name}.png"
  [ -f "$out" ] && return 0
  [ ! -d "$app_path" ] && return 1
  local icon_file
  icon_file="$(defaults read "$app_path/Contents/Info.plist" CFBundleIconFile 2>/dev/null)"
  [ -z "$icon_file" ] && return 1
  [[ "$icon_file" != *.icns ]] && icon_file="${icon_file}.icns"
  local src="$app_path/Contents/Resources/$icon_file"
  [ ! -f "$src" ] && return 1
  # Convert icns → 28x28 padded PNG (16px icon centered on transparent canvas)
  python3 - "$src" "$out" << 'PYEOF'
import sys
from PIL import Image
src, out = sys.argv[1], sys.argv[2]
img = Image.open(src).convert("RGBA").resize((16, 16), Image.LANCZOS)
canvas = Image.new("RGBA", (28, 28), (0, 0, 0, 0))
canvas.paste(img, (6, 6), img)
canvas.save(out)
PYEOF
}

# Browsers
extract "Brave" "Brave"
extract "Google Chrome" "Google_Chrome"
extract "Firefox" "Firefox"
extract "Safari" "Safari"
extract "Arc" "Arc"

# Terminals
extract "WezTerm" "WezTerm"
extract "Alacritty" "Alacritty"

# Editors / IDEs
extract "Visual Studio Code" "Visual_Studio_Code"
extract "Cursor" "Cursor"
extract "Xcode" "Xcode"
extract "Codex" "Codex"

# AI
extract "Antigravity" "Antigravity"
extract "Gemini" "Gemini"
extract "Ollama" "Ollama"

# Communication
extract "Telegram" "Telegram"
extract "WhatsApp" "WhatsApp"
extract "WeChat" "WeChat"
extract "Discord" "Discord"
extract "Slack" "Slack"
extract "VooV Meeting" "VooV_Meeting"

# Media
extract "Spotify" "Spotify"
extract "GarageBand" "GarageBand"
extract "OBS" "OBS"
extract "Pika" "Pika"
extract "CapCut" "CapCut"

# Productivity
extract "Notion" "Notion"
extract "Obsidian" "Obsidian"
extract "Raycast" "Raycast"
extract "Microsoft Word" "Microsoft_Word"
extract "Microsoft Excel" "Microsoft_Excel"
extract "Microsoft PowerPoint" "Microsoft_PowerPoint"
extract "Microsoft To Do" "Microsoft_To_Do"

# Dev Tools
extract "Docker" "Docker"
extract "Postman" "Postman"

# System
extract "OneDrive" "OneDrive"
extract "BlueStacks" "BlueStacks"
extract "AeroSpace" "AeroSpace"

# Special cases
python3 - "/System/Library/CoreServices/Finder.app/Contents/Resources/Finder.icns" "$ICON_DIR/Finder.png" << 'PYEOF'
import sys
from PIL import Image
src, out = sys.argv[1], sys.argv[2]
img = Image.open(src).convert("RGBA").resize((16, 16), Image.LANCZOS)
canvas = Image.new("RGBA", (28, 28), (0, 0, 0, 0))
canvas.paste(img, (6, 6), img)
canvas.save(out)
PYEOF
