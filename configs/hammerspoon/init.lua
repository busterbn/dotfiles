-- Hammerspoon config — installed to ~/.hammerspoon/init.lua via `make hammerspoon`

require("hs.ipc") -- enables the `hs` CLI (debugging: hs -c "<lua>")

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
-- Folder context of the frontmost app: Finder's front window folder, or the
-- folder of the file/folder selected in Obsidian (exported to
-- ~/.obsidian-selection by the path-exporter plugin)
local function contextPath()
    local front = hs.application.frontmostApplication():name()
    if front == "Finder" then
        local ok, path = hs.osascript.applescript(
            'tell application "Finder" to get POSIX path of (target of front window as alias)')
        return ok and path or nil
    end
    if front == "Obsidian" then
        local f = io.open(os.getenv("HOME") .. "/.obsidian-selection")
        if not f then return nil end
        local p = f:read("*l")
        f:close()
        local attrs = p and hs.fs.attributes(p)
        if not attrs then return nil end
        return attrs.mode == "directory" and p or p:match("(.*)/")
    end
end

-- Cmd+Alt+Space: toggle Finder — but in VS Code, reveal the selected file in
-- Finder (via VS Code's own Cmd+Alt+R binding), and in Obsidian, open the
-- selected folder in Finder
local toggleFinder = toggle("Finder")
hs.hotkey.bind({"alt", "cmd"}, "space", function()
    local front = hs.application.frontmostApplication():name()
    if front == "Obsidian" and contextPath() then
        hs.execute('open "' .. contextPath() .. '"')
    elseif front == "Code" then
        hs.eventtap.keyStroke({"cmd", "alt"}, "r")
        -- nothing to reveal (no selection/active file) -> Finder never came
        -- to the front, so fall back to the normal toggle
        hs.timer.doAfter(0.4, function()
            if hs.application.frontmostApplication():name() == "Code" then toggleFinder() end
        end)
    else
        toggleFinder()
    end
end)
-- Toggle the app — but with a folder context in front (Finder or Obsidian),
-- open that folder in the app instead
-- (openFolder overrides how the folder is opened; default is `open -a`)
local function toggleOrOpenFolder(name, launchTarget, openFolder)
    local toggleApp = toggle(name, launchTarget)
    return function()
        local path = hs.application.frontmostApplication():name() ~= name and contextPath() or nil
        if not path then
            toggleApp()
        elseif openFolder then
            openFolder(path)
        else
            hs.execute('open -a "' .. (launchTarget or name) .. '" "' .. path .. '"')
        end
    end
end

hs.hotkey.bind({"alt"}, "space", toggleOrOpenFolder("iTerm2", "iTerm"))

-- Fn+key launchers: "fn" is not a real modifier in hs.hotkey, so use an eventtap
local fnApps = {
    c = toggleOrOpenFolder("Code", "Visual Studio Code"),
    m = toggle("fMessenger", os.getenv("HOME") .. "/Applications/fMessenger.app"),
    n = toggle("Messages"),
    -- obsidian://open only works for paths inside a known vault, so unknown
    -- folders are first registered as vaults in obsidian.json — Obsidian only
    -- reads that list at startup, so it gets restarted when we add one
    o = toggleOrOpenFolder("Obsidian", nil, function(path)
        path = path:gsub("(.)/$", "%1")
        local file = os.getenv("HOME") .. "/Library/Application Support/obsidian/obsidian.json"
        local cfg = hs.json.read(file) or {}
        cfg.vaults = cfg.vaults or {}
        local known = false
        for _, v in pairs(cfg.vaults) do
            if path == v.path or path:sub(1, #v.path + 1) == v.path .. "/" then known = true end
        end
        local function openVault()
            hs.execute('open "obsidian://open?path=' .. hs.http.encodeForQuery(path) .. '"')
        end
        if not known then
            cfg.vaults[hs.hash.MD5(path):sub(1, 16)] = {path = path, ts = os.time() * 1000}
            hs.json.write(cfg, file, false, true)
        end
        local app = hs.application.get("Obsidian")
        if not known and app then
            app:kill()
            hs.timer.waitUntil(function() return not hs.application.get("Obsidian") end, openVault, 0.1)
        else
            openVault()
        end
    end),
}
fnLauncher = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(e)
    local flags = e:getFlags()
    if not (flags.fn and not flags.cmd and not flags.alt and not flags.ctrl and not flags.shift) then
        return false
    end
    local fn = fnApps[hs.keycodes.map[e:getKeyCode()]]
    if not fn then return false end
    -- run outside the callback: a slow action (AppleScript etc.) would make
    -- macOS silently disable this eventtap
    hs.timer.doAfter(0, fn)
    return true
end):start()

-- macOS disables eventtaps whose callbacks stall; quietly turn ours back on
tapGuard = hs.timer.doEvery(10, function()
    if not fnLauncher:isEnabled() then fnLauncher:start() end
    if not snapTap:isEnabled() then snapTap:start() end
end)

-- Window snapping on Caps Lock (Loop replacement)
-- Caps Lock is remapped to RIGHT Ctrl with hidutil, so holding Caps IS holding Ctrl
-- (Caps+Tab cycles tabs natively, Caps+click right-clicks, etc.). The snapping keys
-- below only react to right Ctrl, so the physical (left) Ctrl key is unaffected.
-- The remap isn't persistent across reboots, but this config runs at every login.
hs.execute([[hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E4}]}']])
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

local snapKeys = { w = true, a = true, s = true, d = true, q = true, e = true }
snapTap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(e)
    if e:rawFlags() & hs.eventtap.event.rawFlagMasks.deviceRightControl == 0 then
        return false
    end
    local key = hs.keycodes.map[e:getKeyCode()]
    if not snapKeys[key] then return false end
    if e:getProperty(hs.eventtap.event.properties.keyboardEventAutorepeat) ~= 0 then
        return true -- swallow key repeat so holding a key doesn't spin the cycle
    end
    local win = hs.window.focusedWindow()
    if key == "q" then
        if win then win:moveToScreen(win:screen():previous()) end
    elseif key == "e" then
        if win then win:moveToScreen(win:screen():next()) end
    else
        snapPress(key)
    end
    return true
end):start()

