#!/bin/sh
# Usage: curl -fsSL https://raw.githubusercontent.com/busterbn/dotfiles/main/bootstrap.sh | sh
# Full setup: runs install.sh (deps + clone + backup + .bootstrapped guard),
# then applies every make target. Undo with restore.sh.
set -e

DIR="$HOME/dotfiles"

if [ -f "$DIR/install.sh" ]; then
    sh "$DIR/install.sh"
else
    curl -fsSL https://raw.githubusercontent.com/busterbn/dotfiles/main/install.sh | sh
fi

cd "$DIR"
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
