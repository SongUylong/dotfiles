return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		"nvim-tree/nvim-web-devicons",
		"folke/todo-comments.nvim",
		{
			"nvim-telescope/telescope-ui-select.nvim",
			config = function()
				require("telescope").load_extension("ui-select")
			end,
		},
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")
		local themes = require("telescope.themes")

		telescope.setup({
			defaults = {
				path_display = { "smart" },
				file_ignore_patterns = { "node_modules", ".git" },
				mappings = {
					i = {
						["<C-j>"] = actions.move_selection_next,
						["<C-k>"] = actions.move_selection_previous,
						["<C-q>"] = function(prompt_bufnr)
							actions.send_to_qflist(prompt_bufnr)
							actions.open_qflist()
						end,
					},
				},
			},
			extensions = {
				["ui-select"] = themes.get_dropdown({}),
			},
		})

		telescope.load_extension("fzf")
		telescope.load_extension("ui-select")

		local keymap = vim.keymap

		-- Find files in current working directory (including dotfiles)
		keymap.set("n", "<leader>ff", function()
			require("telescope.builtin").find_files({
				hidden = true,
				no_ignore = true,
				cwd = vim.loop.cwd(),
			})
		end, { desc = "Fuzzy find files in cwd" })

		-- Find recent files
		keymap.set("n", "<leader>fr", function()
			require("telescope.builtin").oldfiles({
				cwd = vim.loop.cwd(),
			})
		end, { desc = "Fuzzy find recent files" })

		-- Live grep in current working directory
		keymap.set("n", "<leader>fs", function()
			require("telescope.builtin").live_grep({
				cwd = vim.loop.cwd(),
			})
		end, { desc = "Find string in cwd" })

		-- Grep string under cursor in current working directory
		keymap.set("n", "<leader>fc", function()
			require("telescope.builtin").grep_string({
				cwd = vim.loop.cwd(),
			})
		end, { desc = "Find string under cursor in cwd" })

		-- Todo comments search
		keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find todos" })
	end,
}
