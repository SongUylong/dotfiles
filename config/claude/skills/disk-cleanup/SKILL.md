---
name: disk-cleanup
description: Scan Eric's whole Mac for reclaimable disk space (Mole clean/purge/installer dry runs, dev caches, Docker, node_modules, big files, old Downloads), show one ranked report, ask what to clean, then clean only the chosen items and report space freed. Use when Eric says his disk is full, asks to free space, clean up, run mole, or invokes /disk-cleanup.
---

# Disk cleanup

One pass: **scan → report → ask → clean → verify**. Nothing is deleted before Eric picks it.

## 1. Scan (read-only)

Run the scanner in the background (it can take 1–3 minutes) and wait for it:

```bash
~/.claude/skills/disk-cleanup/scan.sh > "$SCRATCH/disk-scan.txt" 2>&1
```

(`$SCRATCH` = your scratchpad dir.) It prints: disk usage, `mo clean --dry-run`, `mo purge --dry-run`, `mo installer --dry-run`, dev caches with sizes and safety notes, `docker system df`, `brew cleanup -n`, the biggest `node_modules`, files over 500 MB, Downloads not opened in 60+ days, and the biggest folders in `~` and `~/Library`. If something big in `~/Library/Application Support` or `Containers` is unexplained, look one level deeper with `du -sh` before reporting.

## 2. Report

Show **one table**, biggest first, grouped:

| # | What | Size | Safety |
|---|------|------|--------|

- **Safe**: caches and build output that rebuild themselves (Mole clean, DerivedData, npm/pnpm/yarn/bun/pip/uv/go/Gradle caches, Homebrew cache, Docker build cache and dangling images, `mo purge` artifacts, installers already installed).
- **Check**: things that cost time or data to get back (Docker volumes/images in use, simulators, Ollama/Hugging Face models, Xcode archives, old Downloads, big files, node_modules of active projects).
- **Never touch**: personal documents, photos, iCloud, Mail, Messages, app data in `Application Support` unless it's a known cache, iPhone backups (only mention them).

Start with the headline: current free space and the total that "Safe" would free.

## 3. Ask

Use `AskUserQuestion` (multiSelect) — first option "All safe items (Recommended)", then the biggest individual "Check" items. Up to 4 questions if needed. For big files and old Downloads, list them by name so Eric picks exactly which.

## 4. Clean only what was picked

Prefer the tool's own command over `rm`:

| Item | Command |
|---|---|
| Mole caches/logs | `mo clean </dev/null` (user-level; for the admin-level part tell Eric to run `mo clean` himself — it asks for his password) |
| Project artifacts | `mo purge --yes` |
| Installers | `mo installer` needs a TTY — run it in Eric's terminal with `run_in_terminal`, or move the chosen files to Trash |
| pnpm | `pnpm store prune` |
| npm | `npm cache clean --force` |
| yarn / bun / uv / go | `yarn cache clean` / `bun pm cache rm` / `uv cache clean` / `go clean -cache` |
| Homebrew | `brew cleanup --prune=all` and `brew autoremove` |
| Docker | `docker builder prune -f`, `docker image prune -f` (dangling); `docker system prune -a` only if Eric chose it; never `--volumes` unless he picked volumes by name |
| Simulators | `xcrun simctl delete unavailable` |
| DerivedData etc. | `rm -rf` the exact folder listed in the report |
| Files, Downloads, node_modules | move to Trash with `/usr/bin/trash <path>` (recoverable), not `rm` |
| Trash | empty only if Eric picked "Empty Trash" explicitly (permanent — say so) |

Rules: only paths that appeared in the scan and that Eric picked; quote paths; never use `sudo`; never touch `/System`, `/Library` (root), or anything outside the picked list. If a command fails, report it and continue with the rest.

## 5. Verify and report

Run `df -h /System/Volumes/Data` again. Report: free space before → after, what was cleaned with sizes, anything skipped or failed, and what Eric can still do himself (e.g. `mo clean` with admin password, emptying Trash).

Then follow the global end-of-task steps (vault-notify subagent: log the cleanup in the vault area for this Mac and send the Telegram notification).
