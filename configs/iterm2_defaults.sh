#!/bin/sh
# iTerm2 app settings — run via `make iterm2` ($1 = profile guid, passed by the Makefile).
# The profile itself (colors, font, ...) lives in iterm2.json as a dynamic profile.
set -e

# Use the dynamic profile as default
[ -n "$1" ] && defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "$1"
# Open files/folders (e.g. from Finder via Alt+Space) in new windows, not new tabs
defaults write com.googlecode.iterm2 OpenFileInNewWindows -bool true
