#!/bin/sh
# Usage: curl -fsSL https://raw.githubusercontent.com/busterbn/dotfiles/main/install.sh | sh
set -e

DIR="$HOME/dotfiles"

if [ "$(uname)" = "Darwin" ]; then
    if ! command -v brew >/dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    command -v git >/dev/null || brew install git
else
    command -v git >/dev/null && command -v make >/dev/null || \
        { sudo apt-get update && sudo apt-get install -y git make; }
fi

[ -d "$DIR/.git" ] && git -C "$DIR" pull || git clone https://github.com/busterbn/dotfiles.git "$DIR"

cd "$DIR"
make
