return {
  "christoomey/vim-tmux-navigator",
  lazy = false,
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
    "TmuxNavigatePrevious",
  },
  keys = {
    { "<C-h>", "<cmd><C-U>TmuxNavigateLeft<cr>", desc = "Window left" },
    { "<C-j>", "<cmd><C-U>TmuxNavigateDown<cr>", desc = "Window down" },
    { "<C-k>", "<cmd><C-U>TmuxNavigateUp<cr>", desc = "Window up" },
    { "<C-l>", "<cmd><C-U>TmuxNavigateRight<cr>", desc = "Window right" },
    { "<C-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>", desc = "Previous window" },
  },
}
