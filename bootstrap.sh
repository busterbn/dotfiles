#!/bin/sh
# Usage: curl -fsSL https://raw.githubusercontent.com/busterbn/dotfiles/main/bootstrap.sh | sh
# Full setup: runs install.sh (deps + clone + initial backup, taken only once),
# then applies every make target. Safe to rerun. Undo with restore.sh.
set -e

# Wrapped in main() so `curl | sh` parses the whole script before running it —
# otherwise a child process reading stdin eats the rest of the script.
main() {

DIR="$HOME/dotfiles"

if [ -f "$DIR/install.sh" ]; then
    sh "$DIR/install.sh"
else
    curl -fsSL https://raw.githubusercontent.com/busterbn/dotfiles/main/install.sh | sh
fi

cd "$DIR"

# brew was installed by install.sh in a child process — put it in our PATH too
if [ "$(uname)" = "Darwin" ] && ! command -v brew >/dev/null; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

make update
make deps
make font
make p10k
make git
make ssh

# make macos must run alone: extra goals would be parsed as macos sections
if [ "$(uname)" = "Darwin" ]; then
    make iterm2
    make hammerspoon
    make macos
    make obsidian
fi

}
main "$@"
