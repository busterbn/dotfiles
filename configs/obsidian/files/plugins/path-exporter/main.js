// Exports the current selection as an absolute path to ~/.obsidian-selection,
// for Hammerspoon's folder-aware launchers. The most recent action wins:
// clicking a file/folder in the file explorer, or opening a note.
// Companion to configs/hammerspoon/init.lua.
const { Plugin } = require("obsidian");
const fs = require("fs");
const os = require("os");
const path = require("path");

const OUT = path.join(os.homedir(), ".obsidian-selection");

module.exports = class PathExporter extends Plugin {
    onload() {
        this.lastExplorerPath = null;

        // capture phase, so we see the click even if the explorer handles it
        this.registerDomEvent(document, "click", (evt) => {
            const el = evt.target.closest && evt.target.closest(".nav-folder-title[data-path], .nav-file-title[data-path]");
            if (!el) return;
            this.lastExplorerPath = el.getAttribute("data-path");
            this.write(this.lastExplorerPath);
        }, true);

        this.registerEvent(this.app.workspace.on("file-open", (f) => {
            if (f) this.write(f.path);
        }));

        // Cmd+Delete deletes the last-clicked explorer item, same flow as
        // right-click -> Delete (only while the explorer has focus, so the
        // editor keeps its normal Cmd+Backspace behavior)
        this.addCommand({
            id: "delete-explorer-selection",
            name: "Delete selected file or folder",
            hotkeys: [{ modifiers: ["Mod"], key: "Backspace" }],
            checkCallback: (checking) => {
                const explorer = this.app.workspace.getLeavesOfType("file-explorer")[0];
                const focused = explorer && explorer.view.containerEl.contains(document.activeElement);
                const file = this.lastExplorerPath &&
                    this.app.vault.getAbstractFileByPath(this.lastExplorerPath);
                if (!focused || !file) return false;
                if (!checking) {
                    if (this.app.fileManager.promptForDeletion)
                        this.app.fileManager.promptForDeletion(file);
                    else
                        this.app.vault.trash(file, true);
                }
                return true;
            },
        });
    }

    write(rel) {
        try {
            fs.writeFileSync(OUT, path.join(this.app.vault.adapter.basePath, rel === "/" ? "" : rel));
        } catch (e) { /* read-only fs etc. — just skip */ }
    }
};
