-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

-- Load Debian menu entries
local debian = require("debian.menu")
local has_fdo, freedesktop = pcall(require, "freedesktop")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.

-- Declaring other variables

padding = 4
global_wibar_enabled = true
global_titlebar_enabled = true
user_wibar_enabled = true
user_titlebars_enabled = true

-- Theme and Background
beautiful.init("~/.config/awesome/themes/default.lua")
beautiful.useless_gap = padding
beautiful.gap_single_client = true

awful.layout.suit.tile.left.gap_screen_edge = false
awful.layout.suit.tile.top.gap_screen_edge = false

-- {{{ Border Settings
-- Width of the border (in pixels). 
-- 3 is usually thick enough to be clearly visible.
beautiful.border_width = 1

-- The color of the window currently in focus (Orange to match your tags)
beautiful.border_focus  = "#00ffff" 

-- The color of windows NOT in focus (Dark Grey or Black)
beautiful.border_normal = "#333333" 
-- }}}

-- This is used later as the default terminal and editor to run.
terminal = "alacritty"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.

modkey = "Mod4"

awful.spawn.with_shell("picom -b")

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.floating,
    -- awful.layout.suit.tile,
    -- awful.layout.suit.tile.left,
    -- awful.layout.suit.tile.bottom,
    -- awful.layout.suit.tile.top,
    -- awful.layout.suit.fair,
    -- awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    -- awful.layout.suit.max.fullscreen,
    -- awful.layout.suit.magnifier,
    -- awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
   { "hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", function() awesome.quit() end },
}

local menu_awesome = { "awesome", myawesomemenu, beautiful.awesome_icon }
local menu_terminal = { "open terminal", terminal }

if has_fdo then
    mymainmenu = freedesktop.menu.build({
        before = { menu_awesome },
        after =  { menu_terminal }
    })
else
    mymainmenu = awful.menu({
        items = {
                  menu_awesome,
                  { "Debian", debian.menu.Debian_menu.Debian },
                  menu_terminal,
                }
    })
end


mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock()

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

local tasklist_buttons = gears.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  c:emit_signal(
                                                      "request::activate",
                                                      "tasklist",
                                                      {raise = true}
                                                  )
                                              end
                                          end),
                     awful.button({ }, 3, function()
                                              awful.menu.client_list({ theme = { width = 250 } })
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))
-- {{{ Smart Wibar and Titlebar Visibility

-- Function to check if the Wibar should be visible
local function update_wibar_visibility(s)
    s = s or awful.screen.focused()
    
    -- 1. MASTER CHECK: If user manually disabled it, KEEP IT HIDDEN.
    if not global_wibar_enabled then
        if s.mywibox then s.mywibox.visible = false end
        return
    end

    -- 2. FULLSCREEN CHECK: If user enabled it, only hide for fullscreen.
    local is_fullscreen = false
    for _, c in ipairs(s.clients) do
        if c.fullscreen and c:isvisible() then
            is_fullscreen = true
            break
        end
    end
    
    if s.mywibox then
        -- Visible if NO window is fullscreen
        s.mywibox.visible = not is_fullscreen
    end
end

-- Function to check if a specific client should have a Titlebar
local function update_client_titlebar(c)
    -- 1. MASTER CHECK: If user disabled titlebars, hide them.
    if not global_titlebar_enabled then
        awful.titlebar.hide(c)
        return
    end

    -- 2. FULLSCREEN CHECK: Hide if this specific client is fullscreen.
    if c.fullscreen then
        awful.titlebar.hide(c)
    else
        awful.titlebar.show(c)
    end
end

-- SIGNALS: Trigger these checks automatically

-- When a window changes fullscreen state
client.connect_signal("property::fullscreen", function(c)
    update_client_titlebar(c)
    update_wibar_visibility(c.screen)
end)

-- When a window is managed (opened)
client.connect_signal("manage", function(c)
    update_client_titlebar(c)
    -- Small delay to allow the window to settle
    gears.timer.delayed_call(function() update_wibar_visibility(c.screen) end)
end)

-- When switching focus or tags (to ensure wibar updates)
client.connect_signal("focus", function(c) update_wibar_visibility(c.screen) end)
tag.connect_signal("property::selected", function(t) update_wibar_visibility(t.screen) end)
client.connect_signal("unmanage", function(c) update_wibar_visibility(c.screen) end)
client.connect_signal("property::minimized", function(c) update_wibar_visibility(c.screen) end)

-- }}}

