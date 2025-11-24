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
}
