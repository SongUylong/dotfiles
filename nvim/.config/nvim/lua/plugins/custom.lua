-- Miscellaneous plugins and experimental features
return {
  {
    "vhyrro/luarocks.nvim",
    priority = 1001, -- this plugin needs to run before anything else
    opts = {
      rocks = { "magick" },
    },
  },
  -- {
  --   "3rd/image.nvim",
  --   dependencies = { "luarocks.nvim" },
  --   opts = {},
  -- },
  -- {
  --   "sphamba/smear-cursor.nvim",
  --   opts = {
  --     cursor_color = "",
  --   },
  -- },
}
