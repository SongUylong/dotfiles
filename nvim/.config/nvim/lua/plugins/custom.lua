return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        ignored = true,
        hidden = true,
      },
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<leader>fh",
        "<cmd>Telescope find_files hidden=true no_ignore=true<cr>",
        desc = "Find Hiden Files",
      },
    },
  },
  {
    "vhyrro/luarocks.nvim",
    priority = 1001, -- this plugin needs to run before anything else
    opts = {
      rocks = { "magick" },
    },
  },
  {
    "3rd/image.nvim",
    dependencies = { "luarocks.nvim" },
    opts = {},
  },

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
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        filtered_items = {
          visible = true,
          show_hidden_count = true,
          hide_dotfiles = false,
          hide_gitignored = true,
          hide_by_name = {},
          never_show = {
            "vendor",
            ".git",
            ".DS_Store",
            "thumbs.db",
            ".github",
            ".gitignore",
            "package-lock.json",
            ".changeset",
            ".prettierrc.json",
          },
        },
      },
    },
  },
  {
    "mg979/vim-visual-multi",
  },
  -- { "sphamba/smear-cursor.nvim", opts = {
  --   cursor_color = "",
  -- } },
}
