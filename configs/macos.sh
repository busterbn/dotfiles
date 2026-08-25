#!/bin/sh
# macOS defaults — run via `make macos [section ...]`
# Sections: keyboard keyboard_shortcuts dock finder trackpad mouse screenshots sound windowmanager (default: all)
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
    # Fast key repeat rate
    set_default NSGlobalDomain KeyRepeat int 2
    # Short delay before key repeat starts
    set_default NSGlobalDomain InitialKeyRepeat int 15
    # Hold a key to repeat it instead of showing the accent popup
    set_default NSGlobalDomain ApplePressAndHoldEnabled bool false
    # No automatic capitalization
    set_default NSGlobalDomain NSAutomaticCapitalizationEnabled bool false
    # No smart quotes
    set_default NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled bool false
    # No smart dashes
    set_default NSGlobalDomain NSAutomaticDashSubstitutionEnabled bool false
    # No period on double-space
    set_default NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled bool false
    # No autocorrect
    set_default NSGlobalDomain NSAutomaticSpellingCorrectionEnabled bool false
    # No autocorrect in web text fields
    set_default NSGlobalDomain WebAutomaticSpellingCorrectionEnabled bool false
    # Never auto-tab new windows, only manually
    set_default NSGlobalDomain AppleWindowTabbingMode string manual
    # Globe key does nothing (0=nothing 1=input source 2=emoji 3=dictation)
    set_default com.apple.HIToolbox AppleFnUsageType int 0
    # No full keyboard navigation with Tab
    set_default NSGlobalDomain AppleKeyboardUIMode int 0
}

keyboard_shortcuts() {
    # Full snapshot of System Settings > Keyboard > Keyboard Shortcuts: almost every
    # system shortcut disabled, Opt+Tab = move focus to next window. Not backed up.
    # Refresh the snapshot with: defaults export com.apple.symbolichotkeys configs/symbolichotkeys.plist
    defaults import com.apple.symbolichotkeys "$(dirname "$0")/symbolichotkeys.plist"
    # Same for the Services menu shortcuts (all disabled), stored in the pbs domain.
    # Refresh with: defaults export pbs configs/services.plist
    defaults import pbs "$(dirname "$0")/services.plist"
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null \
        || echo "note: could not apply hotkey changes live, log out and back in to apply"
}

dock() {
    # Auto-hide the dock
    set_default com.apple.dock autohide bool true
    # Show the hidden dock immediately on hover
    set_default com.apple.dock autohide-delay float 0
    # Dock icon size
    set_default com.apple.dock tilesize int 68
    # Don't show recent apps in the dock
    set_default com.apple.dock show-recents bool false
    # Faster hide/show animation
    set_default com.apple.dock autohide-time-modifier float 0.4
    # Don't rearrange Spaces by most recent use
    set_default com.apple.dock mru-spaces bool false
    # No indicator dots under running apps
    set_default com.apple.dock show-process-indicators bool false
    # Disable the bottom-right Quick Note hot corner
    set_default com.apple.dock wvous-br-corner int 1
    # Swipe down with three fingers for App Expose
    set_default com.apple.dock showAppExposeGestureEnabled bool true
    # Mission Control and Show Desktop gestures on
    set_default com.apple.dock showMissionControlGestureEnabled bool true
    set_default com.apple.dock showDesktopGestureEnabled bool true
}

finder() {
    # Always show file extensions
    set_default NSGlobalDomain AppleShowAllExtensions bool true
    # Show the path bar at the bottom of Finder windows
    set_default com.apple.finder ShowPathbar bool true
    # Column view as default
    set_default com.apple.finder FXPreferredViewStyle string clmv
    # Auto-resize columns to fit the longest filename
    set_default com.apple.finder _FXEnableColumnAutoSizing bool true
    # Don't create .DS_Store files on network drives or USB drives
    set_default com.apple.desktopservices DSDontWriteNetworkStores bool true
    set_default com.apple.desktopservices DSDontWriteUSBStores bool true
    # Show status bar (item count and free space)
    set_default com.apple.finder ShowStatusBar bool true
    # Full POSIX path in window title
    set_default com.apple.finder _FXShowPosixPathInTitle bool true
    # Search the current folder by default
    set_default com.apple.finder FXDefaultSearchScope string SCcf
    # New windows open in Downloads
    set_default com.apple.finder NewWindowTarget string PfLo
    set_default com.apple.finder NewWindowTargetPath string "file://$HOME/Downloads/"
    # Open folders in new windows instead of tabs
    set_default com.apple.finder FinderSpawnTab bool false
    # Allow quitting Finder with Cmd+Q
    set_default com.apple.finder QuitMenuItem bool true
    # No warning when changing a file extension
    set_default com.apple.finder FXEnableExtensionChangeWarning bool false
    # Save dialogs always open expanded with the folder tree
    set_default NSGlobalDomain NSNavPanelExpandedStateForSaveMode bool true
    set_default NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 bool true
    # No external/removable drive icons on the desktop
    set_default com.apple.finder ShowExternalHardDrivesOnDesktop bool false
    set_default com.apple.finder ShowRemovableMediaOnDesktop bool false
    # Don't show hidden files (toggle per window with Cmd+Shift+.)
    set_default com.apple.finder AppleShowAllFiles bool false
    # No confirmation when emptying the trash
    set_default com.apple.finder WarnOnEmptyTrash bool false
    # No "Recent Tags" in the sidebar
    set_default com.apple.finder ShowRecentTags bool false
    # Faster spring-loaded folders when dragging
    set_default NSGlobalDomain com.apple.springing.delay float 0.2
    # Small sidebar icons (1-3 = small/medium/large)
    set_default NSGlobalDomain NSTableViewDefaultSizeMode int 1
}

