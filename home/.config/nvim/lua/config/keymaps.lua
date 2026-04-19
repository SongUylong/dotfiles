vim.keymap.del("n", "<c-/>")
vim.keymap.del("t", "<c-/>")

vim.keymap.set("n", "<c-`>", function()
  Snacks.terminal(nil, { cwd = LazyVim.root() })
end, { desc = "Terminal (Root Dir)" })
vim.keymap.set("t", "<C-`>", "<cmd>close<cr>", { desc = "Hide Terminal" })
vim.keymap.set("n", "<leader>tf", function()
  require("telescope").extensions.flutter.commands()
end, { desc = "Telescope Flutter Commands" })

-- Cursor: `workbench.action.navigateLeft` (used by vscode-neovim for <C-w>h) still
-- expects workbench.parts.activitybar; Cursor exposes unifiedsidebar instead.
if vim.g.vscode then
  vim.keymap.set("n", "<C-h>", function()
    require("vscode").call("workbench.files.action.focusFilesExplorer")
  end, { desc = "Focus File Explorer" })
end
