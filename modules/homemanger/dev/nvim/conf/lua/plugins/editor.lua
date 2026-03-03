-- Editor Enhancements
return {
  -- Move lines/blocks with Ctrl+h/j/k/l
  {
    "nvim-mini/mini.move",
    version = "*",
    opts = {
      mappings = {
        -- Visual mode movement
        left = "<C-h>",
        right = "<C-l>",
        down = "<C-j>",
        up = "<C-k>",

        -- Normal mode line movement
        line_left = "<C-h>",
        line_right = "<C-l>",
        line_down = "<C-j>",
        line_up = "<C-k>",
      },
      options = {
        reindent_linewise = true,
      },
    },
  },

  -- Multiple cursors support
  {
    "mg979/vim-visual-multi",
  },

  -- Code screenshot utility
  {
    "mistricky/codesnap.nvim",
    build = "make",
    keys = {
      { "<leader>cy", "<cmd>CodeSnap<cr>", mode = "x", desc = "Save selected code snapshot into clipboard" },
      { "<leader>cs", "<cmd>CodeSnapSave<cr>", mode = "x", desc = "Save selected code snapshot" },
    },
    opts = {
      save_path = "~/Pictures/Screenshots",
      show_line_number = false,
      snapshot_config = {
        theme = "candy",
        window = {
          mac_window_bar = false,
          shadow = {
            radius = 0,
            color = "#00000000",
          },
          margin = {
            x = 0,
            y = 0,
          },
          border = {
            width = 0,
            color = "#00000000",
          },
          radius = 0,
        },
        code_config = {
          font_family = "CaskaydiaCove Nerd Font",
          breadcrumbs = {
            enable = false,
          },
        },
        watermark = {
          content = "",
        },
        background = "#00000000",
      },
    },
  },
}
