#!/usr/bin/env bash
app="$1"
ICON_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}/app_icons"

# Returns path if PNG exists, else empty string (caller uses nerd font fallback)
p() { local f="$ICON_DIR/$1.png"; [ -f "$f" ] && echo "$f"; }

case "$app" in
  "Brave Browser"|"Brave")             p "Brave"               ;;
  "Google Chrome")                     p "Google_Chrome"       ;;
  "Firefox")                           p "Firefox"             ;;
  "Safari")                            p "Safari"              ;;
  "Arc")                               p "Arc"                 ;;
  "WezTerm")                           p "WezTerm"             ;;
  "iTerm2"|"Terminal")                 p "iTerm"               ;;
  "Alacritty")                         p "Alacritty"           ;;
  "Visual Studio Code")                p "Visual_Studio_Code"  ;;
  "Cursor")                            p "Cursor"              ;;
  "Xcode")                             p "Xcode"               ;;
  "Neovide"|"Neovim")                  p "Neovim"              ;;
  "Codex")                             p "Codex"               ;;
  "Antigravity")                       p "Antigravity"         ;;
  "Gemini")                            p "Gemini"              ;;
  "Ollama")                            p "Ollama"              ;;
  "Discord")                           p "Discord"             ;;
  "Slack")                             p "Slack"               ;;
  "Telegram")                          p "Telegram"            ;;
  "Messages")                          p "Messages"            ;;
  "WhatsApp")                          p "WhatsApp"            ;;
  "WeChat")                            p "WeChat"              ;;
  "VooV Meeting")                      p "VooV_Meeting"        ;;
  "Spotify")                           p "Spotify"             ;;
  "Music")                             p "Music"               ;;
  "GarageBand")                        p "GarageBand"          ;;
  "OBS")                               p "OBS"                 ;;
  "Pika")                              p "Pika"                ;;
  "CapCut")                            p "CapCut"              ;;
  "Notion")                            p "Notion"              ;;
  "Obsidian")                          p "Obsidian"            ;;
  "Raycast")                           p "Raycast"             ;;
  "Microsoft Word")                    p "Microsoft_Word"      ;;
  "Microsoft Excel")                   p "Microsoft_Excel"     ;;
  "Microsoft PowerPoint")              p "Microsoft_PowerPoint";;
  "Microsoft To Do")                   p "Microsoft_To_Do"     ;;
  "Adobe Photoshop 2025"|"Adobe Photoshop") p "Adobe_Photoshop" ;;
  "Docker")                            p "Docker"              ;;
  "Postman")                           p "Postman"             ;;
  "Finder")                            p "Finder"              ;;
  "OneDrive")                          p "OneDrive"            ;;
  "BlueStacks")                        p "BlueStacks"          ;;
  "AeroSpace")                         p "AeroSpace"           ;;
esac
