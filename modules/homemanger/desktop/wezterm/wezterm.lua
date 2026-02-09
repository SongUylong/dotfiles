local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

-- Performance settings
config.enable_wayland = true
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
config.max_fps = 120
config.animation_fps = 120
config.status_update_interval = 1000

-- General settings
config.font_size = 10
config.color_scheme = "Catppuccin Macchiato"
config.enable_tab_bar = true
config.window_decorations = "NONE"
config.window_background_opacity = 1
config.font = wezterm.font("CaskaydiaCove Nerd Font", { weight = "Regular", stretch = "Normal", style = "Normal" })
config.window_close_confirmation = "AlwaysPrompt"
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }
config.freetype_load_target = "Light"
config.freetype_render_target = "Light"
config.scrollback_lines = 3000

config.inactive_pane_hsb = {
	saturation = 0.24,
	brightness = 0.5,
}

-- Colors (must be defined before tab_bar colors)
config.colors = {
	foreground = "#CBE0F0",
	background = "#011423",
	cursor_bg = "#47FF9C",
	cursor_border = "#47FF9C",
	cursor_fg = "#011423",
	selection_bg = "#033259",
	selection_fg = "#CBE0F0",
	ansi = {
		"#214969",
		"#E52E2E",
		"#44FFB1",
		"#FFE073",
		"#0FC5ED",
		"#a277ff",
		"#24EAF7",
		"#24EAF7",
	},
	brights = {
		"#214969",
		"#E52E2E",
		"#44FFB1",
		"#FFE073",
		"#A277FF",
		"#a277ff",
		"#24EAF7",
		"#24EAF7",
	},
	tab_bar = {
		background = "transparent",
		active_tab = {
			bg_color = "transparent",
			fg_color = "#0FC5ED",
		},
		inactive_tab = {
			bg_color = "transparent",
			fg_color = "#24EAF7",
		},
		new_tab = {
			bg_color = "transparent",
			fg_color = "#44FFB1",
		},
	},
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
	local panes_with_info = pane:tab():panes_with_info()
	for _, p in ipairs(panes_with_info) do
		if p.is_active and p.is_zoomed then
			table.insert(left_cells, { Foreground = { Color = palette.ansi[4] } })
			table.insert(left_cells, { Text = wezterm.nerdfonts.md_fullscreen .. " zoom " })
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
	{ key = "c", mods = "LEADER", action = act.ActivateCopyMode },
	--Pane Split
	{ key = "v", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "h", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	--Panes Move
	{ key = "h", mods = "ALT", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "ALT", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "ALT", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "ALT", action = act.ActivatePaneDirection("Right") },
	--Panes Zoom
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
	--Panes Close
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "X", mods = "LEADER", action = act.EmitEvent("close-all-other-panes") },
	--Panes Rotate
	{ key = "r", mods = "LEADER", action = act.RotatePanes("Clockwise") },
	--Panes Resize
	{ key = "s", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
	-- Workspace
	{ key = "w", mods = "LEADER", action = act.ActivateKeyTable({ name = "workspace" }) },
	-- Tabs
	{ key = "t", mods = "LEADER", action = act.ActivateKeyTable({ name = "tab" }) },
	{
		key = "p",
		mods = "LEADER",
		action = wezterm.action_callback(function(window, pane)
			local selection = window:get_selection_text_for_pane(pane)

			-- If we have a selected text and it matches a URL pattern, open it
			if selection and selection ~= "" then
				local url_pattern = "https?://%S+"
				if selection:match(url_pattern) then
					wezterm.log_info("Opening: " .. selection)
					wezterm.open_with(selection) -- Opens the URL in the default browser
				else
					wezterm.log_info("No URL selected!")
				end
			end
		end),
	},
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
		{ key = "f", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
		{
			key = "n",
			action = act.PromptInputLine({
				description = wezterm.format({
					{ Attribute = { Intensity = "Bold" } },
					{ Foreground = { AnsiColor = "Fuchsia" } },
					{ Text = "Enter name for new workspace" },
				}),
				action = wezterm.action_callback(function(window, pane, line)
					if line then
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
		{ key = "l", action = act.SwitchWorkspaceRelative(1) },
		{ key = "h", action = act.SwitchWorkspaceRelative(-1) },
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
