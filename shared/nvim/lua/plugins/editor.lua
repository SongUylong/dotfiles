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
    "user.buffer.keys",
    virtual = true,
    event = "VeryLazy",
    config = function()
      local map = vim.keymap.set

      for i = 1, 9 do
        map("n", "<C-" .. i .. ">", "<cmd>BufferLineGoToBuffer " .. i .. "<cr>", { desc = "Go to Buffer " .. i })
      end

      -- Close current Buffer using Ctrl + x
      -- Uses Snacks to keep the window layout intact
      map("n", "<C-x>", function()
        Snacks.bufdelete()
      end, { desc = "Close Current Buffer" })
    end,
  },
}
