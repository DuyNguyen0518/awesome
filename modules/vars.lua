-- modules/vars.lua
local beautiful = require("beautiful")
local gears = require("gears")

local _M = {}

-- Safely build the path to your theme file
-- This expects 'theme.lua' to be in ~/.config/awesome/
local theme_path = gears.filesystem.get_configuration_dir() .. "theme.lua"

-- Initialize the theme
beautiful.init(theme_path)

-- Fallback wallpaper if theme doesn't define one
if not beautiful.wallpaper then
    beautiful.wallpaper = "/usr/share/awesome/themes/default/background.png"
end

_M.terminal = "x-terminal-emulator"
_M.editor = os.getenv("EDITOR") or "editor"
_M.editor_cmd = _M.terminal .. " -e " .. _M.editor
_M.modkey = "Mod4"

return _M