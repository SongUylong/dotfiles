Here is your daily driving manual based exactly on the config you just pasted.

Because you cleared the defaults, your Zellij now works perfectly on a **"Two-Step" system**.
Step 1: Press `Ctrl + [Letter]` to enter a mode and let go.
Step 2: Press a single letter to perform the action and instantly go back to typing.

### 🛑 The Escape Hatch & Quitting

- **Cancel / Go Back:** Press **`Esc`** at any time to return to normal typing mode.
- **Quit Zellij entirely:** Press **`Ctrl q`**.

---

### 🪟 Panes (Splitting the screen)

**Prefix: `Ctrl p**`(Press`Ctrl p`, let go, then press...)

- **`r`** = Split screen to the **Right**
- **`d`** = Split screen **Down**
- **`x`** = Close the current pane
- **`f`** = Zoom pane to Fullscreen (press `Ctrl p` then `f` again to unzoom)
- **`w`** = Float the current pane in a popup window
- **`c`** = Rename the current pane

### 🚀 Moving Between Panes (No prefix needed!)

Because of the `shared` block at the bottom of your config, you don't need a mode for this:

- Hold **`Alt`** and press **`Arrow Keys`** (Up, Down, Left, Right) to jump between panes.
  _(Note: If you applied the WezTerm fix we discussed earlier, you can also just use your Mac's `Cmd + h/j/k/l` to do this)._

---

### 📑 Tabs (Multiple workspaces)

**Prefix: `Ctrl t**`(Press`Ctrl t`, let go, then press...)

- **`n`** = Create a **New** tab
- **`x`** = Close the current tab
- **`r`** = Rename the tab
- **`l`** = Go to the next tab (Right)
- **`h`** = Go to the previous tab (Left)
- **`b`** = **Break** the current pane off into its own brand new tab

---

### 📜 Scrolling & History

**Prefix: `Ctrl s**`(Press`Ctrl s`, let go, then press...)

- **`k`** or **`Up Arrow`** = Scroll up line by line
- **`j`** or **`Down Arrow`** = Scroll down line by line
- **`h`** or **`l`** = Page Up / Page Down
- **`s`** = Search the terminal output for specific text
- **`e`** = Open your entire terminal scrollback history in your default text editor (like Vim/Nano)
- **Press `Esc**` when you are done reading to go back to typing.

---

### 📏 Resizing Panes

**Prefix: `Ctrl r**`(Press`Ctrl r`, let go, then press...)

- **`h / j / k / l`** = Push the borders Left, Down, Up, or Right
- **`+ / -`** = Zoom the pane larger or smaller
- **Press `Esc**` when you are happy with the size to go back to typing.

---

### 🔒 Locked Mode (The "Get out of my way" mode)

**Prefix: `Ctrl g**`

- If you run a program inside Zellij that uses lots of shortcuts (like Neovim, Emacs, or Htop), press **`Ctrl g`**.
- Zellij will now completely ignore all your shortcuts, passing everything to the program inside.
- Press **`Ctrl g`** again to unlock it and get your Zellij shortcuts back.

That's your whole system! Print this out or keep it on a second monitor for a day, and it will be completely to muscle memory.
