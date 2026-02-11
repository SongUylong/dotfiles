local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

-- General settings
config.enable_tab_bar = true
config.window_decorations = "RESIZE"
-- Note: font, font_size, and opacity are managed by Stylix
config.window_close_confirmation = "AlwaysPrompt"
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }
config.freetype_load_target = "Light"
config.freetype_render_target = "Light"
config.scrollback_lines = 3000
config.font_size = 16

-- Catppuccin Mocha theme
config.color_scheme = "Catppuccin Mocha"

config.inactive_pane_hsb = {
	saturation = 0.24,
	brightness = 0.5,
}

-- Custom status bar configuration
config.tab_bar_at_bottom = false
config.use_fancy_tab_bar = false
config.tab_max_width = 22

-- Format tab titles
wezterm.on("format-tab-title", function(tab, tabs, panes, conf, hover, max_width)
	local title = tab.tab_index + 1 .. " " .. wezterm.nerdfonts.fa_long_arrow_right .. " "

	if tab.active_pane.title then
		title = title .. tab.active_pane.title
	end

	if #title > max_width then
		title = wezterm.truncate_right(title, max_width - 1) .. "…"
	end

	return {
		{ Text = " " .. title .. " " },
	}
end)

-- Throttle status updates to prevent flickering
local last_update = 0
local update_interval = 1 -- seconds

-- Left status (workspace, leader, zoom)
wezterm.on("update-status", function(window, pane)
	local now = os.time()
	if now - last_update < update_interval and not window:leader_is_active() then
		return
	end
	last_update = now

	local left_cells = {}
	local right_cells = {}

	local palette = window:effective_config().resolved_palette

	-- Left status: workspace/leader indicator
	local workspace = window:active_workspace()
	local leader_icon = "🌙"

	if window:leader_is_active() then
		table.insert(left_cells, { Foreground = { Color = palette.ansi[4] } })
		table.insert(left_cells, { Text = " " .. leader_icon .. " " })
	else
		table.insert(left_cells, { Foreground = { Color = palette.ansi[6] } })
		table.insert(left_cells, { Text = " " .. wezterm.nerdfonts.fa_briefcase .. " " .. workspace .. " " })
	end

	-- Check if zoomed
	local tab = pane:tab()
	if tab then
		local panes_with_info = tab:panes_with_info()
		for _, p in ipairs(panes_with_info) do
			if p.is_active and p.is_zoomed then
				table.insert(left_cells, { Foreground = { Color = palette.ansi[4] } })
				table.insert(left_cells, { Text = wezterm.nerdfonts.md_fullscreen .. " zoom " })
			end
		end
	end

	window:set_left_status(wezterm.format(left_cells))

	-- Right status: cwd and clock
	local cwd = pane:get_current_working_dir()
	if cwd then
		cwd = cwd.file_path:gsub(os.getenv("HOME"), "~")
		local basename = cwd:match("([^/]+)/?$") or cwd
		table.insert(right_cells, { Foreground = { Color = palette.ansi[7] } })
		table.insert(right_cells, { Text = basename .. " " })
		table.insert(right_cells, { Foreground = { Color = palette.brights[1] } })
		table.insert(
			right_cells,
			{ Text = wezterm.nerdfonts.fa_long_arrow_left .. " " .. wezterm.nerdfonts.oct_file_directory .. " " }
		)
	end

	local time = wezterm.time.now():format("%I:%M")
	table.insert(right_cells, { Foreground = { Color = palette.ansi[5] } })
	table.insert(right_cells, { Text = time .. " " })
	table.insert(right_cells, { Foreground = { Color = palette.brights[1] } })
	table.insert(
		right_cells,
		{ Text = wezterm.nerdfonts.fa_long_arrow_left .. " " .. wezterm.nerdfonts.fa_clock .. " " }
	)

	window:set_right_status(wezterm.format(right_cells))
end)

config.disable_default_mouse_bindings = false

config.leader = { key = "w", mods = "ALT", timeout_milliseconds = math.maxinteger }

