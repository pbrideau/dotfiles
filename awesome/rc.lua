-- Standard awesome library
local gears = require("gears")
local gfs = require("gears.filesystem")

local awful = require("awful")
local vicious = require("vicious")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup").widget

local lain = require("lain")

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
-- Themes define colours, icons, and wallpapers

--beautiful.init("/usr/share/awesome/themes/default/theme.lua")
beautiful.init(gfs.get_configuration_dir().."mytheme/theme.lua")

-- This is used later as the default terminal and editor to run.
-- terminal = "x-terminal-emulator"
-- terminal = "urxvtcd"
-- terminal = "xterm -xrm 'XTerm*selectToClipboard: true'"
terminal = "xfce4-terminal"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

-- Default meta.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
meta = "Mod4"
alt  = "Mod1"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.tile,
    -- awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    -- awful.layout.suit.tile.top,
    -- awful.layout.suit.fair,
    -- awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral,
    -- awful.layout.suit.spiral.dwindle,
    -- awful.layout.suit.max,
    -- awful.layout.suit.max.fullscreen,
    -- awful.layout.suit.magnifier,
    -- awful.layout.suit.floating,
    -- bling.layout.centered
    lain.layout.centerwork
}
-- }}}

-- {{{ Helper functions
local function client_menu_toggle_fn()
    local instance = nil

    return function ()
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({ theme = { width = 250 } })
        end
    end
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "hotkeys", function() return false, hotkeys_popup.show_help end},
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", function() awesome.quit() end}
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- }}}

-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock()

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
local taglist_buttons = awful.util.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ meta }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ meta }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                    )
mytasklist = {}
local tasklist_buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() and c.first_tag then
                                                      c.first_tag:view_only()
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, client_menu_toggle_fn()),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              --if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              --if client.focus then client.focus:raise() end
                                          end))

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    -- set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(s.mytaglist)
    left_layout:add(s.mypromptbox)

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    right_layout:add(wibox.widget.systray())
    right_layout:add(mytextclock)
    right_layout:add(s.mylayoutbox)

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(s.mytasklist)
    layout:set_right(right_layout)

    s.mywibox:set_widget(layout)
end)

mywibox_bottom = {}
mywibox_bottom[1] = awful.wibar({ position = "bottom", height = "20", screen = s })
local empty_layout = wibox.layout.align.horizontal()
mywibox_bottom[1]:set_widget(empty_layout)


-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ alt, "Control" }, "h",      function () awful.tag.viewprev() awful.client.focus.byidx(1) end ),
    awful.key({ alt, "Control" }, "l",      function () awful.tag.viewnext() awful.client.focus.byidx(1) end ),
    awful.key({ alt, "Control" }, "Left",   function () awful.tag.viewprev() awful.client.focus.byidx(1) end ),
    awful.key({ alt, "Control" }, "Right",  function () awful.tag.viewnext() awful.client.focus.byidx(1) end ),
    awful.key({ alt, "Control", "Shift" }, "h",      function () awful.tag.viewprev() awful.client.focus.byidx(1) end ),
    awful.key({ alt, "Control", "Shift" }, "l",      function () awful.tag.viewnext() awful.client.focus.byidx(1) end ),
    awful.key({ alt, "Control", "Shift" }, "Left",   function () awful.tag.viewprev() awful.client.focus.byidx(1) end ),
    awful.key({ alt, "Control", "Shift" }, "Right",  function () awful.tag.viewnext() awful.client.focus.byidx(1) end ),
    awful.key({ meta,           }, "Escape", awful.tag.history.restore),

    awful.key({ meta,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ meta,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ meta,           }, "w", function () mymainmenu:show() end),

    -- Layout manipulation
    awful.key({ meta, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ meta, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ alt, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ alt, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ alt, "Control", "Shift" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ alt, "Control", "Shift" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ meta,           }, "u", awful.client.urgent.jumpto),
    awful.key({ meta,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ meta            }, "Return", function () awful.spawn(terminal) end),
    awful.key({ meta, "Control" }, "r", awesome.restart),
    awful.key({ meta, "Shift"   }, "q", awesome.quit),

    awful.key({ meta,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ meta,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ meta, "Control" }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ meta, "Control" }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ meta, alt    }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ meta, alt    }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ meta,           }, "space", function () awful.layout.inc( 1) end),
    awful.key({ meta, "Shift"   }, "space", function () awful.layout.inc(-1) end),

    awful.key({ meta, "Control" }, "n", awful.client.restore),

    -- Sound management

    --awful.key({ alt,           }, "Up",    function () awful.util.spawn_with_shell("amixer set Master playback 5%+") end),
    --awful.key({ alt,           }, "Down",  function () awful.util.spawn_with_shell("amixer set Master playback 5%-") end),
    awful.key({ alt,           }, "Up",    function () awful.util.spawn_with_shell("pactl set-sink-volume 0 +5%") end),
    awful.key({ alt,           }, "Down",  function () awful.util.spawn_with_shell("pactl set-sink-volume 0 -5%") end),
    awful.key({ meta,          }, ".",  function () awful.util.spawn_with_shell("pactl set-source-mute $(pactl info | grep 'Default Source' | awk '{print $3;}') 1") end), -- mute
    awful.key({ meta,          }, ",",  function () awful.util.spawn_with_shell("pactl set-source-mute $(pactl info | grep 'Default Source' | awk '{print $3;}') 0") end), -- unmute


    -- Prompt
    awful.key({         "Control" }, "space",     function () awful.screen.focused().mypromptbox:run() end),

    awful.key({ meta }, "x",
              function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end),
    -- Menubar
    awful.key({ meta }, "p", function() menubar.show() end),
    -- Locking
    awful.key({ meta, "Control" }, ",",         function () awful.util.spawn_with_shell("xscreensaver-command -lock") end)
)

