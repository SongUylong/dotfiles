return {
  {
    "rmagatti/auto-session",
    lazy = false,
    opts = {
      auto_restore_enabled = true,
      auto_session_suppress_dirs = { "~/", "~/Downloads", "/" },
      session_lens = {
        -- If load_on_setup is set to false, one needs to eventually call `require("auto-session").setup_session_lens()` if they want to use session-lens.
        load_on_setup = true,
        previewer = false,
        mappings = {
          -- Default mappings for session lens selection
          delete_session = { "i", "<C-D>" },
          alternate_session = { "i", "<C-S>" },
        },
      },
    },
    config = function(_, opts)
      require("auto-session").setup(opts)
    end,
    keys = {
      -- Keybinding to search through sessions (Prefix + S inside Neovim)
      { "<leader>qs", "<cmd>SessionSearch<CR>", desc = "Search sessions" },
      { "<leader>ql", "<cmd>SessionRestore<CR>", desc = "Restore session" },
      { "<leader>qd", "<cmd>SessionDelete<CR>", desc = "Delete session" },
    },
  },
}
