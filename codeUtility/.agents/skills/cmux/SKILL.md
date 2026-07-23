---
name: cmux
description: Interact with cmux terminal emulator, manage workspaces, tabs, split surfaces, notifications, and embedded browser commands. Use when user mentions cmux, opening workspace in cmux, splitting cmux panes, or sending cmux notifications.
---

# cmux Terminal Skill

`cmux` is a Ghostty-based terminal emulator for AI agents.

## Workspaces

```
cmux workspace create --name "NAME"                                   # new workspace
cmux workspace create --name "NAME" --cwd /path                       # with cwd
cmux workspace create --name "NAME" --layout "$(cat layout.json)"     # with split layout
cmux workspace select --workspace workspace:N                         # switch to
cmux workspace close --workspace workspace:N                          # close
cmux workspace list                                                    # list all
```

Always use `--workspace workspace:N` flag when targeting a specific workspace from outside it. Environment vars CMUX_WORKSPACE_ID / CMUX_SURFACE_ID reflect the caller's workspace, not the target.

## Layout JSON (binary tree only)

Each node is `{"direction":"horizontal|vertical","split":0.5,"children":[...]}`. Exactly 2 children per node. Leaf panes are `{"pane":{"surfaces":[{"type":"terminal","command":"cmd"}]}}`.

5-pane example (3 left + 2 right):
```json
{
  "direction": "horizontal",
  "split": 0.5,
  "children": [
    {
      "direction": "vertical",
      "split": 0.33,
      "children": [
        {"pane": {"surfaces": [{"type": "terminal", "command": "cmd1"}]}},
        {
          "direction": "vertical",
          "split": 0.5,
          "children": [
            {"pane": {"surfaces": [{"type": "terminal", "command": "cmd2"}]}},
            {"pane": {"surfaces": [{"type": "terminal", "command": "cmd3"}]}}
          ]
        }
      ]
    },
    {
      "direction": "vertical",
      "split": 0.5,
      "children": [
        {"pane": {"surfaces": [{"type": "terminal", "command": "cmd4"}]}},
        {"pane": {"surfaces": [{"type": "terminal", "command": "cmd5"}]}}
      ]
    }
  ]
}
```

Always write layout JSON to a temp file and pipe with `$(cat /tmp/file.json)` to avoid shell quoting issues.

## Panes & Surfaces (terminology)

- **Pane** = a split container in the workspace (the frame)
- **Surface** = a terminal tab inside a pane (the actual terminal)

```
cmux list-panes              # list panes in current workspace
cmux list-panes --workspace workspace:N
cmux list-pane-surfaces --pane pane:N    # list surfaces in a pane
cmux list-panels                         # overview: all surfaces + commands
```

## Sending Text to Terminals

```
cmux send --surface surface:N "text"                     # type text (no Enter)
cmux send-key --surface surface:N enter                   # press Enter
cmux send --surface surface:N $'text with newline\r'      # type + enter in one shot
```

Works with opencode TUI, bash, etc. For opencode TUI textbox, text goes to the input field — send Enter to submit.

## Capturing Output

```
cmux capture-pane --surface surface:N --scrollback        # get terminal content
```

## Running Commands in Panes

From layout JSON: `"command": "cmd"` runs on pane creation.

Inline:
- `cmux send` to interact with running TUI apps
- For non-interactive: use `opencode run <msg>` in command (headless, no TUI)
- For interactive TUI: start `opencode` (no args), then `cmux send` prompts

## opencode + cmux

```
opencode run <msg>           # headless batch mode — runs then exits, no TUI
opencode                     # full interactive TUI (starts in cmux pane)
cmux send ...                # type into opencode TUI textbox
cmux send-key ... enter      # submit prompt in opencode
cmux omo [args]              # launch opencode with tmux shim for multi-agent
```

`opencode run` is good for automation. `opencode` (bare) is best when user wants to see the interface.

## Notifications

```
cmux notify --title "Title" --body "Message"
cmux set-status "key" "value" --icon "bolt" --color "#a6e3a1"
cmux set-progress 0.5 --label "doing thing..."
```

## Browser & Markdown

```
cmux browser open http://localhost:3000
cmux markdown open /path/to/doc.md
```

## Tips

- Prefer layout JSON for multi-pane workspaces instead of sequential splits
- Only 2 children per node in layout (binary tree)
- `--workspace workspace:N` flag needed when targeting diff workspace than caller
- Workspace IDs are short refs like `workspace:1`, `workspace:2` etc
- To interact with a running TUI app, use send + send-key enter
- capture-pane with --scrollback to read pane contents
