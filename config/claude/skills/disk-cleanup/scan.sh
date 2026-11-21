#!/bin/bash
# disk-cleanup scan: read-only. Prints a report of what is using space and what can be
# cleaned. Deletes nothing.
set -uo pipefail
H="$HOME"
sz() { du -sk "$@" 2>/dev/null | awk '{s+=$1} END {printf "%.1fG", s/1048576}'; }
row() { # label  size  path  safety
  printf '%-34s %8s  %-55s %s\n' "$1" "$2" "$3" "$4"; }
have() { command -v "$1" >/dev/null 2>&1; }

echo "== DISK =="
df -h /System/Volumes/Data | awk 'NR==2 {print "Used " $3 " of " $2 " (" $5 "), free " $4}'
echo

echo "== MOLE: caches, logs, leftovers (mo clean --dry-run) =="
mo clean --dry-run </dev/null 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "⊙|Potential space|Detailed file list" | head -60
echo
echo "== MOLE: project build artifacts (mo purge --dry-run) =="
mo purge --dry-run </dev/null 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -vE "^\s*$" | tail -15
echo
echo "== MOLE: installers (mo installer --dry-run) =="
mo installer --dry-run </dev/null 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -vE "^\s*$" | tail -15
echo

echo "== DEV CACHES & TOOLS =="
printf '%-34s %8s  %-55s %s\n' "ITEM" "SIZE" "PATH" "SAFETY"
for p in \
  "Xcode DerivedData|$H/Library/Developer/Xcode/DerivedData|safe (rebuilt on next build)" \
  "Xcode Archives|$H/Library/Developer/Xcode/Archives|ask (old app builds)" \
  "Xcode iOS DeviceSupport|$H/Library/Developer/Xcode/iOS DeviceSupport|safe (re-downloads)" \
  "iOS Simulators|$H/Library/Developer/CoreSimulator/Devices|use: xcrun simctl delete unavailable" \
  "Simulator caches|$H/Library/Developer/CoreSimulator/Caches|safe" \
  "npm cache|$H/.npm/_cacache|safe" \
  "pnpm store|$H/Library/pnpm/store|safe: pnpm store prune" \
  "yarn cache|$H/Library/Caches/Yarn|safe" \
  "bun cache|$H/.bun/install/cache|safe" \
  "Gradle caches|$H/.gradle/caches|safe (re-downloads)" \
  "Maven repo|$H/.m2/repository|safe (re-downloads)" \
  "CocoaPods cache|$H/Library/Caches/CocoaPods|safe" \
  "pip cache|$H/Library/Caches/pip|safe" \
  "uv cache|$H/.cache/uv|safe: uv cache clean" \
  "Go build cache|$H/Library/Caches/go-build|safe: go clean -cache" \
  "Cargo registry|$H/.cargo/registry|safe (re-downloads)" \
  "Homebrew downloads|$H/Library/Caches/Homebrew|safe: brew cleanup --prune=all" \
  "Hugging Face models|$H/.cache/huggingface|ask (models re-download, large)" \
  "Ollama models|$H/.ollama/models|ask (delete with ollama rm)" \
  "Android SDK|$H/Library/Android/sdk|ask" \
  "Android emulators|$H/.android/avd|ask" \
  "Playwright browsers|$H/Library/Caches/ms-playwright|safe (reinstall if needed)" \
  "Electron/other caches|$H/Library/Caches|mostly safe (mo clean covers it)" \
  "Trash|$H/.Trash|ask: empty Trash" \
  "iOS/iPhone backups|$H/Library/Application Support/MobileSync/Backup|ask (personal data)" \
  ; do
  IFS='|' read -r label path safety <<<"$p"
  [ -e "$path" ] || continue
  s=$(sz "$path"); [ "$s" = "0.0G" ] && continue
  row "$label" "$s" "${path/#$H/~}" "$safety"
done
if have docker && docker info >/dev/null 2>&1; then
  echo; echo "-- Docker (docker system df) --"; docker system df 2>/dev/null
fi
have brew && { echo; echo "-- Homebrew: brew cleanup -n would free --"; brew cleanup -n --prune=all 2>/dev/null | tail -1; }
echo

echo "== node_modules folders (biggest 15) =="
find "$H" -maxdepth 6 -type d -name node_modules -prune \
  -not -path "*/Library/*" -not -path "*/.Trash/*" -not -path "*/.npm/*" 2>/dev/null \
  | while read -r d; do du -sk "$d" 2>/dev/null; done | sort -rn | head -15 \
  | awk -v h="$H" '{s=$1; $1=""; sub(/^ /,""); p=$0; sub(h,"~",p); printf "%7.2fG  %s\n", s/1048576, p}'
echo

echo "== BIG FILES > 500 MB (outside Library) =="
find "$H" -xdev -type f -size +500M -not -path "*/Library/*" -not -path "*/.Trash/*" 2>/dev/null \
  | while read -r f; do du -sk "$f" 2>/dev/null; done | sort -rn | head -25 \
  | awk -v h="$H" '$1 > 102400 {s=$1; $1=""; sub(/^ /,""); p=$0; sub(h,"~",p); printf "%7.2fG  %s\n", s/1048576, p}'
echo "(sizes are real disk use; sparse cache files can look bigger in Finder)"
echo

echo "== PROJECT BUILD FOLDERS > 200 MB (build, dist, .next, target, DerivedData, Pods, .gradle) =="
find "$H/code" "$H/dev" "$H/www" "$H/Projects" -maxdepth 6 -type d \( -name build -o -name dist -o -name .next -o -name target -o -name DerivedData -o -name Pods -o -name .gradle -o -name .turbo -o -name .expo \) -prune \
  -not -path "*/node_modules/*" 2>/dev/null \
  | while read -r d; do du -sk "$d" 2>/dev/null; done | awk '$1 > 204800' | sort -rn | head -20 \
  | awk -v h="$H" '{s=$1; $1=""; sub(/^ /,""); p=$0; sub(h,"~",p); printf "%7.2fG  %s\n", s/1048576, p}'
echo "(safe: rebuilt by the next build)"
echo

echo "== OLD DOWNLOADS (not opened in 60+ days, biggest 20) =="
find "$H/Downloads" -maxdepth 2 -mindepth 1 -atime +60 2>/dev/null \
  | while read -r f; do du -sk "$f" 2>/dev/null; done | sort -rn | head -20 \
  | awk -v h="$H" '{s=$1; $1=""; sub(/^ /,""); p=$0; sub(h,"~",p); printf "%7.2fG  %s\n", s/1048576, p}'
echo

echo "== HOME: biggest top-level folders =="
du -sk "$H"/* "$H"/.[!.]* 2>/dev/null | sort -rn | head -15 \
  | awk -v h="$H" '{s=$1; $1=""; sub(/^ /,""); p=$0; sub(h,"~",p); printf "%7.2fG  %s\n", s/1048576, p}'
echo
echo "== ~/Library: biggest folders =="
du -sk "$H/Library"/* 2>/dev/null | sort -rn | head -10 \
  | awk -v h="$H" '{s=$1; $1=""; sub(/^ /,""); p=$0; sub(h,"~",p); printf "%7.2fG  %s\n", s/1048576, p}'
du -sk "$H/Library/Application Support"/* "$H/Library/Containers"/* 2>/dev/null | sort -rn | head -12 \
  | awk -v h="$H" '{s=$1; $1=""; sub(/^ /,""); p=$0; sub(h,"~",p); printf "%7.2fG  %s\n", s/1048576, p}'
echo
echo "Scan done. Nothing was deleted."