trackpad() {
    # Tap to click
    set_default com.apple.AppleMultitouchTrackpad Clicking bool true
    # Max tracking speed (0-3)
    set_default NSGlobalDomain com.apple.trackpad.scaling float 3
    # Medium click firmness (0/1/2 = light/medium/firm)
    set_default com.apple.AppleMultitouchTrackpad FirstClickThreshold int 0
    set_default com.apple.AppleMultitouchTrackpad SecondClickThreshold int 0
    # Disable Force Click (both keys are the same setting, seen from driver and system)
    set_default com.apple.AppleMultitouchTrackpad ForceSuppressed bool true
    set_default NSGlobalDomain com.apple.trackpad.forceClick bool false
    # No haptic click feedback (silent clicking)
    set_default com.apple.AppleMultitouchTrackpad ActuateDetents int 0
    # Secondary click with two fingers (not corner click)
    set_default com.apple.AppleMultitouchTrackpad TrackpadRightClick bool true
    set_default com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick int 0
    # Look up & data detectors on three-finger tap
    set_default com.apple.AppleMultitouchTrackpad TrackpadThreeFingerTapGesture int 2
    # Natural scrolling
    set_default NSGlobalDomain com.apple.swipescrolldirection bool true
    # Pinch to zoom
    set_default com.apple.AppleMultitouchTrackpad TrackpadPinch bool true
    # Smart zoom on two-finger double-tap
    set_default com.apple.AppleMultitouchTrackpad TrackpadTwoFingerDoubleTapGesture int 1
    # Rotate with two fingers
    set_default com.apple.AppleMultitouchTrackpad TrackpadRotate bool true
    # Swipe between pages by scrolling left/right with two fingers
    set_default NSGlobalDomain AppleEnableSwipeNavigateWithScrolls bool true
    # Swipe between full-screen apps with three fingers
    set_default com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture int 2
    # Notification Center: swipe left from the right edge with two fingers
    set_default com.apple.AppleMultitouchTrackpad TrackpadTwoFingerFromRightEdgeSwipeGesture int 3
    # Mission Control up / App Expose down with three fingers
    set_default com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture int 2
    # Show Desktop: spread with thumb and three fingers
    set_default com.apple.AppleMultitouchTrackpad TrackpadFourFingerPinchGesture int 2
    set_default com.apple.AppleMultitouchTrackpad TrackpadFiveFingerPinchGesture int 2
    # Mirror to external (Bluetooth) trackpads
    set_default com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking bool true
    set_default com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick bool true
    set_default com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerTapGesture int 2
    set_default com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadPinch bool true
    set_default com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadTwoFingerDoubleTapGesture int 1
    set_default com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRotate bool true
    set_default com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerHorizSwipeGesture int 2
    set_default com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadTwoFingerFromRightEdgeSwipeGesture int 3
    set_default com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerVertSwipeGesture int 2
    set_default com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerPinchGesture int 2
    set_default com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFiveFingerPinchGesture int 2
}

mouse() {
    # Mouse tracking speed
    set_default NSGlobalDomain com.apple.mouse.scaling float 0.875
}

screenshots() {
    # Save screenshots to Downloads
    set_default com.apple.screencapture location string "$HOME/Downloads"
    # Save as png
    set_default com.apple.screencapture type string png
    # No floating thumbnail, save immediately
    set_default com.apple.screencapture show-thumbnail bool false
}

sound() {
    # No UI sound effects (trash, screenshots, etc.)
    set_default NSGlobalDomain com.apple.sound.uiaudio.enabled int 0
    # No pop sound when changing volume
    set_default NSGlobalDomain com.apple.sound.beep.feedback int 0
    # Alert sound: Purr
    set_default NSGlobalDomain com.apple.sound.beep.sound string /System/Library/Sounds/Purr.aiff
}

windowmanager() {
    # Tiled windows without margins
    set_default com.apple.WindowManager EnableTiledWindowMargins bool false
    # Don't tile windows when dragged to screen edges
    set_default com.apple.WindowManager EnableTilingByEdgeDrag bool false
    set_default com.apple.WindowManager EnableTopTilingByEdgeDrag bool false
    # No Option-drag tiling
    set_default com.apple.WindowManager EnableTilingOptionAccelerator bool false
    # Hide desktop widgets
    set_default com.apple.WindowManager StandardHideWidgets bool true
}

ALL="keyboard keyboard_shortcuts dock finder trackpad mouse screenshots sound windowmanager"
{ [ $# -eq 0 ] || [ "$1" = all ]; } && set -- $ALL
for section in "$@"; do
    echo "» $section"
    $section
done

killall Dock Finder SystemUIServer 2>/dev/null || true
echo "Done. Restore old settings with: sh $BACKUP"
