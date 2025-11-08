return {
	"kylechui/nvim-surround",
	event = { "BufReadPre", "BufNewFile" },
	version = "*",
	config = function()
		require("nvim-surround").setup({
			keymaps = {
				insert = "<C-g>s", -- leave default insert mapping
				insert_line = "<C-g>S",
				normal = "sa", -- was "ys"
				normal_cur = "sas", -- was "yss"
				normal_line = "sA", -- optional for line surround
				visual = "sa", -- now `sa` works in visual mode too
				delete = "sd", -- was "ds"
				change = "sr", -- was "cs"
			},
		})
	end,
}
