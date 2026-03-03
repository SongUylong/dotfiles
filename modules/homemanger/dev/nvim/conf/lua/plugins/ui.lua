-- UI Enhancements
return {
  -- Better picker with snacks
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        ignored = true,
        hidden = true,
      },
    },
  },

  -- File explorer
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
            "package-lock.json",
            ".changeset",
            ".prettierrc.json",
          },
        },
      },
    },
    keys = {
      {
        "<leader>e",
        function()
          require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() })
        end,
        desc = "Explorer NeoTree (cwd)",
      },
      {
        "<leader>E",
        function()
          require("neo-tree.command").execute({ toggle = true, dir = LazyVim.root() })
        end,
        desc = "Explorer NeoTree (Root Dir)",
      },
      {
        "<leader>ge",
        function()
          require("neo-tree.command").execute({ source = "git_status", toggle = true, dir = vim.uv.cwd() })
        end,
        desc = "Git Explorer (cwd)",
      },
      {
        "<leader>gE",
        function()
          require("neo-tree.command").execute({ source = "git_status", toggle = true, dir = LazyVim.root() })
        end,
        desc = "Git Explorer (Root Dir)",
      },
    },
  },

  -- Image support
  {
    "vhyrro/luarocks.nvim",
    priority = 1001,
    opts = {
      rocks = { "magick" },
    },
  },
  {
    "3rd/image.nvim",
    dependencies = { "luarocks.nvim" },
    opts = {},
  },
}
