# 🛠️ dotfiles

> Busters machine setup — one repo to go from fresh install to fully configured.

Works on **macOS** (brew) and **Debian / Raspberry Pi OS** (apt).

## 🚀 Quick start

```sh
curl -fsSL https://raw.githubusercontent.com/busterbn/dotfiles/main/install.sh | sh
```

Installs git (and brew on macOS) if missing, clones the repo to `~/dotfiles` and lists the available commands.

## 📦 Commands

| Command | Description | Platform |
|---|---|---|
| `make update` | Update & upgrade system packages | all |
| `make deps` | Install dependencies (git, python, just, uv, ripgrep, fd, …) | all |
| `make font` | Install MesloLGS Nerd Font | all |
| `make p10k` | oh-my-zsh + powerlevel10k, plugins, dotfiles & terminal font | all |
| `make iterm2` | iTerm2 + profile from `configs/iterm2.json` | macOS |
| `make ssh` | Authorize my SSH key (+ enable Remote Login on macOS) | all |
| `make git` | Install global gitignore | all |
| `make macos [section …]` | Apply macOS defaults (backs up old values first) | macOS |
| `make screenclip` | Launch agent that also copies new screenshots to the clipboard | macOS |

> **Note (`make screenclip`):** The launch agent reads `~/Downloads`, which macOS blocks for background
> processes. Grant access once per machine: System Settings → Privacy & Security → **Full Disk Access**
> → `+` → press Cmd+Shift+G, enter `/bin/sh`, add it and toggle it on.

### `make macos` sections

Run everything with `make macos` (or `make macos all`), or pick sections, e.g. `make macos keyboard dock`.
Before anything is changed, the old values are saved to an executable restore script (`~/.macos-backup-<timestamp>.sh`) — run it with `sh` to roll back.

| Section | What it does |
|---|---|
| `keyboard` | Fastest key repeat, shortest repeat delay, hold-to-repeat instead of accent popup, no auto-capitalization, no smart quotes/dashes, no period on double-space, no autocorrect (system + web), windows never auto-tab |
| `dock` | Auto-hide with no delay and fast animation, icon size 68, hide recent apps, keep Spaces in fixed order, no dots under running apps, disable Quick Note hot corner, three-finger swipe down for App Exposé |
| `finder` | Show all file extensions, path bar and status bar, column view by default with auto-sized columns, full POSIX path in window title, search current folder by default, new windows open in `~/Downloads`, folders open in windows instead of tabs, no extension-change warning, Finder can quit with Cmd+Q, save dialogs always open expanded, no drive icons on the desktop, hidden files stay hidden, no empty-trash confirmation, no Recent Tags in the sidebar, faster spring-loaded folders, small sidebar icons, no `.DS_Store` on network or USB drives |
| `trackpad` | Tap to click, max tracking speed, disable Force Click |
| `mouse` | Pointer speed 0.875 |
| `screenshots` | Save to `~/Downloads` as PNG, no floating thumbnail |
| `sound` | No UI sound effects, no volume-change pop, alert sound Purr |
| `windowmanager` | Tiled windows without margins, no tiling on edge drag or Option-drag, hide desktop widgets |

## ✨ What you get

- **Shell** — zsh with [oh-my-zsh](https://ohmyz.sh) and [powerlevel10k](https://github.com/romkatv/powerlevel10k)
- **Plugins** — autosuggestions, syntax highlighting, history substring search
- **Font** — MesloLGS Nerd Font, auto-configured in Terminal, iTerm2 and VS Code
- **Dotfiles** — `.zshrc` and `.p10k.zsh` from `dotfiles/` (existing `.zshrc` is backed up)
- **Quiet shells** — `.hushlogin` so new terminals skip the "Last login" banner

## 📁 Layout

```
dotfiles/
├── makefile        # all the commands
├── dotfiles/       # .zshrc, .p10k.zsh
└── configs/        # iterm2.json profile
```
