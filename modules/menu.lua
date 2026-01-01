-- modules/menu.lua
local awful = require("awful")
local hotkeys_popup = require("awful.hotkeys_popup")
local beautiful = require("beautiful")
local debian = require("debian.menu")
local vars = require("modules.vars")

-- Enable hotkeys help widget for VIM and other apps
require("awful.hotkeys_popup.keys")

local has_fdo, freedesktop = pcall(require, "freedesktop")

local _M = {}

-- Create a launcher widget and a main menu
local myawesomemenu = {
   { "hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
   { "manual", vars.terminal .. " -e man awesome" },
   { "edit config", vars.editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", function() awesome.quit() end },
}

local menu_awesome = { "awesome", myawesomemenu, beautiful.awesome_icon }
local menu_terminal = { "open terminal", vars.terminal }

if has_fdo then
    _M.mymainmenu = freedesktop.menu.build({
        before = { menu_awesome },
        after =  { menu_terminal }
    })
else
    _M.mymainmenu = awful.menu({
        items = {
                  menu_awesome,
                  { "Debian", debian.menu.Debian_menu.Debian },
                  menu_terminal,
                }
    })
end

_M.mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = _M.mymainmenu })

return _M