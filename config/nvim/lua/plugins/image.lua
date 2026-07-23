return {
  {
    "3rd/image.nvim",
    enabled = true,
    lazy = true,
    build = false,
    init = function()
      require("config.khmer_view").setup()
    end,
    opts = {
      backend = "kitty",
      processor = "magick_cli",
      integrations = {
        markdown = { enabled = false },
        asciidoc = { enabled = false },
        neorg = { enabled = false },
        rst = { enabled = false },
        typst = { enabled = false },
        html = { enabled = false },
        css = { enabled = false },
      },
      max_width_window_percentage = 100,
      max_height_window_percentage = 100,
      window_overlap_clear_enabled = true,
      hijack_file_patterns = {},
    },
  },
}
