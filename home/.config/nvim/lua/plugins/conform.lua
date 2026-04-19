return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      javascript = { "prettier" },
      typescript = { "prettier" },
      javascriptreact = { "prettier" },
      typescriptreact = { "prettier" },
      css = { "prettier" },
      html = { "prettier" },
      json = { "prettier" },
      yaml = { "prettier" },
      markdown = { "prettier" },
      lua = { "stylua" },
      python = { "black" },
      c = { "clang-format" },
      cpp = { "clang-format" },
      java = { "clang-format" },
      cs = { "clang-format" },
      php = { "php_cs_fixer" },
    },
    formatters = {
      prettier = {
        prepend_args = {
          "--bracket-same-line",
          "false",
        },
      },
      stylua = {
        prepend_args = {
          "--collapse-simple-statement",
          "Never",
        },
      },
      ["clang-format"] = {
        prepend_args = {
          "--style={BasedOnStyle: Google, BreakBeforeBraces: Allman, IndentWidth: 2, TabWidth: 2, UseTab: Never}",
        },
      },
    },
  },
}
