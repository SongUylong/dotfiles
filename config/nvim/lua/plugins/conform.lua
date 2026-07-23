return {
  "stevearc/conform.nvim",
  opts = {
    format_on_save = {
      timeout_ms = 1000,
      lsp_fallback = true,
    },
    formatters_by_ft = {
      javascript = { "prettierd", "prettier", stop_after_first = true },
      typescript = { "prettierd", "prettier", stop_after_first = true },
      javascriptreact = { "prettierd", "prettier", stop_after_first = true },
      typescriptreact = { "prettierd", "prettier", stop_after_first = true },
      css = { "prettierd", "prettier", stop_after_first = true },
      scss = { "prettierd", "prettier", stop_after_first = true },
      html = { "prettierd", "prettier", stop_after_first = true },
      json = { "prettierd", "prettier", stop_after_first = true },
      jsonc = { "prettierd", "prettier", stop_after_first = true },
      yaml = { "prettierd", "prettier", stop_after_first = true },
      markdown = { "prettierd", "prettier", stop_after_first = true },
      graphql = { "prettierd", "prettier", stop_after_first = true },
      prisma = { "prettierd", "prettier", stop_after_first = true },
      lua = { "stylua" },
      python = { "ruff_format", "black", stop_after_first = true },
      go = { "gofmt", "goimports" },
      rust = { "rustfmt" },
      c = { "clang-format" },
      cpp = { "clang-format" },
      java = { "clang-format" },
      cs = { "clang-format" },
      php = { "php_cs_fixer" },
      sh = { "shfmt" },
      bash = { "shfmt" },
      zsh = { "shfmt" },
      toml = { "taplo" },
    },
    formatters = {
      prettier = {
        prepend_args = { "--bracket-same-line", "false" },
      },
      stylua = {
        prepend_args = { "--collapse-simple-statement", "Never" },
      },
      ["clang-format"] = {
        prepend_args = {
          "--style={BasedOnStyle: Google, BreakBeforeBraces: Allman, IndentWidth: 2, TabWidth: 2, UseTab: Never}",
        },
      },
    },
  },
}
