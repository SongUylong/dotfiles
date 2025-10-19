return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		local mason = require("mason")
		local mason_lspconfig = require("mason-lspconfig")
		local mason_tool_installer = require("mason-tool-installer")

		-- Setup for mason.nvim
		mason.setup({
			PATH = "prepend",
			providers = {
				["python:3"] = {
					-- Paste the path you copied here
					install_dir = "/Users/eric/.pyenv/shims/python3",
				},
			},
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		-- Setup for mason-lspconfig.nvim
		mason_lspconfig.setup({
			-- A list of LSPs to install automatically
			ensure_installed = {
				"html",
				"cssls",
				"tailwindcss",
				"svelte",
				"lua_ls",
				"graphql",
				"emmet_ls",
				"prismals",
				"pyright",
				"eslint",
			},
			-- This is the crucial part that connects Mason to nvim-lspconfig
			handlers = {
				-- The first argument to setup is the server name.
				-- This default handler will pass all servers installed by Mason
				-- to the nvim-lspconfig setup function.
				function(server_name)
					require("lspconfig")[server_name].setup({})
				end,

				-- You can also override the default setup for specific servers.
				-- For example, you can provide custom settings for lua_ls.
				["lua_ls"] = function()
					require("lspconfig").lua_ls.setup({
						settings = {
							Lua = {
								diagnostics = {
									-- Get the language server to recognize the `vim` global
									globals = { "vim" },
								},
							},
						},
					})
				end,
			},
		})

		-- Setup for mason-tool-installer.nvim
		mason_tool_installer.setup({
			-- A list of formatters and linters to install automatically
			ensure_installed = {
				"prettier",
				"isort",
				"black",
				"pylint",
				"eslint_d",
			},
		})
	end,
}
