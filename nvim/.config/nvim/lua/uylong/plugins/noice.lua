return {
	"folke/noice.nvim",
	event = "VeryLazy",
	enabled = true,
	dependencies = {
		"MunifTanjim/nui.nvim",
	},
	config = function()
		require("noice").setup({
			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
				},
				hover = { silent = true },
			},

			views = {
				cmdline = {
					position = { row = "100%", col = "0%" }, -- bottom-left
					size = { width = "50%", height = 1 }, -- smaller height
					border = { style = "rounded" },
				},
				popupmenu = {
					relative = "editor",
					position = { row = "100%-2", col = "50%" }, -- just above cmdline
					size = { width = "50%", height = 10 },
					border = { style = "rounded" },
				},
				mini = {
					position = { row = "100%", col = "50%" },
				},
			},

			presets = {
				bottom_search = true,
				command_palette = true,
				long_message_to_split = true,
				inc_rename = false,
				lsp_doc_border = true,
			},
		})
	end,
}
