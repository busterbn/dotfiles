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

hs.notify.show("Hammerspoon", "", "Config loaded")