-- {{{ Helper Functions for the Pill Look
local function rounded_shape(size)
    return function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, size)
    end
end

-- Wrapper to create a "Pill" container
local function build_pill(widget, bg_color)
    return wibox.widget {
        {
            {
                widget,
                layout = wibox.layout.fixed.horizontal,
                spacing = 10
            },
            left = 8,
            right = 8,
            top = 2,
            bottom = 2,
            widget = wibox.container.margin
        },
        bg = bg_color or "#1f1f1f", -- Dark grey pill background
        shape = rounded_shape(5),  -- Fully rounded ends
        widget = wibox.container.background
    }
end
-- }}}

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()

    -- Create an imagebox widget for the layout
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))

    -- Define the styling logic separately so we can run it immediately AND on updates
    local function update_tag_circle(self, c3, index, objects)
        local box = self:get_children_by_id('custom_circle')[1]
        
        if c3.selected then
            -- Active: Solid Cyan
            box.bg = "#00ffff" 
            box.border_width = 0
        elseif #c3:clients() > 0 then
            -- Occupied: Solid Grey
            box.bg = "#555555" 
            box.border_width = 0
        else
            -- Empty: Hollow Ring
            box.bg = "#ffffff" -- Transparent
            box.border_color = "#555555"
            box.border_width = 2
        end
    end

    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        layout   = {
            spacing = 10,
            layout  = wibox.layout.fixed.horizontal
        },
        widget_template = {
            {
                {
                    -- Dummy widget to give the container substance
                    widget = wibox.widget.textbox,
                    text   = "", 
                },
                id     = "custom_circle", 
                shape  = gears.shape.circle,
                widget = wibox.container.background,
                forced_height = 12,
                forced_width  = 12,
            },
            widget = wibox.container.margin,
            top = 6, 
            bottom = 6,
            left = 2,
            right = 2,
            
            create_callback = function(self, c3, index, objects)
                -- RUN IMMEDIATELY: Fixes the issue of dots not appearing on startup
                update_tag_circle(self, c3, index, objects)

                -- Add Tooltip
                awful.tooltip({
                    objects = { self },
                    timer_function = function() return c3.name end,
                })
            end,

            update_callback = function(self, c3, index, objects)
                -- RUN ON CHANGE: Updates the look when you switch tags or open windows
                update_tag_circle(self, c3, index, objects)
            end,
        },
        buttons = taglist_buttons
    }
    -- }}}

    -- {{{ Tasklist (Icons only)
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons,
        layout   = {
            spacing = 5,
            layout  = wibox.layout.fixed.horizontal
        },
        widget_template = {
            {
                {
                    {
                        -- CHANGED: Use 'icon_role' with imagebox
                        id     = "icon_role",
                        widget = wibox.widget.imagebox,
                    },
                    margins = 2, -- Space between icon and pill edge
                    widget  = wibox.container.margin,
                },
                id     = "background_role",
                widget = wibox.container.background,
            },
            bg     = "#2c2c2c", -- Background color of the individual task pill
            shape  = rounded_shape(10),
            widget = wibox.container.background,
        },
    }

    -- 1. Wrap the tasklist in your pill container and save it to a variable
    s.mytasklist_pill = build_pill(s.mytasklist)

    -- 2. Define a function to toggle visibility based on clients
    local function update_tasklist_visibility()
        local t = s.selected_tag
        if t then
            -- Get number of clients on the selected tag
            local client_count = #t:clients()
            -- Show if there is at least 1 client, hide otherwise
            s.mytasklist_pill.visible = (client_count > 0)
        else
            s.mytasklist_pill.visible = false
        end
    end

    -- 3. Connect signals to trigger the update
    -- When switching tags
    tag.connect_signal("property::selected", function(t)
        if t.screen == s then update_tasklist_visibility() end
    end)
    -- When a client is opened, closed, moved, or tagged
    client.connect_signal("manage", function(c) 
        if c.screen == s then update_tasklist_visibility() end 
    end)
    client.connect_signal("unmanage", function(c) 
        if c.screen == s then update_tasklist_visibility() end 
    end)
    client.connect_signal("tagged", function(c) 
        if c.screen == s then update_tasklist_visibility() end 
    end)
    client.connect_signal("untagged", function(c) 
        if c.screen == s then update_tasklist_visibility() end 
    end)

    -- Run once on startup to set initial state
    update_tasklist_visibility()
    -- }}}

    -- {{{ Custom Widgets based on your request

    -- 1. Middle Widget: Time
    local time_widget = wibox.widget.textclock("%H:%M")
    time_widget.font = "Sans Bold 12"
    time_widget.align = "center"
    
    -- 2. Right: Control Center (Battery, Wifi, Date)
    local control_widget = wibox.widget {
        format = "%a, %b %d", -- "Mon, Feb 02"
        widget = wibox.widget.textclock
    }

    -- 3. Right: Notification Bell (Static icon for now)
    local notif_icon = wibox.widget {
        text   = "  ",
        font   = "JetBrains Nerd Font 14",
        widget = wibox.widget.textbox
    }

    notif_icon:buttons(gears.table.join(
        awful.button({ }, 1, function() naughty.toggle() end) -- Toggle notifications if supported
    ))

    -- }}}

    -- Create the Wibar
    s.mywibox = awful.wibar({ 
        position = "top", 
        screen = s, 
        height = 40, 
        bg = "#00000000", 
        ontop = true,
        type = "dock",
        margins = { top = 4, left = 4, right = 4, bottom = 0 }
    })

    update_wibar_visibility(s)

    -- Spacing widget
    local sep = wibox.widget.textbox(" ")

    -- Add widgets to the wibox
    s.mywibox:setup {
        -- WRAPPER: This container adds the margins to the screen edges
        {
            layout = wibox.layout.align.horizontal,
            expand = "none",

            -- {{{ Left Pills
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = 5,
                build_pill(mylauncher),
                build_pill(s.mytaglist),
                -- CHANGED: Use the variable we created instead of building a new one
                s.mytasklist_pill, 
                s.mypromptbox,
            },
            -- }}}

            -- {{{ Middle Pill: Time
            {
                layout = wibox.layout.fixed.horizontal,
                build_pill(time_widget),
            },
            -- }}}

            -- {{{ Right Pills
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = 5,
                build_pill(wibox.widget.systray()),
                build_pill(wibox.widget {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = 12, -- Increase spacing slightly for text icons
                    { 
                        text = " ", 
                        font = "JetBrainsMono Nerd Font 16", 
                        widget = wibox.widget.textbox 
                    },
                    { 
                        text = " ", 
                        font = "JetBrainsMono Nerd Font 12", 
                        widget = wibox.widget.textbox 
                    },
                    control_widget
                }),
                build_pill(notif_icon),
                build_pill(s.mylayoutbox),
            },
            -- }}}
        },
        -- MARGIN SETTINGS
        top = 4,    -- Push down from top edge
        left = padding * 2,   -- Push in from left edge
        right = padding * 2,  -- Push in from right edge
        bottom = 4, 
        widget = wibox.container.margin
    }
