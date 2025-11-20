return {
  "nvim-flutter/flutter-tools.nvim",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "stevearc/dressing.nvim", -- optional for vim.ui.select
  },
  config = function()
    require("flutter-tools").setup({
      -- Your flutter-tools configuration options here
    })
    -- Load the Telescope flutter extension
    require("telescope").load_extension("flutter")
  end,
  config = true,
}
