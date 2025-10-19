return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		"williamboman/mason-lspconfig.nvim", -- Make sure this is a dependency
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{ "folke/neodev.nvim", opts = {} },
	},
	config = function()
		-- Standard modules
		local lspconfig = require("lspconfig")
		local mason_lspconfig = require("mason-lspconfig")
		local cmp_nvim_lsp = require("cmp_nvim_lsp")
		local keymap = vim.keymap

		-- This function will be run for every server that attaches to a buffer
		-- It's where we set our keymaps
		local on_attach = function(client, bufnr)
			local opts = { buffer = bufnr, silent = true }

			opts.desc = "Show LSP references"
			keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)
			opts.desc = "Go to declaration"
			keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
			opts.desc = "Show LSP definitions"
			keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)
			opts.desc = "Show LSP implementations"
			keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)
			opts.desc = "Show LSP type definitions"
			keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)
			opts.desc = "See available code actions"
			keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
			opts.desc = "Smart rename"
			keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
			opts.desc = "Show buffer diagnostics"
			keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)
			opts.desc = "Show line diagnostics"
			keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
			opts.desc = "Go to previous diagnostic"
			keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
			opts.desc = "Go to next diagnostic"
			keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
			opts.desc = "Show documentation for what is under cursor"
			keymap.set("n", "K", vim.lsp.buf.hover, opts)
			opts.desc = "Restart LSP"
			keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)
		end

		-- Standard capabilities for autocompletion
		local capabilities = cmp_nvim_lsp.default_capabilities()

		-- Custom diagnostic signs
		local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
		end

		-- This is the crucial part that connects mason and lspconfig
		mason_lspconfig.setup_handlers({
			-- The first handler is the default one.
			-- It loops through all the servers you have installed with Mason
			-- and sets them up with the standard on_attach and capabilities.
			function(server_name)
				lspconfig[server_name].setup({
					capabilities = capabilities,
					on_attach = on_attach,
				})
			end,

			-- You can add specific overrides for servers that need special settings
			["lua_ls"] = function()
				lspconfig.lua_ls.setup({
					capabilities = capabilities,
					on_attach = on_attach,
					settings = {
						Lua = {
							diagnostics = { globals = { "vim" } },
						},
					},
				})
			end,

			["pyright"] = function()
				lspconfig.pyright.setup({
					capabilities = capabilities,
					on_attach = on_attach,
					settings = {
						python = {
							analysis = {
								-- Optional: a common setting to improve performance
								typeCheckingMode = "off",
							},
						},
					},
				})
			end,
		})
	end,
}
