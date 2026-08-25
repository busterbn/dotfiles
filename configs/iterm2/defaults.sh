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
