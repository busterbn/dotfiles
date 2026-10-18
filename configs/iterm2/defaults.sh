#!/bin/sh
# iTerm2 app settings — run via `make iterm2` ($1 = profile guid, passed by the Makefile).
# The profile itself (colors, font, ...) lives in profile.json as a dynamic profile.
set -e

# Use the dynamic profile as default
[ -n "$1" ] && defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "$1"
# Open files/folders (e.g. from Finder via Alt+Space) in new windows, not new tabs
defaults write com.googlecode.iterm2 OpenFileInNewWindows -bool true
# Mouse wheel scrolls in alternate screen apps (less, vim, ...)
defaults write com.googlecode.iterm2 AlternateMouseScroll -bool true
# No confirmation prompt on Cmd+Q
defaults write com.googlecode.iterm2 PromptOnQuit -bool false
# Quit iTerm2 when the last window closes
defaults write com.googlecode.iterm2 QuitWhenAllWindowsClosed -bool true
# Minimal tab style
defaults write com.googlecode.iterm2 TabStyleWithAutomaticOption -int 6
# Python API server on
defaults write com.googlecode.iterm2 EnableAPIServer -bool true
# No sound/flash/haptics on Esc
defaults write com.googlecode.iterm2 SoundForEsc -bool false
defaults write com.googlecode.iterm2 VisualIndicatorForEsc -bool false
defaults write com.googlecode.iterm2 HapticFeedbackForEsc -bool false
# Terminal apps may write to the clipboard
defaults write com.googlecode.iterm2 AllowClipboardAccess -bool true
# Windows resize freely instead of snapping to character cells (plays nice with Hammerspoon)
defaults write com.googlecode.iterm2 DisableWindowSizeSnap -bool true
# Global key bindings — refresh the snapshot with: make snapshot iterm2
keymap="$(dirname "$0")/globalkeymap.plist"
if [ -f "$keymap" ]; then
    defaults write com.googlecode.iterm2 GlobalKeyMap "$(cat "$keymap")"
fi
# No Claude Code integration (the Chat/Diff/Code Review bar iTerm2 adds when claude runs):
# drop its workgroup and the Enter/Exit Workgroup triggers from every profile, and don't
# nag about repairing it. The cc-status hooks it put in ~/.claude/settings.json are not touched here.
defaults export com.googlecode.iterm2 - | python3 -c '
import plistlib, json, sys
d = plistlib.loads(sys.stdin.buffer.read())
if "Workgroups" in d:
    d["Workgroups"] = json.dumps([w for w in json.loads(d["Workgroups"]) if w.get("uniqueIdentifier") != "builtin.claudeCode"]).encode()  # stored as data, not string
for p in d.get("New Bookmarks", []):
    if "Triggers" in p:
        p["Triggers"] = [t for t in p["Triggers"] if "Workgroup" not in t.get("action", "")]
sys.stdout.buffer.write(plistlib.dumps(d))
' | defaults import com.googlecode.iterm2 -
defaults write com.googlecode.iterm2 NoSyncSuppressClaudeCodeIntegrationRepairPrompt -bool true
