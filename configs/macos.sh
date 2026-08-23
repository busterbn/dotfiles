#!/bin/sh
# macOS defaults — run via `make macos [section ...]`
# Sections: keyboard dock finder trackpad mouse screenshots (default: all)
# Backs up current values to an executable restore script before changing anything.
set -e

BACKUP="$HOME/.macos-backup-$(date +%Y%m%d-%H%M%S).sh"
echo "#!/bin/sh" > "$BACKUP"
chmod +x "$BACKUP"

set_default() { # domain key type value
    if cur=$(defaults read "$1" "$2" 2>/dev/null); then
        echo "defaults write '$1' '$2' -$3 '$cur'" >> "$BACKUP"
    else
        echo "defaults delete '$1' '$2' 2>/dev/null" >> "$BACKUP"
    fi
    defaults write "$1" "$2" "-$3" "$4"
}

keyboard() {
    set_default NSGlobalDomain KeyRepeat int 2
    set_default NSGlobalDomain InitialKeyRepeat int 15
    set_default NSGlobalDomain ApplePressAndHoldEnabled bool false
    set_default NSGlobalDomain NSAutomaticCapitalizationEnabled bool false
    set_default NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled bool false
    set_default NSGlobalDomain NSAutomaticDashSubstitutionEnabled bool false
}

dock() {
    set_default com.apple.dock autohide bool true
    set_default com.apple.dock autohide-delay float 0
    set_default com.apple.dock tilesize int 68
    set_default com.apple.dock show-recents bool false
}

finder() {
    set_default NSGlobalDomain AppleShowAllExtensions bool true
    set_default com.apple.finder ShowPathbar bool true
    set_default com.apple.finder FXPreferredViewStyle string Nlsv
    set_default com.apple.desktopservices DSDontWriteNetworkStores bool true
}

trackpad() {
    set_default com.apple.AppleMultitouchTrackpad Clicking bool true
}

mouse() {
    set_default NSGlobalDomain com.apple.mouse.scaling float 0.875
}

screenshots() {
    set_default com.apple.screencapture location string "$HOME/Downloads"
    set_default com.apple.screencapture type string png
}

ALL="keyboard dock finder trackpad mouse screenshots"
{ [ $# -eq 0 ] || [ "$1" = all ]; } && set -- $ALL
for section in "$@"; do
    echo "» $section"
    $section
done

killall Dock Finder SystemUIServer 2>/dev/null || true
echo "Done. Restore old settings with: sh $BACKUP"
