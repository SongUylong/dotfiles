local session_tracker_file = vim.fn.stdpath("data") .. "/last_session_name.txt"

local function get_last_session()
	if vim.fn.filereadable(session_tracker_file) == 1 then
		return vim.fn.readfile(session_tracker_file)[1]
	end
	return nil
end

local function set_last_session(name)
	vim.fn.writefile({ name }, session_tracker_file)
end

return {
	"rmagatti/auto-session",
	lazy = false,
	keys = {
		-- Save session (prompt if new, overwrite if exists)
		{
			"<leader>ss",
			function()
				local current_session_name = get_last_session()
				local name

				if current_session_name then
					name = current_session_name
				else
					name = vim.fn.input("Session name: ")
				end

				if name ~= "" then
					vim.cmd("AutoSession save " .. name)
					set_last_session(name)
					print("Saved session: " .. name)
				else
					print("Session not saved (no name entered)")
				end
			end,
			desc = "Save session (prompt if new, overwrite if exists)",
		},

		{
			"<leader>sr",
			"<cmd>AutoSession search<CR>",
			desc = "Session picker (Telescope)",
		},
	},

	opts = {
		auto_save = false, -- disable auto save
		auto_restore = false, -- disable auto restore
		auto_create = false, -- don't create sessions automatically
		suppressed_dirs = { "~/", "~/Downloads", "~/Documents" },
		root_dir = vim.fn.stdpath("data") .. "/sessions/",
		session_lens = {
			picker = "telescope", -- use Telescope
			load_on_setup = true,
		},
	},
}
