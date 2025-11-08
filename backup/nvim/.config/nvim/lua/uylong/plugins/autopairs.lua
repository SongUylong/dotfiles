return {
	{
		"windwp/nvim-autopairs",
		event = { "InsertEnter" },
		dependencies = { "hrsh7th/nvim-cmp" },
		config = function()
			local autopairs = require("nvim-autopairs")

			autopairs.setup({
				check_ts = true,
				ts_config = {
					java = false,
				},
			})

			local cmp_autopairs = require("nvim-autopairs.completion.cmp")
			local cmp = require("cmp")
			cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
		end,
	},

	{
		"windwp/nvim-ts-autotag",
		ft = {
			"html",
			"javascript",
			"javascriptreact",
			"typescript",
			"typescriptreact",
			"svelte",
			"vue",
			"xml",
			"lua",
		},
		config = function()
			require("nvim-ts-autotag").setup()
		end,
	},
}
