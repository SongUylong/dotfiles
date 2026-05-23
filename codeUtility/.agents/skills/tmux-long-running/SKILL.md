---
name: tmux-long-running
description: >
  Use when running long-lived or slow terminal work such as uploads, SSH commands,
  deploys, builds, migrations, dev servers, queues, watchers, backups, downloads,
  or any command that should keep running while the agent continues working.
---

# Tmux Long Running Tasks

Use `tmux` when a command may take time, needs monitoring, or should survive agent pauses.

## When To Use

- Uploading code or files with `scp`, `rsync`, `sftp`, or deploy scripts.
- Running remote commands over `ssh`.
- Starting dev servers, queue workers, watchers, tunnels, or log tails.
- Running long builds, tests, migrations, downloads, backups, or restores.
- Any task where user may ask for progress later.

## Pattern

Use clear session names:

```sh
tmux new-session -d -s task_name -c /path/to/workdir 'command'
```

For many steps:

```sh
tmux new-session -d -s task_name -c /path/to/workdir zsh
tmux send-keys -t task_name 'command here' C-m
```

## Monitor

```sh
tmux list-sessions
tmux capture-pane -t task_name -p
tmux attach -t task_name
```

Detach with `Ctrl-b d`.

## Rules

- Tell user the session name.
- Keep long jobs in tmux instead of blocking main work.
- Check `capture-pane` before saying work is done.
- Do not kill unrelated sessions.
- Stop only when safe:

```sh
tmux send-keys -t task_name C-c
tmux kill-session -t task_name
```