clientkeys = awful.util.table.join(
    awful.key({ meta,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ meta, "Control" }, "c",      function (c) c:kill()                         end),
    -- duplicate for "P" key on fr-godox layout
    awful.key({ meta, "Control" }, "e",      function (c) c:kill()                         end),

    awful.key({ meta, "Control" }, "space",  awful.client.floating.toggle                     ),

    awful.key({ meta, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),

    -- default "o" is grabbed by something else in XFCE ??? Bind another key
    awful.key({ meta,           }, "o",      function (c) c:move_to_screen() end),
    awful.key({ meta,           }, "a",      function (c) c:move_to_screen() end),

    awful.key({ meta,           }, "t",      function (c) c.ontop = not c.ontop end),

    awful.key({ meta,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),

    -- all minimized clients are restored 
    awful.key({ meta, "Shift"   }, "n",      function ()
        local tag = awful.tag.selected()
        for i=1, #tag:clients() do
            tag:clients()[i].minimized=false
        end
                                                end ),

    awful.key({ meta,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
            c:raise()
        end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ "Control", alt }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end),
        awful.key({ "Control", alt, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end)
    )
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ meta }, 1, awful.mouse.client.move),
    awful.button({ meta }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
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
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen,
                     size_hints_honor = false
      }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
        },
        class = {
          "Arandr",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Wpa_gui",
          "pinentry",
          "veromix",
          "xtightvncviewer"},

        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = true }
    },{
        -- Firefox pip
        rule = { role = "PictureInPicture" },
        properties = { floating = false }
    },

    -- Set Firefox to always map on the tag named "2" on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = "2" } },

    {
        rule = { class = "MPlayer" },
        properties = { floating = true }
    },{
        rule = { class = "pinentry" },
        properties = { floating = true }
    },{
        rule = { class = "gimp" },
        properties = { floating = true }
    },{
        rule = { class = "Xfce4-terminal" },
        properties = { },
        callback = awful.client.setslave
    },{
        -- rule fot the calendar in xfce4
        rule = { class = "Wrapper" },
        properties = { floating = true }
    },{
      -- rule for fullscreen of flash window
      rule = { class = "Plugin-container" },
      properties = {
          maximized_horizontal = true,
          maximized_vertical = true
      }
    },{
        rule = {
            instance = "Navigator",
            role = "Preferences"
        },
        properties = { floating = true },
        callback = function(c) client.focus:move_to_tag(tags[awful.screen.focused()][awful.tag.getidx()], c) end
    },{
    --    rule = { instance = "Navigator", instance = "Dialog" },
    --    callback = function(c) client.focus:move_to_tag(tags[awful.screen.focused()][awful.tag.getidx()], c) end
    --},{
        rule = { instance = "Navigator" },
        properties = { screen = 1, tag = "1", maximized = false  }
    },{
        rule = { instance = "Download", role = "Manager" },
        properties = { screen = 1, tag = "1"  },
        callback = awful.client.setslave
    },{
        -- Icedove
        rule = { instance = "Mail" },
        properties = { screen = 1, tag = "3" }
    },{
        rule = { instance = "Calendar" },
        properties = { floating = true }
    },{
        rule = { class = "VirtualBox" },
        properties = { screen = 1, tag = "8", floating= true }
    },{
        rule = { class = "rdesktop" },
        properties = { screen = 1, tag = "7"  }
    },{
        rule = { class = "xfce4-panel" },
        properties = { floating = true, ontop = true  } 
    },{
        rule = { class = "Chromium" },
        properties = { maximized = false } 
    },{
        rule = { class = "libreoffice-writer" },
        properties = { maximized = false } 
    },{
        rule = { class = "libreoffice" },
        properties = { maximized = false } 
    },{
        rule = { class = "Microsoft Teams - Preview" },
        properties = { screen = 1, tag = "2"  }
    },{
        rule = { name = "Microsoft Teams Notification" },
        properties = {
           titlebars_enabled = false,
           floating = true,
           focus = false,
           draw_backdrop = false,
           skip_decoration = true,
           skip_taskbar = true,
           ontop = true,
           sticky = true
        }
    }
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- client.connect_signal("manage", function (c, startup)
--     -- Enable sloppy focus
--     c:connect_signal("mouse::enter", function(c)
--         if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
--             and awful.client.focus.filter(c) then
--             client.focus = c
--         end
--     end)
-- 
--     if not startup then
--         -- Set the windows at the slave,
--         -- i.e. put it at the end of others instead of setting it master.
--         -- awful.client.setslave(c)
-- 
--         -- Put windows in a smart way, only if they does not set an initial position.
--         if not c.size_hints.user_position and not c.size_hints.program_position then
--             awful.placement.no_overlap(c)
--             awful.placement.no_offscreen(c)
--         end
--    end

-- Add a titlebar if titlebars_enabled is set to true in the rules.
    --local titlebars_enabled = false
    --if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
--client.connect_signal("request::titlebars", function(c)
--    -- buttons for the titlebar
--    local buttons = awful.util.table.join(
--        awful.button({ }, 1, function()
--            client.focus = c
--            c:raise()
--            awful.mouse.client.move(c)
--        end),
--        awful.button({ }, 3, function()
--            client.focus = c
--            c:raise()
--            awful.mouse.client.resize(c)
--        end)
--    )
--
--    awful.titlebar(c) : setup {
--        { -- Left
--            awful.titlebar.widget.iconwidget(c),
--            buttons = buttons,
--            layout  = wibox.layout.fixed.horizontal
--        },
--        { -- Middle
--            { -- Title
--                align  = "center",
--                widget = awful.titlebar.widget.titlewidget(c)
--            },
--            buttons = buttons,
--            layout  = wibox.layout.flex.horizontal
--        },
--        { -- Right
--            awful.titlebar.widget.floatingbutton (c),
--            awful.titlebar.widget.maximizedbutton(c),
--            awful.titlebar.widget.stickybutton   (c),
--            awful.titlebar.widget.ontopbutton    (c),
--            awful.titlebar.widget.closebutton    (c),
--            layout = wibox.layout.fixed.horizontal()
--        },
--        layout = wibox.layout.align.horizontal
--    }
--end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        client.focus = c
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

function run_once(prg,arg_string,pname,screen)
    if not prg then
        do return nil end
    end

    if not pname then
       pname = prg
    end

    if not arg_string then 
        awful.util.spawn_with_shell("pgrep -f -u $USER -x '" .. pname .. "' || (" .. prg .. ")",screen)
    else
        awful.util.spawn_with_shell("pgrep -f -u $USER -x '" .. pname .. " ".. arg_string .."' || (" .. prg .. " " .. arg_string .. ")",screen)
    end
end

-- run_once("/usr/lib/lxpolkit/lxpolkit")
-- run_once("nm-applet")
-- run_once("xscreensaver", "-no-splash")
-- run_once("udiskie", "-s", "-F")