-- Default window sizes: every new standard window opens at defaultSize
-- unless its app has an override ({x, y, w, h} in screen units, same
-- convention as the snapping cycles above)
local defaultSize = {0.05, 0, 0.9, 1}         -- on the built-in display
local defaultSizeExternal = {0.1, 0, 0.8, 1}  -- on Studio Display & other externals
local appSizes = {
    ["Finder"] = {0.15, 0, 0.7, 1},
}
sizeFilter = hs.window.filter.new()
-- iTerm2 sizes itself via Columns/Rows in its profile, so leave it alone
sizeFilter:rejectApp("iTerm2")
sizeFilter:subscribe(hs.window.filter.windowCreated, function(win, appName)
    if not win:isStandard() then return end
    if appName == "System Settings" then
        -- fixed-width window: keep its width, center it, full height
        local f, s = win:frame(), win:screen():frame()
        win:setFrame({x = s.x + (s.w - f.w) / 2, y = s.y, w = f.w, h = s.h})
        return
    end
    local builtin = (win:screen():name() or ""):find("Built%-in")
    local u = appSizes[appName] or (builtin and defaultSize or defaultSizeExternal)
    win:moveToUnit({x = u[1], y = u[2], w = u[3], h = u[4]})
end)

-- Any app activated without a window (Cmd+Tab, launchers, ...) gets one:
-- "reopen" is what a Dock click sends — the app opens its default window
-- if it has none, and does nothing otherwise
reopenWatcher = hs.application.watcher.new(function(name, event, app)
    if event ~= hs.application.watcher.activated then return end
    hs.timer.doAfter(0.15, function()
        if app:isFrontmost() and app:mainWindow() == nil and app:bundleID() then
            hs.osascript.applescript('tell application id "' .. app:bundleID() .. '" to reopen')
        end
    end)
end):start()

-- noTunes replacement: if Apple Music tries to launch (play/pause key,
-- AirPods connect, ...), kill it and open Spotify instead
musicWatcher = hs.application.watcher.new(function(name, event, app)
    if event == hs.application.watcher.launching and name == "Music" then
        app:kill9()
        hs.application.launchOrFocus("Spotify")
    end
end):start()

-- Use Studio Display speakers + mic whenever it gets connected
local function useStudioDisplay()
    local out = hs.audiodevice.findOutputByName("Studio Display Speakers")
    if out then out:setDefaultOutputDevice() end
    local mic = hs.audiodevice.findInputByName("Studio Display Microphone")
    if mic then mic:setDefaultInputDevice() end
end
local studioConnected = hs.audiodevice.findOutputByName("Studio Display Speakers") ~= nil
-- Already docked at load (e.g. at login): claim the audio only if it's on the
-- built-in devices, so a reload doesn't steal from headphones
if studioConnected and hs.audiodevice.defaultOutputDevice():transportType() == "Built-in" then
    useStudioDisplay()
end

-- Mute when audio output falls back from Bluetooth (headphones/speaker disconnected)
local lastTransport = hs.audiodevice.defaultOutputDevice():transportType()
hs.audiodevice.watcher.setCallback(function(event)
    if event == "dev#" then -- device list changed: did the Studio Display just arrive?
        local now = hs.audiodevice.findOutputByName("Studio Display Speakers") ~= nil
        if now and not studioConnected then useStudioDisplay() end
        studioConnected = now
        return
    end
    if event ~= "dOut" then return end
    local out = hs.audiodevice.defaultOutputDevice()
    if lastTransport == "Bluetooth" and out:transportType() ~= "Bluetooth" then
        out:setMuted(true)
    end
    lastTransport = out:transportType()
end)
hs.audiodevice.watcher.start()

hs.notify.show("Hammerspoon", "", "Config loaded")
