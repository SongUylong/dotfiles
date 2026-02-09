return {
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
      -- Swap: <leader>E now opens in Root Dir
      {
        "<leader>E",
        function()
          -- LazyVim.root() finds the project root.
          -- If you aren't using LazyVim, remove `dir = ...` to let Neo-tree auto-detect.
          require("neo-tree.command").execute({ toggle = true, dir = LazyVim.root() })
        end,
        desc = "Explorer NeoTree (Root Dir)",
      },
      -- Ensure the specific Git status keys follow suit if you use them
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
}
