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
}
