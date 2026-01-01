-- rc.lua
-- If LuaRocks is installed, make sure that packages installed through it are found (e.g. lgi).
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local naughty = require("naughty")
local menubar = require("menubar")

-- {{{ Error handling
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        if in_error then return end
        in_error = true
        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Load Modules
-- 1. Variables (Terminal, Editor, Theme Init)
local vars = require("modules.vars")

-- 2. Menu (Main Menu, Launcher)
local mymenu = require("modules.menu")

-- 3. UI (Wibar, Layouts, Wallpaper)
-- We don't need to store this in a variable, it just sets up the screen.
require("modules.ui")

-- 4. Keys (Keybindings and Mouse Bindings)
local keys = require("modules.keys")

-- 5. Rules (Window Rules)
require("modules.rules")

-- 6. Signals (Event listeners like focus, titlebars)
require("modules.signals")
-- }}}

-- {{{ Final Setup
-- Set the terminal for the menubar
menubar.utils.terminal = vars.terminal

-- Set Global Keys
root.keys(keys.globalkeys)

-- Set Desktop Mouse Buttons
root.buttons(keys.desktop_buttons)
-- }}}