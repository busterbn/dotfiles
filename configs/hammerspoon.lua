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
local function launch(app)
    return function() hs.application.launchOrFocus(app) end
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
hs.hotkey.bind({"alt", "cmd"}, "space", launch("Finder"))

-- Fn+key launchers: "fn" is not a real modifier in hs.hotkey, so use an eventtap
local fnApps = {
    m = os.getenv("HOME") .. "/Applications/fMessenger.app",
    n = "Messages",
    o = "Obsidian",
}
fnLauncher = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(e)
    local flags = e:getFlags()
    if not (flags.fn and not flags.cmd and not flags.alt and not flags.ctrl and not flags.shift) then
        return false
    end
    local app = fnApps[hs.keycodes.map[e:getKeyCode()]]
    if not app then return false end
    hs.application.launchOrFocus(app)
    return true
end):start()

hs.notify.show("Hammerspoon", "", "Config loaded")
