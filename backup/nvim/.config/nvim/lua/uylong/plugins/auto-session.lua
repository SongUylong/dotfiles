return {
	"rmagatti/auto-session",
	lazy = false, -- Necessary for auto-restoring on startup

	keys = {
		{
			-- For SAVING a session WITH A CUSTOM NAME. This will prompt you.
			"<leader>ss", -- Note the capital 'S'
			function()
				local session_name = vim.fn.input("Enter session name: ")
				if session_name and session_name ~= "" then
					vim.cmd("AutoSession save " .. session_name)
					vim.notify("Session saved as: " .. session_name)
				else
					vim.notify("Session save cancelled.", vim.log.levels.WARN)
				end
			end,
			desc = "Save session with a custom name",
		},
		{
			-- For RESTORING, DELETING, and SEARCHING sessions with Telescope.
			"<leader>sr",
			"<cmd>AutoSession search<CR>",
			desc = "Search/Restore/Delete sessions (Telescope)",
		},
	},

	opts = {
		-- Automatically restore the session for the current directory if one exists.
		auto_restore = true,

		-- We set these to false so the plugin only acts when you press the keymaps.
		auto_save = false,
		auto_create = false,

		-- This section enables the Telescope UI (the session_lens).
		session_lens = {
			picker = "telescope", -- Use Telescope as the interface
			load_on_setup = true,
			-- Default keymap to delete a session is <C-d> in insert mode.
			mappings = {
				delete_session = { "i", "<C-d>" },
			},
		},
		-- Recommended setting to make sessions more useful
		sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions",

		log_level = "error",
		root_dir = vim.fn.stdpath("data") .. "/sessions/",
		suppressed_dirs = { "~/", "~/Downloads", "~/Documents" },
	},
}
