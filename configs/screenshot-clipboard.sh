#!/bin/sh
# Copies the newest screenshot in ~/Downloads to the clipboard.
# Triggered by launchd (com.bn.screenshot-clipboard) whenever ~/Downloads changes.

# TEMP DEBUG
echo "HOME=$HOME user=$(id -un)"
ls "$HOME/Downloads" 2>&1 | head -3

f=$(ls -t "$HOME/Downloads"/Screenshot*.png | head -1)
echo "$(date +%T) triggered, newest: $f"
[ -n "$f" ] || exit 0

# Only react to screenshots taken just now, not other Downloads activity
age=$(( $(date +%s) - $(stat -f %m "$f") ))
echo "$(date +%T) age: ${age}s"
[ "$age" -le 5 ] || exit 0

osascript -e "set the clipboard to (read (POSIX file \"$f\") as «class PNGf»)"
echo "$(date +%T) copied to clipboard, osascript exit: $?"