end)

-- {{{ Mouse bindings
root.buttons(gears.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Custom "Padded Maximize" Function
local function toggle_padded_maximize(c)
    local padding = 10 -- The 10px gap you want
    
    -- If the window is "officially" maximized, turn that off first
    if c.maximized then
        c.maximized = false
    end

    if c.is_padded_maximized then
        -- RESTORE: Put it back to how it was
        c.floating = c.orig_floating or false
        
        -- Only restore geometry if it was originally floating
        if c.orig_floating and c.orig_geometry then
            c:geometry(c.orig_geometry)
        end
        
        -- Restore borders
        -- c.border_width = beautiful.border_width
        c.is_padded_maximized = false
    else
        -- MAXIMIZE: Save state and apply custom size
        c.orig_floating = c.floating
        c.orig_geometry = c:geometry()
        
        c.floating = true
        
        -- Optional: Remove border when maximized for a cleaner look
        -- c.border_width = 0 
        
        -- Calculate available space (workarea) minus the padding
        local wa = c.screen.workarea
        c:geometry({
            x = wa.x + padding,
            y = wa.y + padding,
            width = wa.width - (2 * padding),
            height = wa.height - (2 * padding)
        })
        
        c.is_padded_maximized = true
        c:raise()
    end
end
-- }}}

-- {{{ Key bindings
local titlebars_enabled = true

globalkeys = gears.table.join(
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),
    awful.key({ modkey, "Shift" }, "t",
        function()
            global_titlebar_enabled = not global_titlebar_enabled
            for _, c in ipairs(client.get()) do
                update_client_titlebar(c)
            end
        end,
        {description = "toggle all titlebars", group = "awesome"}),
    awful.key({ modkey }, "b",
        function ()
            global_wibar_enabled = not global_wibar_enabled
            for s in screen do
                update_wibar_visibility(s)
            end
        end,
        {description = "toggle wibar", group = "awesome"}),
    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end,
              {description = "show main menu", group = "awesome"}),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),

    -- Volume Keys (using amixer)
    awful.key({ }, "XF86AudioRaiseVolume", function ()
        awful.spawn("amixer sset Master 5%+")
    end, {description = "volume up", group = "hotkeys"}),

    awful.key({ }, "XF86AudioLowerVolume", function ()
        awful.spawn("amixer sset Master 5%-")
    end, {description = "volume down", group = "hotkeys"}),

    awful.key({ }, "XF86AudioMute", function ()
        awful.spawn("amixer sset Master toggle")
    end, {description = "toggle mute", group = "hotkeys"}),

    -- Brightness Keys (using brightnessctl)
    awful.key({ }, "XF86MonBrightnessUp", function ()
        awful.spawn("brightnessctl set +10%")
    end, {description = "brightness up", group = "hotkeys"}),

    awful.key({ }, "XF86MonBrightnessDown", function ()
        awful.spawn("brightnessctl set 10%-")
    end, {description = "brightness down", group = "hotkeys"}), 

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
              {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
              {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
              {description = "decrease the number of columns", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),

    awful.key({ modkey, "Control", "Shift" }, "space",
        function ()
            local tag = awful.screen.focused().selected_tag
            if tag then
                local clients = tag:clients()
                local all_floating = true

                -- Step 1: Check if ALL windows are currently floating
                for _, c in ipairs(clients) do
                    if not c.floating then
                        all_floating = false
                        break
                    end
                end

                -- Step 2: Toggle based on the result
                -- If they are ALL floating, we want to tile them (false).
                -- If even one is tiled, we want to float them all (true).
                local target_state = not all_floating

                for _, c in ipairs(clients) do
                    c.floating = target_state
                    -- Optional: Raise them so they don't get lost
                    if target_state == true then c:raise() end
                end
            end
        end,
        {description = "unfloat all visible clients", group = "layout"}),

    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                    c:emit_signal(
                        "request::activate", "key.unminimize", {raise = true}
                    )
                  end
              end,
              {description = "restore minimized", group = "client"}),

    -- Prompt
    awful.key({ modkey },            "r",     function () awful.screen.focused().mypromptbox:run() end,
              {description = "run prompt", group = "launcher"}),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end,
              {description = "lua execute prompt", group = "awesome"}),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end,
              {description = "show the menubar", group = "launcher"})
)

