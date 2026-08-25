-- Hammerspoon config — installed to ~/.hammerspoon/init.lua via `make hammerspoon`

-- Copy new screenshots in ~/Downloads to the clipboard (they still land as files too)
local downloads = os.getenv("HOME") .. "/Downloads"
screenshotWatcher = hs.pathwatcher.new(downloads, function(files, flags)
    for i, file in ipairs(files) do
        if file:match("/Screenshot[^/]*%.png$") and (flags[i].itemCreated or flags[i].itemRenamed) then
            local img = hs.image.imageFromPath(file)
            if img then hs.pasteboard.writeObjects(img) end
        end
    end
end):start()

-- Shortcuts
-- App launchers focus the app, or hide it if it's already in front.
-- `name` is the running process name; `launchTarget` the launch name/path if it differs.
local function toggle(name, launchTarget)
    return function()
        local app = hs.application.get(name)
        if app and app:isFrontmost() then
            app:hide()
        else
            hs.application.launchOrFocus(launchTarget or name)
        end
    end
end

local function toggleDarkMode()
    hs.osascript.applescript('tell application "System Events" to tell appearance preferences to set dark mode to not dark mode')
end

-- Cmd+E hides the current app (sends Cmd+H)
hs.hotkey.bind({"cmd"}, "e", function() hs.eventtap.keyStroke({"cmd"}, "h") end)

-- Toggle dark mode with Cmd+F5 or Cmd+moon key (raw keycode 178)
hs.hotkey.bind({"cmd"}, "f5", toggleDarkMode)
hs.hotkey.bind({"cmd"}, 178, toggleDarkMode)

-- App launchers
hs.hotkey.bind({"alt", "cmd"}, "space", toggle("Finder"))
hs.hotkey.bind({"alt"}, "space", toggle("iTerm2", "iTerm"))

-- Fn+key launchers: "fn" is not a real modifier in hs.hotkey, so use an eventtap
local fnApps = {
    m = toggle("fMessenger", os.getenv("HOME") .. "/Applications/fMessenger.app"),
    n = toggle("Messages"),
    o = toggle("Obsidian"),
}
fnLauncher = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(e)
    local flags = e:getFlags()
    if not (flags.fn and not flags.cmd and not flags.alt and not flags.ctrl and not flags.shift) then
        return false
    end
    local fn = fnApps[hs.keycodes.map[e:getKeyCode()]]
    if not fn then return false end
    fn()
    return true
end):start()

-- Window snapping on Caps Lock (Loop replacement)
-- Caps Lock is remapped to F18 with hidutil (not persistent across reboots,
-- but this config runs at every login since Hammerspoon starts at login).
hs.execute([[hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x70000006D}]}']])
hs.window.animationDuration = 0

-- Repeated presses cycle through the positions, Loop-style ({x, y, w, h} in screen units)
local cycles = {
    a = {{0, 0, 1/2, 1}, {0, 0, 2/3, 1}, {0, 0, 3/4, 1}, {0, 0, 1/4, 1}, {0, 0, 1/3, 1}},
    d = {{1/2, 0, 1/2, 1}, {1/3, 0, 2/3, 1}, {1/4, 0, 3/4, 1}, {3/4, 0, 1/4, 1}, {2/3, 0, 1/3, 1}},
    s = {{1/3, 0, 1/3, 1}, {1/4, 0, 1/2, 1}, {0.2, 0, 0.6, 1}, {0.15, 0, 0.7, 1}, {0.1, 0, 0.8, 1}, {0.05, 0, 0.9, 1}},
}
-- Two direction keys within 0.35s = quarter of the screen
local quarters = {
    wa = {0, 0, 1/2, 1/2}, wd = {1/2, 0, 1/2, 1/2},
    as = {0, 1/2, 1/2, 1/2}, sd = {1/2, 1/2, 1/2, 1/2},
}

local snapState = {} -- per window id: {key, idx, time, restore}

local function snapPress(key)
    local win = hs.window.focusedWindow()
    if not win then return end
    local st = snapState[win:id()] or {}
    local now = hs.timer.secondsSinceEpoch()

    if st.key and now - (st.time or 0) < 0.35 then
        local q = quarters[st.key .. key] or quarters[key .. st.key]
        if q then
            win:moveToUnit({x = q[1], y = q[2], w = q[3], h = q[4]})
            snapState[win:id()] = {key = key, time = now}
            return
        end
    end

    if key == "w" then -- maximize, press again to restore the previous frame
        if st.key == "w" and st.restore then
            win:setFrame(st.restore)
            snapState[win:id()] = {key = key, time = now}
        else
            local restore = win:frame()
            win:maximize()
            snapState[win:id()] = {key = key, time = now, restore = restore}
        end
        return
    end

    local idx = (st.key == key and st.idx) and (st.idx % #cycles[key]) + 1 or 1
    local u = cycles[key][idx]
    win:moveToUnit({x = u[1], y = u[2], w = u[3], h = u[4]})
    snapState[win:id()] = {key = key, idx = idx, time = now}
end

snap = hs.hotkey.modal.new()
hs.hotkey.bind({}, "f18", function() snap:enter() end, function() snap:exit() end)
for _, key in ipairs({"w", "a", "s", "d"}) do
    snap:bind({}, key, function() snapPress(key) end)
end
snap:bind({}, "q", function()
    local win = hs.window.focusedWindow()
    if win then win:moveToScreen(win:screen():previous()) end
end)
snap:bind({}, "e", function()
    local win = hs.window.focusedWindow()
    if win then win:moveToScreen(win:screen():next()) end
end)

-- noTunes replacement: if Apple Music tries to launch (play/pause key,
-- AirPods connect, ...), kill it and open Spotify instead
musicWatcher = hs.application.watcher.new(function(name, event, app)
    if event == hs.application.watcher.launching and name == "Music" then
        app:kill9()
        hs.application.launchOrFocus("Spotify")
    end
end):start()

-- Mute when audio output falls back from Bluetooth (headphones/speaker disconnected)
local lastTransport = hs.audiodevice.defaultOutputDevice():transportType()
hs.audiodevice.watcher.setCallback(function(event)
    if event ~= "dOut" then return end
    local out = hs.audiodevice.defaultOutputDevice()
    if lastTransport == "Bluetooth" and out:transportType() ~= "Bluetooth" then
        out:setMuted(true)
    end
    lastTransport = out:transportType()
end)
hs.audiodevice.watcher.start()

hs.notify.show("Hammerspoon", "", "Config loaded")
