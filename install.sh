#!/bin/sh
# Usage: curl -fsSL https://raw.githubusercontent.com/busterbn/dotfiles/main/install.sh | sh
# Backs up everything the make targets can change into .backup/ before anything
# is applied, so restore.sh can always put the machine back. The backup is only
# taken once (guarded by .initial_backup_done) — reruns skip it instead of
# overwriting it, so the script is safe to run again.
set -e

# Wrapped in main() so `curl | sh` parses the whole script before running it —
# otherwise a child process reading stdin eats the rest of the script.
main() {

DIR="$HOME/dotfiles"

if [ "$(uname)" = "Darwin" ]; then
    if ! command -v brew >/dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" < /dev/tty
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    command -v git >/dev/null || brew install git
else
    command -v git >/dev/null && command -v make >/dev/null || \
        { sudo apt-get update && sudo apt-get install -y git make; }
fi

[ -d "$DIR/.git" ] && git -C "$DIR" pull || git clone https://github.com/busterbn/dotfiles.git "$DIR"

# --- Backup of everything the make targets can touch (first run only) ---
if [ -f "$DIR/.initial_backup_done" ]; then
    echo "Initial backup already taken — skipping (remove $DIR/.initial_backup_done to redo it)"
else
    BACKUP="$DIR/.backup"
    rm -rf "$BACKUP"
    mkdir -p "$BACKUP/files" "$BACKUP/defaults"

    backup_file() { # $1 = path relative to $HOME
        if [ -e "$HOME/$1" ]; then
            mkdir -p "$BACKUP/files/$(dirname "$1")"
            cp -R "$HOME/$1" "$BACKUP/files/$1"
        else
            echo "$1" >> "$BACKUP/absent"
        fi
    }

    backup_file .zshrc
    backup_file .p10k.zsh
    backup_file .hushlogin
    backup_file .gitignore_global
    backup_file .ssh/authorized_keys
    backup_file .hammerspoon/init.lua

    # Dirs the make targets create — removed on restore if they didn't exist before
    for d in .oh-my-zsh .hammerspoon; do
        [ -d "$HOME/$d" ] || echo "$d" >> "$BACKUP/absent"
    done

    # git config value set by `make git`
    git config --global core.excludesfile > "$BACKUP/git-excludesfile" 2>/dev/null \
        || rm -f "$BACKUP/git-excludesfile"

    # login shell, changed by `make p10k` (chsh)
    echo "$SHELL" > "$BACKUP/login-shell"

    if [ "$(uname)" = "Darwin" ]; then
        backup_file "Library/Application Support/Code/User/settings.json"
        backup_file "Library/Application Support/iTerm2/DynamicProfiles/init.json"

        # Every defaults domain touched by make iterm2 / make macos
        for domain in com.googlecode.iterm2 com.apple.symbolichotkeys pbs NSGlobalDomain \
                com.apple.dock com.apple.finder com.apple.desktopservices com.apple.HIToolbox \
                com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad \
                com.apple.screencapture com.apple.WindowManager com.apple.notificationcenterui; do
            defaults export "$domain" "$BACKUP/defaults/$domain.plist" 2>/dev/null \
                || echo "$domain" >> "$BACKUP/absent-defaults"
        done

        # Obsidian: the items configs/obsidian/sync.sh replaces, per vault
        OBSIDIAN_ITEMS="app.json appearance.json community-plugins.json core-plugins.json hotkeys.json webviewer.json plugins snippets themes"
        echo "$OBSIDIAN_ITEMS" > "$BACKUP/obsidian-items"
        if [ -f "$HOME/Library/Application Support/obsidian/obsidian.json" ]; then
            n=0
            python3 -c 'import json,os; [print(v["path"]) for v in json.load(open(os.path.expanduser("~/Library/Application Support/obsidian/obsidian.json")))["vaults"].values()]' \
            | while read -r v; do
                [ -d "$v/.obsidian" ] || continue
                n=$((n+1))
                mkdir -p "$BACKUP/obsidian/$n"
                printf '%s\n' "$v" > "$BACKUP/obsidian/$n/path"
                for i in $OBSIDIAN_ITEMS; do
                    if [ -e "$v/.obsidian/$i" ]; then
                        cp -R "$v/.obsidian/$i" "$BACKUP/obsidian/$n/$i"
                    else
                        echo "$i" >> "$BACKUP/obsidian/$n/absent"
                    fi
                done
            done
        fi
    fi

    touch "$DIR/.initial_backup_done"
    echo "Backup saved in $BACKUP — undo everything with $DIR/restore.sh"
fi

cd "$DIR"
make

}
main "$@"
