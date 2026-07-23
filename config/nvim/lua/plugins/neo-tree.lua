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
      window = {
        mappings = {
          ["j"] = function(state)
            vim.cmd("normal! j")
            local node = state.tree:get_node()
            if node and node.type == "file" then
              require("neo-tree.sources.common.commands").preview(state)
            end
          end,
          ["k"] = function(state)
            vim.cmd("normal! k")
            local node = state.tree:get_node()
            if node and node.type == "file" then
              require("neo-tree.sources.common.commands").preview(state)
            end
          end,
          ["<down>"] = function(state)
            vim.cmd("normal! j")
            local node = state.tree:get_node()
            if node and node.type == "file" then
              require("neo-tree.sources.common.commands").preview(state)
            end
          end,
          ["<up>"] = function(state)
            vim.cmd("normal! k")
            local node = state.tree:get_node()
            if node and node.type == "file" then
              require("neo-tree.sources.common.commands").preview(state)
            end
          end,
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