clientkeys = gears.table.join(
    awful.key({ modkey,           }, "f",
        function (c)
            -- Toggle the fullscreen state
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),

    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "c", function (c)
        if c.pid then
            awful.spawn("kill -9 " .. c.pid)
        end
        end, {description = "force kill", group = "client"}),

    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),

    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),

    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),

    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),

    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),

    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "(un)maximize", group = "client"}),

    awful.key({ modkey, "Shift"   }, "m",
        function (c)
            toggle_padded_maximize(c)
        end,
        {description = "maximize with 10px gap", group = "client"}),

    awful.key({ modkey, "Control" }, "m",
        function (c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end ,
        {description = "(un)maximize vertically", group = "client"}),
    awful.key({ modkey, "Shift"   }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end ,
        {description = "(un)maximize horizontally", group = "client"})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen
     }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
          "pinentry",
        },
        class = {
          "Arandr",
          "Blueman-manager",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
          "Wpa_gui",
          "veromix",
          "xtightvncviewer"},

        -- Note that the name property shown in xprop might be set slightly after creation of the client
        -- and the name shown there might not match defined rules here.
        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "ConfigManager",  -- Thunderbird's about:config.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = true }
    },

    -- Set Firefox to always map on the tag named "2" on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = "2" } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set new windows at the end (Slave) instead of the start (Master).
    if not awesome.startup then 
        awful.client.setslave(c) 
    end

    if awesome.startup
      and not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
    
    -- Optional: Explicitly focus the new window
    c:emit_signal("request::activate", "manage", {raise = true})
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
    -- If titlebars are globally disabled, hide the new one immediately
    if not global_titlebar_enabled then
        awful.titlebar.hide(c)
    end
end)

-- Remove borders if there is only one client to save space
-- screen.connect_signal("arrange", function (s)
--     local only_one = #s.tiled_clients == 1
--     for _, c in pairs(s.clients) do
--         if only_one and not c.floating then
--             c.border_width = 0
--         else
--             c.border_width = beautiful.border_width
--         end
--     end
-- end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {raise = false})
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
client.connect_signal("property::maximized", function(c)
    c.border_width = beautiful.border_width
end)
-- }}}
