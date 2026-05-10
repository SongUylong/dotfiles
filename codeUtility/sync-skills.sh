#!/usr/bin/env bash
# sync-skills.sh — Symlink all shared skills to every AI editor's skills directory.
#
# Source:  ~/dotfiles/codeUtility/.agents/skills/*
# Targets: Antigravity (Gemini), Codex (OpenAI), Cursor
#
# Usage:  ./sync-skills.sh          # symlink all skills
#         ./sync-skills.sh --dry    # preview what would be done
#         ./sync-skills.sh --clean  # remove symlinks pointing to our source

set -euo pipefail

SKILLS_SRC="$HOME/dotfiles/codeUtility/.agents/skills"

# Editor skills directories
TARGETS=(
  "$HOME/.gemini/antigravity/skills"
  "$HOME/.codex/skills"
  "$HOME/.cursor/skills-cursor"
)

TARGET_LABELS=(
  "Antigravity (Gemini)"
  "Codex (OpenAI)"
  "Cursor"
)

DRY=false
CLEAN=false

for arg in "$@"; do
  case "$arg" in
    --dry)   DRY=true ;;
    --clean) CLEAN=true ;;
    -h|--help)
      echo "Usage: $0 [--dry] [--clean]"
      echo "  --dry    Preview changes without making them"
      echo "  --clean  Remove symlinks that point to the shared skills source"
      exit 0
      ;;
  esac
done

if [ ! -d "$SKILLS_SRC" ]; then
  echo "❌ Skills source not found: $SKILLS_SRC"
  exit 1
fi

added=0
skipped=0
cleaned=0
errors=0

for i in "${!TARGETS[@]}"; do
  target_dir="${TARGETS[$i]}"
  label="${TARGET_LABELS[$i]}"

  echo ""
  echo "━━━ $label ━━━"
  echo "    → $target_dir"

  # Create target dir if needed
  if [ ! -d "$target_dir" ]; then
    if $DRY; then
      echo "    📁 Would create: $target_dir"
    else
      mkdir -p "$target_dir"
      echo "    📁 Created: $target_dir"
    fi
  fi

  if $CLEAN; then
    # Remove symlinks that point into our skills source
    for link in "$target_dir"/*/; do
      link="${link%/}"
      [ -L "$link" ] || continue
      link_target=$(readlink "$link" 2>/dev/null || true)
      # Check if symlink points to our source (absolute path)
      if [[ "$link_target" == "$SKILLS_SRC"* ]]; then
        name=$(basename "$link")
        if $DRY; then
          echo "    🗑  Would remove: $name"
        else
          rm "$link"
          echo "    🗑  Removed: $name"
        fi
        ((cleaned++))
      fi
    done
    continue
  fi

  # Symlink each skill
  for skill_dir in "$SKILLS_SRC"/*/; do
    skill_name=$(basename "$skill_dir")
    dest="$target_dir/$skill_name"

    if [ -L "$dest" ]; then
      existing_target=$(readlink "$dest" 2>/dev/null || true)
      if [ "$existing_target" = "$SKILLS_SRC/$skill_name" ]; then
        ((skipped++))
        continue
      fi
      # Broken or different symlink — replace it
      if $DRY; then
        echo "    🔄 Would replace: $skill_name (was → $existing_target)"
      else
        rm "$dest"
        ln -s "$SKILLS_SRC/$skill_name" "$dest"
        echo "    🔄 Replaced: $skill_name"
      fi
      ((added++))
    elif [ -e "$dest" ]; then
      # Real file/dir exists — skip to avoid data loss
      echo "    ⚠️  Skipped (not a symlink): $skill_name"
      ((skipped++))
    else
      if $DRY; then
        echo "    ✅ Would link: $skill_name"
      else
        ln -s "$SKILLS_SRC/$skill_name" "$dest"
        echo "    ✅ Linked: $skill_name"
      fi
      ((added++))
    fi
  done
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━"
if $CLEAN; then
  echo "🧹 Cleaned: $cleaned symlinks"
elif $DRY; then
  echo "🔍 Dry run: $added would be added/replaced, $skipped already correct"
else
  echo "✅ Done: $added added/replaced, $skipped already correct, $errors errors"
fi
