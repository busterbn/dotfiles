# 🛠️ dotfiles

> Busters machine setup — one repo to go from fresh install to fully configured.

Works on **macOS** (brew) and **Debian / Raspberry Pi OS** (apt).

## 🚀 Quick start

```sh
curl -fsSL https://raw.githubusercontent.com/busterbn/dotfiles/main/bootstrap.sh | sh
```

Runs the full setup: installs git (and brew on macOS) if missing, clones the repo to `~/dotfiles`, backs up everything that will be changed into `.backup/`, and applies every make target below.

## 🧰 Scripts

| Script         | What it does                                                                                                                                                                              |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `bootstrap.sh` | Full setup: runs `install.sh`, then `make update deps font p10k git ssh` (+ `iterm2 hammerspoon macos obsidian` on macOS, run as separate make calls). Safe to rerun                        |
| `install.sh`   | Installs brew/git if missing, clones the repo, backs up everything the make targets can change into `.backup/` (files, defaults domains, git config, Obsidian config), lists the commands. The backup is only taken on the first run (guarded by `.initial_backup_done`) — reruns skip it instead of overwriting it |
| `restore.sh`   | Puts everything back from `.backup/` and removes `.initial_backup_done`. Installed packages/apps (brew, fonts, iTerm2, …) are left in place                                                 |

## 📦 Commands

| Command                                       | Description                                                                                                                                   | Platform |
| --------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| `make update`                               | Update & upgrade system packages                                                                                                              | all      |
| `make deps`                                 | Install dependencies (git, python, just, uv, ripgrep, fd, …)                                                                                 | all      |
| `make font`                                 | Install MesloLGS Nerd Font                                                                                                                    | all      |
| `make p10k`                                 | oh-my-zsh + powerlevel10k, plugins, dotfiles & terminal font                                                                                  | all      |
| `make iterm2`                               | iTerm2 + profile from`configs/iterm2/profile.json` + app defaults                                                                           | macOS    |
| `make ssh`                                  | Authorize my SSH key (+ enable Remote Login on macOS)                                                                                         | all      |
| `make git`                                  | Install global gitignore                                                                                                                      | all      |
| `make macos [section …]`                   | Apply macOS defaults (backs up old values first)                                                                                              | macOS    |
| `make hammerspoon`                          | Hammerspoon + config: new screenshots are also copied to the clipboard                                                                        | macOS    |
| `make obsidian`                             | Apply the shared Obsidian config (plugins, themes, appearance, snippets) to every known vault                                                 | macOS    |
| `make snapshot [iterm2] [macos] [obsidian]` | Save current settings back into`configs/`: iTerm2 key bindings, the macOS keyboard shortcut plists, and/or the main Obsidian vault's config | macOS    |

> **Note (`make hammerspoon`):** On first run, allow the permission prompts Hammerspoon shows
> (it needs access to `~/Downloads` to see new screenshots).

### `make macos` sections

Run everything with `make macos` (or `make macos all`), or pick sections, e.g. `make macos keyboard dock`.
Before anything is changed, the old values are saved to an executable restore script (`~/.macos-backup-<timestamp>.sh`) — run it with `sh` to roll back.

| Section                | What it does                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `keyboard`           | Fastest key repeat, shortest repeat delay, hold-to-repeat instead of accent popup, no auto-capitalization, no smart quotes/dashes, no period on double-space, no autocorrect (system + web), windows never auto-tab, Globe key does nothing, no Tab keyboard navigation                                                                                                                                                                                                                                                                                          |
| `keyboard_shortcuts` | Imports full snapshots of system keyboard shortcuts (`configs/macos/symbolichotkeys.plist`) and Services shortcuts (`configs/macos/services.plist`): almost everything disabled, Opt+Tab moves focus to next window                                                                                                                                                                                                                                                                                                                                          |
| `dock`               | Auto-hide with no delay and fast animation, icon size 68, hide recent apps, keep Spaces in fixed order, no dots under running apps, disable Quick Note hot corner, three-finger swipe down for App Exposé                                                                                                                                                                                                                                                                                                                                                       |
| `finder`             | Show all file extensions, path bar and status bar, column view by default with auto-sized columns, full POSIX path in window title, search current folder by default, new windows open in`~/Downloads`, folders open in windows instead of tabs, no extension-change warning, Finder can quit with Cmd+Q, save dialogs always open expanded, no drive icons on the desktop, hidden files stay hidden, no empty-trash confirmation, no Recent Tags in the sidebar, faster spring-loaded folders, small sidebar icons, no `.DS_Store` on network or USB drives |
| `trackpad`           | Tap to click, max tracking speed, click firmness, disable Force Click, silent clicking, two-finger secondary click, three-finger tap look up, natural scrolling, pinch zoom, smart zoom, rotate, and all More Gestures swipes (mirrored to Bluetooth trackpads)                                                                                                                                                                                                                                                                                                  |
| `mouse`              | Pointer speed 0.875                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| `screenshots`        | Save to`~/Downloads` as PNG, no floating thumbnail                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| `sound`              | No UI sound effects, no volume-change pop, alert sound Purr                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| `windowmanager`      | Tiled windows without margins, no tiling on edge drag or Option-drag, hide desktop widgets                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |

## ✨ What you get

- **Shell** — zsh with [oh-my-zsh](https://ohmyz.sh) and [powerlevel10k](https://github.com/romkatv/powerlevel10k)
- **Plugins** — autosuggestions, syntax highlighting, history substring search
- **Font** — MesloLGS Nerd Font, auto-configured in Terminal, iTerm2 and VS Code
- **Dotfiles** — `.zshrc` and `.p10k.zsh` from `configs/zsh/` (existing `.zshrc` is backed up)
- **Quiet shells** — `.hushlogin` so new terminals skip the "Last login" banner

## 📁 Layout

```
dotfiles/
├── bootstrap.sh    # full setup: install.sh + all make targets
├── install.sh      # brew/git + clone + backup into .backup/
├── restore.sh      # undo everything from .backup/
├── makefile        # all the commands
└── configs/
    ├── git/          # .gitignore_global
    ├── hammerspoon/  # init.lua
    ├── iterm2/       # profile.json, defaults.sh
    ├── macos/        # defaults.sh, keyboard shortcut snapshots
    ├── obsidian/     # sync.sh + shared vault config (plugins, themes, ...)
    └── zsh/          # .zshrc, .p10k.zsh
```