config.keys = {
	{ key = "n", mods = "SUPER", action = act.ActivateCopyMode },
	{ key = "t", mods = "SUPER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "x", mods = "SUPER", action = act.CloseCurrentTab({ confirm = false }) },
	{ key = "m", mods = "SUPER", action = act.ActivateKeyTable({ name = "workspace" }) },
	-- Pane splitting
	{ key = ";", mods = "SUPER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "'", mods = "SUPER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	-- Pane navigation
	{ key = "h", mods = "SUPER", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "SUPER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "SUPER", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "SUPER", action = act.ActivatePaneDirection("Right") },
}
config.mouse_bindings = {
	-- Ctrl-click will open the link under the mouse cursor
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = wezterm.action.OpenLinkAtMouseCursor,
	},
}

config.key_tables = {
	tab = {
		{ key = "o", action = act.SpawnTab("CurrentPaneDomain") },
		--Tab Navigation
		{ key = "[", action = act.ActivateTabRelative(-1) },
		{ key = "]", action = act.ActivateTabRelative(1) },
		-- Key table for moving tabs around
		{ key = "m", action = act.ActivateKeyTable({ name = "move_tab", one_shot = false }) },
		-- Tab Close
		{ key = "x", action = act.CloseCurrentTab({ confirm = true }) },
		{ key = "X", action = act.EmitEvent("close-all-other-tabs") },
	},
	move_tab = {
		{ key = "h", action = act.MoveTabRelative(-1) },
		{ key = "j", action = act.MoveTabRelative(-1) },
		{ key = "k", action = act.MoveTabRelative(1) },
		{ key = "l", action = act.MoveTabRelative(1) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },
	},
	resize_pane = {
		{ key = "h", action = act.AdjustPaneSize({ "Left", 5 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 5 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 5 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 5 }) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },
	},
	workspace = {
		-- Fuzzy workspace finder
		{
			key = "f",
			action = act.ShowLauncherArgs({
				flags = "FUZZY|WORKSPACES",
				title = "🔍 Find Workspace",
			}),
		},
		-- Create new workspace
		{
			key = "n",
			action = act.PromptInputLine({
				description = wezterm.format({
					{ Attribute = { Intensity = "Bold" } },
					{ Text = "🏗️  New workspace name: " },
				}),
				action = wezterm.action_callback(function(window, pane, line)
					if line and line ~= "" then
						window:perform_action(
							act.SwitchToWorkspace({
								name = line,
							}),
							pane
						)
					end
				end),
			}),
		},
		-- Rename current tab
		{
			key = "r",
			action = act.PromptInputLine({
				description = wezterm.format({
					{ Attribute = { Intensity = "Bold" } },
					{ Text = "Rename tab: " },
				}),
				action = wezterm.action_callback(function(window, pane, line)
					if line and line ~= "" then
						window:active_tab():set_title(line)
					end
				end),
			}),
		},
		-- Show all workspaces and domains
		{
			key = "s",
			action = act.ShowLauncherArgs({
				flags = "FUZZY|WORKSPACES|DOMAINS",
				title = "📋 All Workspaces & Domains",
			}),
		},
		-- Previous/next workspace
		{ key = "h", action = act.SwitchWorkspaceRelative(-1) },
		{ key = "l", action = act.SwitchWorkspaceRelative(1) },
		-- Help
		{
			key = "?",
			action = act.ShowLauncherArgs({
				flags = "FUZZY|WORKSPACES",
				title = "🔍 Workspace Manager",
			}),
		},
	},
}
--utils of panes
wezterm.on("close-all-other-panes", function(window, pane)
	local tab = pane:tab()
	local panes = tab:panes()

	for _, p in ipairs(panes) do
		if p:pane_id() ~= pane:pane_id() then
			p:activate()
			window:perform_action(act.CloseCurrentPane({ confirm = false }), p)
		end
	end
end)
for i = 1, 9 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "ALT",
		action = act.ActivateTab(i - 1),
	})
end
--utils of tabs
wezterm.on("close-all-other-tabs", function(window, pane)
	local tab = window:active_tab()
	local mux_window = window:mux_window()
	local tabs = mux_window:tabs()

	for _, t in ipairs(tabs) do
		if t:tab_id() ~= tab:tab_id() then
			t:activate()
			window:perform_action(wezterm.action.CloseCurrentTab({ confirm = false }), pane)
		end
	end
end)
--aerospace
table.insert(config.keys, { key = "e", mods = "ALT", action = "Nop" })

-- Let AeroSpace handle Alt+e instead of WezTerm
return config
