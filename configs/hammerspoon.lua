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
