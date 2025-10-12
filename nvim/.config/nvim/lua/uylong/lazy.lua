-- ========================================
-- 💤 Bootstrap lazy.nvim (Plugin Manager)
-- ========================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    lazyrepo,
    lazypath,
  })

  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

vim.opt.rtp:prepend(lazypath)

-- ========================================
-- ⚙️ Basic Settings
-- ========================================
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- ========================================
-- 🚀 Setup lazy.nvim
-- ========================================
require("lazy").setup({
  spec = {
    -- import all plugins from lua/uylong/plugins
    { import = "uylong.plugins" },
  },
  install = {
    colorscheme = { "habamax" }, -- default colorscheme while installing
  },
  checker = {
    enabled = true,  -- auto-check for plugin updates
    notify = false,  -- disable annoying notifications
  },
  change_detection = {
    enabled = true,
    notify = false,
  },
})

-- ========================================
-- 🧭 Diagnostic UI (VSCode-like)
-- ========================================
vim.diagnostic.config({
  virtual_text = {
    prefix = "●", -- VSCode-style dot
    spacing = 4,
  },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- ✅ Diagnostic Sign Icons
local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

