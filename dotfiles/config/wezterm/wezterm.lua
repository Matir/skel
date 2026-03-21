
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0-- https://wezfurlong.org/wezterm/config/files.html
-- https://alexplescan.com/posts/2024/08/10/wezterm/
-- https://github.com/wez/wezterm/issues/6112
-- https://github.com/wez/wezterm/issues/5754
local wezterm = require "wezterm"
local config = wezterm.config_builder()
local action = wezterm.action
local mux = wezterm.mux

config.audible_bell = "Disabled"
config.check_for_updates = false -- managed by brew
config.set_environment_variables = {
  PATH = '/opt/homebrew/bin:/usr/local/bin/:' .. os.getenv('PATH')
}

local function scheme_for_appearance(a)
  return a:find("Dark") and "Catppuccin Macchiato" or "Catppuccin Latte"
end

config.font = wezterm.font { family = 'JetBrains Mono', weight = 'Medium', harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' } }
config.font_size = 15.0
config.line_height = 1.0
config.bold_brightens_ansi_colors = true
config.color_scheme = scheme_for_appearance(wezterm.gui.get_appearance())
config.macos_window_background_blur = 20
config.window_background_opacity = 0.96

config.window_decorations = 'RESIZE|INTEGRATED_BUTTONS'
config.window_padding = { left = '0.5cell', right = '0.5cell', top = '1.5cell', bottom = '0.5cell' }
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.tab_max_width = 32
config.show_new_tab_button_in_tab_bar = false
-- config.hide_tab_bar_if_only_one_tab = true -- sometimes procude wrong window size on maximize

config.default_cursor_style = 'BlinkingBar'
config.animation_fps = 1
config.cursor_blink_rate = 500
config.prefer_egl = true
config.max_fps = 60

config.enable_scroll_bar = true
config.scrollback_lines = 10000

-- makes wezterm to work like tmux; see also: https://bower.sh/zmx-session-persistence
config.default_gui_startup_args = { 'connect', 'unix' }
config.window_close_confirmation = 'NeverPrompt'

local function maximize_window(window)
  if not window.gui_window then return end

  local screen = wezterm.gui.screens().active
  local guiwin = window:gui_window()
  if not screen or not guiwin then return end

  -- window:gui_window():maximize() -- have long animation
  guiwin:set_position(screen.x, screen.y)
  guiwin:set_inner_size(screen.width, screen.height)
end

-- https://github.com/wez/wezterm/issues/3299#issuecomment-2145712082
wezterm.on("gui-startup", function(cmd)
	local tab, pane, window = mux.spawn_window(cmd or {})
  maximize_window(window)
end)

wezterm.on("gui-attached", function(window)
  local workspace = mux.get_active_workspace()
  for _, window in ipairs(mux.all_windows()) do
    if window:get_workspace() == workspace then
      maximize_window(window)
    end
  end
end)

wezterm.on("window-resized", function(window, pane)
  maximize_window(window)
end)

-- see also https://wezterm.org/config/lua/wezterm/battery_info.html
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local title = (tab.tab_title ~= "" and tab.tab_title) or tab.active_pane.title
  title = title:lower()

  local prefix = tostring(tab.tab_index + 1) .. ":"
  local width = math.max(1, max_width - (#prefix + 2))
  title = wezterm.truncate_right(title, width)

  return " " .. prefix .. title .. " "
end)

-- https://github.com/wezterm/wezterm/issues/1988#issuecomment-2462216249
local function search_cmd(window, pane)
  window:perform_action(action.Search 'CurrentSelectionOrEmptyString', pane)
  window:perform_action(action.Multiple {
    action.CopyMode 'ClearPattern',
    action.CopyMode 'ClearSelectionMode',
    action.CopyMode 'MoveToScrollbackBottom'
  }, pane)
end

config.keys = {
  { key = 'q', mods = 'CMD', action = wezterm.action.Nop }, -- prevent accidental quit
  { key = 't', mods = 'CMD', action = action.SpawnTab 'CurrentPaneDomain' },
  { key = 'd', mods = 'CMD', action = action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'd', mods = 'CMD|SHIFT', action = action.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = 'k', mods = 'CMD', action = action.ClearScrollback 'ScrollbackAndViewport' },
  { key = 'w', mods = 'CMD', action = action.CloseCurrentPane { confirm 100  6869  100  6869    0     0  42178      0 --:--:-- --:--:-- --:--:-- 42401
= false } },
  { key = 'w', mods = 'CMD|SHIFT', action = action.CloseCurrentTab { confirm = false } },
  { key = 'a', mods = 'CMD', action = action.SelectTextAtMouseCursor 'SemanticZone', },
  { key = 'LeftArrow', mods = 'CMD', action = action.SendKey { key = 'Home' } },
  { key = 'RightArrow', mods = 'CMD', action = action.SendKey { key = 'End' } },
  { key = 'Backspace', mods = 'CMD', action = action.SendKey({ mods = "CTRL", key = "u" }) },
  { key = 'Backspace', mods = 'OPT', action = action.SendKey({ mods = "CTRL", key = "w" }) },
  { key = 'P', mods = 'CMD|SHIFT', action = action.ActivateCommandPalette },
  { key = 'f', mods = 'CMD', action = wezterm.action_callback(search_cmd) },
  { key = ',', mods = 'CMD', action = action.SpawnCommandInNewTab { cwd = wezterm.home_dir, args = { 'code', wezterm.config_file } } },
  { key = 'E', mods = 'CMD|SHIFT', action = action.PromptInputLine {
    description = 'Enter tab title (empty to unset):',
    action = wezterm.action_callback(function(window, _, line)
      window:active_tab():set_title(line)
    end),
  }},
}

config.mouse_bindings = {
  { event = { Up = { streak = 1, button = "Left" } }, mods = "NONE", action = action.Nop },
  { event = { Up = { streak = 1, button = "Left" } }, mods = "CMD", action = action.OpenLinkAtMouseCursor },
  -- Disable CMD + LeftClick window drag (make it behave like normal select)
  -- { event = { Drag = { streak = 1, button = 'Left' } }, mods = "CMD", action = action.Nop },
  { event = { Drag = { streak = 1, button = "Left" } }, mods = "CMD", action = action.ExtendSelectionToMouseCursor("Cell") },
}

-- https://code.visualstudio.com/docs/configure/command-line#_opening-vs-code-with-urls
-- path-symbols: [\w@\.\/\-\[\]\(\)]

local function path_exists(path)
  local ok, _, _ = wezterm.run_child_process { "test", "-e", path }
  return ok
end

config.hyperlink_rules = wezterm.default_hyperlink_rules()
-- config.hyperlink_rules = {}

table.insert(config.hyperlink_rules, {
  regex = [[((?:[\w@\.\/\-\[\]\(\)]+\/)+[\w@\.\/\-\[\]\(\)]+\.\w+)\b]],
  format = "vscode://file/$PWD/$1",
  highlight = 1,
})

table.insert(config.hyperlink_rules, {
  regex = [[((?:[\w@\.\/\-\[\]\(\)]+\/)+[\w@\.\/\-\[\]\(\)]+\.\w+):(\d+):(\d+)]],
  format = "vscode://file/$PWD/$1:$2:$3",
  highlight = 1,
})

wezterm.on("open-uri", function(window, pane, uri)
  if uri:find("$PWD") then
    local cwd_uri = pane:get_current_working_dir()
    local before, after = uri:match("^(.-)$PWD/(.+)$")
    wezterm.log_info(before, after, path_exists(after))
    if path_exists(after) then
      uri = before .. after
    else
      uri = uri:gsub("$PWD", cwd_uri.file_path)
    end

    wezterm.log_info(uri)
    wezterm.open_with(uri)
    return false
  end

  return true
end)

return config
