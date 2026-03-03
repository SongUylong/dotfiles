local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

-- OS detection
local is_linux = wezterm.target_triple:find("linux") ~= nil
local is_mac = wezterm.target_triple:find("apple") ~= nil

-- ── OS-specific settings ─────────────────────────────────────────────────────
if is_linux then
	config.enable_wayland = true
	config.front_end = "WebGpu"
	config.webgpu_power_preference = "HighPerformance"
	config.window_decorations = "NONE"
	config.font = wezterm.font_with_fallback({ "CaskaydiaCove Nerd Font" })
elseif is_mac then
	config.window_decorations = "RESIZE"
	config.font_size = 16
	config.send_composed_key_when_left_alt_is_pressed = true
end

-- ── Performance ──────────────────────────────────────────────────────────────
config.max_fps = 120
config.animation_fps = 120
config.status_update_interval = 1000

-- ── General ──────────────────────────────────────────────────────────────────
config.enable_tab_bar = true
config.window_close_confirmation = "AlwaysPrompt"
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }
config.freetype_load_target = "Light"
config.freetype_render_target = "Light"
config.scrollback_lines = 3000
config.font_shaper = "Harfbuzz"
config.use_ime = false
config.color_scheme = "Catppuccin Mocha"

config.inactive_pane_hsb = {
	saturation = 0.24,
	brightness = 0.5,
}

-- ── Tab bar ──────────────────────────────────────────────────────────────────
config.tab_bar_at_bottom = false
config.use_fancy_tab_bar = false
config.tab_max_width = 22

wezterm.on("format-tab-title", function(tab, tabs, panes, conf, hover, max_width)
	local title = tab.tab_index + 1 .. " " .. wezterm.nerdfonts.fa_long_arrow_right .. " "
	if tab.active_pane.title then
		title = title .. tab.active_pane.title
	end
	if #title > max_width then
		title = wezterm.truncate_right(title, max_width - 1) .. "…"
	end
	return { { Text = " " .. title .. " " } }
end)

-- ── Status bar ───────────────────────────────────────────────────────────────
local last_update = 0
local update_interval = 1

wezterm.on("update-status", function(window, pane)
	local now = os.time()
	if now - last_update < update_interval and not window:leader_is_active() then
		return
	end
	last_update = now

	local left_cells = {}
	local right_cells = {}
	local palette = window:effective_config().resolved_palette
	local workspace = window:active_workspace()
	local leader_icon = "🌙"

	if window:leader_is_active() then
		table.insert(left_cells, { Foreground = { Color = palette.ansi[4] } })
		table.insert(left_cells, { Text = " " .. leader_icon .. " " })
	else
		table.insert(left_cells, { Foreground = { Color = palette.ansi[6] } })
		table.insert(left_cells, { Text = " " .. wezterm.nerdfonts.fa_briefcase .. " " .. workspace .. " " })
	end

	local tab = pane:tab()
	if tab then
		for _, p in ipairs(tab:panes_with_info()) do
			if p.is_active and p.is_zoomed then
				table.insert(left_cells, { Foreground = { Color = palette.ansi[4] } })
				table.insert(left_cells, { Text = wezterm.nerdfonts.md_fullscreen .. " zoom " })
			end
		end
	end

	window:set_left_status(wezterm.format(left_cells))

	local cwd = pane:get_current_working_dir()
	if cwd then
		cwd = cwd.file_path:gsub(os.getenv("HOME"), "~")
		local basename = cwd:match("([^/]+)/?$") or cwd
		table.insert(right_cells, { Foreground = { Color = palette.ansi[7] } })
		table.insert(right_cells, { Text = basename .. " " })
		table.insert(right_cells, { Foreground = { Color = palette.brights[1] } })
		table.insert(right_cells, { Text = wezterm.nerdfonts.fa_long_arrow_left .. " " .. wezterm.nerdfonts.oct_file_directory .. " " })
	end

	local time = wezterm.time.now():format("%I:%M")
	table.insert(right_cells, { Foreground = { Color = palette.ansi[5] } })
	table.insert(right_cells, { Text = time .. " " })
	table.insert(right_cells, { Foreground = { Color = palette.brights[1] } })
	table.insert(right_cells, { Text = wezterm.nerdfonts.fa_long_arrow_left .. " " .. wezterm.nerdfonts.fa_clock .. " " })

	window:set_right_status(wezterm.format(right_cells))
end)

-- ── Keys ─────────────────────────────────────────────────────────────────────
config.disable_default_mouse_bindings = false

-- Use SUPER on macOS, ALT on Linux for common binds
local mod = is_mac and "SUPER" or "ALT"

config.keys = {
	{ key = "n", mods = mod, action = act.ActivateCopyMode },
	{ key = "t", mods = mod, action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "x", mods = mod, action = act.CloseCurrentTab({ confirm = false }) },
	-- Pane navigation (forward to zellij)
	{ key = "h", mods = mod, action = wezterm.action.SendKey({ key = "h", mods = "ALT" }) },
	{ key = "j", mods = mod, action = wezterm.action.SendKey({ key = "j", mods = "ALT" }) },
	{ key = "k", mods = mod, action = wezterm.action.SendKey({ key = "k", mods = "ALT" }) },
	{ key = "l", mods = mod, action = wezterm.action.SendKey({ key = "l", mods = "ALT" }) },
}

config.mouse_bindings = {
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = wezterm.action.OpenLinkAtMouseCursor,
	},
}

-- Tab number shortcuts (ALT+1..9 always)
for i = 1, 9 do
	table.insert(config.keys, { key = tostring(i), mods = "ALT", action = act.ActivateTab(i - 1) })
end

-- macOS: block Alt+e for AeroSpace
if is_mac then
	table.insert(config.keys, { key = "e", mods = "ALT", action = "Nop" })
end

-- ── Utils ────────────────────────────────────────────────────────────────────
wezterm.on("close-all-other-panes", function(window, pane)
	local tab = pane:tab()
	for _, p in ipairs(tab:panes()) do
		if p:pane_id() ~= pane:pane_id() then
			p:activate()
			window:perform_action(act.CloseCurrentPane({ confirm = false }), p)
		end
	end
end)

return config
