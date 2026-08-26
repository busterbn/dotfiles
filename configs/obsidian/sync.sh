#!/bin/sh
# Shared Obsidian config across all vaults.
#   sync.sh snapshot - copy the main vault's config into configs/obsidian/files/
#   sync.sh apply    - mirror configs/obsidian/files/ into every known vault
# Per-vault state (workspace.json, graph.json, ...) is left alone.
set -e
cd "$(dirname "$0")"

MAIN="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian Vault"
ITEMS="app.json appearance.json community-plugins.json core-plugins.json webviewer.json plugins snippets themes"

vaults() {
    python3 -c 'import json,os; [print(v["path"]) for v in json.load(open(os.path.expanduser("~/Library/Application Support/obsidian/obsidian.json")))["vaults"].values()]'
}

case "$1" in
snapshot)
    mkdir -p files
    for i in $ITEMS; do
        rm -rf "files/$i"
        [ -e "$MAIN/.obsidian/$i" ] && cp -R "$MAIN/.obsidian/$i" "files/$i" || true
    done
    echo "Snapshotted from $MAIN"
    ;;
apply)
    vaults | while read -r v; do
        [ -d "$v/.obsidian" ] || continue
        for i in $ITEMS; do
            [ -e "files/$i" ] || continue
            rm -rf "$v/.obsidian/$i"
            cp -R "files/$i" "$v/.obsidian/$i"
        done
        echo "Applied to $v"
    done
    ;;
*)
    echo "Usage: sync.sh snapshot|apply"
    exit 1
    ;;
esac
