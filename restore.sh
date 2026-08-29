#!/bin/sh
# Undo bootstrap.sh: restore everything from .backup/ and remove .initial_backup_done.
# Installed packages/apps (brew, fonts, iTerm2, Hammerspoon, ...) are left in place.
set -e
cd "$(dirname "$0")"
BACKUP=".backup"

[ -d "$BACKUP" ] || { echo "No backup found ($PWD/$BACKUP missing) — nothing to restore."; exit 1; }

# Remove files/dirs that didn't exist before bootstrap
[ -f "$BACKUP/absent" ] && while read -r f; do rm -rf "$HOME/$f"; done < "$BACKUP/absent"

# Put back files that did exist
(cd "$BACKUP/files" && find . -type f) | while read -r f; do
    f=${f#./}
    mkdir -p "$(dirname "$HOME/$f")"
    cp -R "$BACKUP/files/$f" "$HOME/$f"
done

# login shell changed by `make p10k`
[ -f "$BACKUP/login-shell" ] && sudo chsh -s "$(cat "$BACKUP/login-shell")" "$USER"

# git config value set by `make git`
if [ -f "$BACKUP/git-excludesfile" ]; then
    git config --global core.excludesfile "$(cat "$BACKUP/git-excludesfile")"
else
    git config --global --unset core.excludesfile 2>/dev/null || true
fi

if [ "$(uname)" = "Darwin" ]; then
    # delete before import: import merges, so added keys would otherwise survive
    for p in "$BACKUP/defaults"/*.plist; do
        [ -e "$p" ] || continue
        d=$(basename "$p" .plist)
        defaults delete "$d" 2>/dev/null || true
        defaults import "$d" "$p"
        echo "Restored defaults: $d"
    done
    [ -f "$BACKUP/absent-defaults" ] && while read -r d; do
        defaults delete "$d" 2>/dev/null || true
    done < "$BACKUP/absent-defaults"

    # Obsidian items per vault
    if [ -d "$BACKUP/obsidian" ]; then
        ITEMS=$(cat "$BACKUP/obsidian-items")
        for b in "$BACKUP/obsidian"/*/; do
            v=$(cat "$b/path")
            [ -d "$v/.obsidian" ] || continue
            for i in $ITEMS; do
                rm -rf "$v/.obsidian/$i"
                [ -e "$b$i" ] && cp -R "$b$i" "$v/.obsidian/$i" || true
            done
        done
    fi

    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null || true
    killall Hammerspoon 2>/dev/null || true
    killall "System Settings" 2>/dev/null || true
    killall Dock Finder SystemUIServer NotificationCenter cfprefsd 2>/dev/null || true
fi

rm -f .initial_backup_done
echo "Restored from $BACKUP. Log out and back in for keyboard/trackpad/shell changes to fully apply."
