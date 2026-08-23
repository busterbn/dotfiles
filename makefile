ifeq ($(shell uname),Darwin)
	PKG := brew
	INSTALL := brew install
	DEPS := curl git python just uv ripgrep fd
	export PATH := /opt/homebrew/bin:$(PATH)
else
	PKG := apt-get
	INSTALL := sudo apt-get install -y
	DEPS := curl git python3 python3-pip just ripgrep fd-find
endif

ZSH_CUSTOM := $(HOME)/.oh-my-zsh/custom
ITERM_GUID := 107077FF-D223-44BC-A27A-FB00E330323C
ifeq ($(PKG),brew)
	VSCODE_SETTINGS := $(HOME)/Library/Application Support/Code/User/settings.json
else
	VSCODE_SETTINGS := $(HOME)/.config/Code/User/settings.json
endif

.DEFAULT_GOAL := help
.PHONY: help update deps font p10k iterm2 ssh git macos

SSH_KEY := ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILUeG60x8YPAyKq8lHlLkWJ7PSWMA9QT1UDZDjhBsV45 bn@mac.local

help:
	@echo "Available commands:"
	@echo "  make update   - update and upgrade system packages ($(PKG))"
	@echo "  make deps     - install dependencies: $(DEPS)"
	@echo "  make font     - install MesloLGS Nerd Font"
	@echo "  make p10k     - install oh-my-zsh + powerlevel10k and dotfiles"
	@echo "  make iterm2   - install iTerm2 profile (macOS only)"
	@echo "  make ssh      - authorize bn@mac.local ssh key (+ enable Remote Login on macOS)"
	@echo "  make git      - install global gitignore"
	@echo "  make macos    - apply macOS defaults, backs up old values first"
	@echo "                  optional sections: keyboard dock finder trackpad mouse screenshots"

update:
ifeq ($(PKG),apt-get)
	sudo apt-get update && sudo apt-get upgrade -y
else
	brew update && brew upgrade
endif

deps:
	$(INSTALL) $(DEPS)
ifeq ($(PKG),apt-get)
	curl -LsSf https://astral.sh/uv/install.sh | sh
endif

font:
ifeq ($(PKG),apt-get)
	@mkdir -p $(HOME)/.local/share/fonts
	@for s in Regular Bold Italic "Bold Italic"; do \
		f="MesloLGS NF $$s.ttf"; \
		[ -f "$(HOME)/.local/share/fonts/$$f" ] || curl -fsSL -o "$(HOME)/.local/share/fonts/$$f" "https://github.com/romkatv/powerlevel10k-media/raw/master/$$(echo $$f | sed 's/ /%20/g')"; \
	done
	@command -v fc-cache >/dev/null && fc-cache -f || true
else
	brew list --cask font-meslo-lg-nerd-font >/dev/null 2>&1 || brew install --cask font-meslo-lg-nerd-font
endif

p10k: font
	@for t in git curl; do command -v $$t >/dev/null || $(INSTALL) $$t; done
ifeq ($(PKG),apt-get)
	sudo apt-get install -y zsh
	[ "$$SHELL" = "$$(which zsh)" ] || chsh -s "$$(which zsh)"
else
	osascript -e 'tell application "Terminal" to set font name of default settings to "MesloLGS-NF-Regular"' \
		-e 'tell application "Terminal" to set font size of default settings to 13'
endif
	[ -d $(HOME)/.oh-my-zsh ] || sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
	[ -d $(ZSH_CUSTOM)/themes/powerlevel10k ] || git clone https://github.com/romkatv/powerlevel10k.git $(ZSH_CUSTOM)/themes/powerlevel10k
	[ -d $(ZSH_CUSTOM)/plugins/zsh-autosuggestions ] || git clone https://github.com/zsh-users/zsh-autosuggestions $(ZSH_CUSTOM)/plugins/zsh-autosuggestions
	[ -d $(ZSH_CUSTOM)/plugins/zsh-syntax-highlighting ] || git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $(ZSH_CUSTOM)/plugins/zsh-syntax-highlighting
	[ -d $(ZSH_CUSTOM)/plugins/zsh-history-substring-search ] || git clone https://github.com/zsh-users/zsh-history-substring-search $(ZSH_CUSTOM)/plugins/zsh-history-substring-search
	@if [ -f $(HOME)/.zshrc ]; then \
		if [ -f $(HOME)/.zshrc.bak ]; then \
			cp $(HOME)/.zshrc $(HOME)/.zshrc.bak.$$(date +%Y%m%d-%H%M%S); \
		else \
			cp $(HOME)/.zshrc $(HOME)/.zshrc.bak; \
		fi \
	fi
	cp dotfiles/.zshrc $(HOME)/.zshrc
	cp dotfiles/.p10k.zsh $(HOME)/.p10k.zsh
	touch $(HOME)/.hushlogin
	@python3 -c 'import json,os,sys; p=sys.argv[1]; s=json.load(open(p)) if os.path.exists(p) else {}; s.setdefault("terminal.integrated.fontFamily","MesloLGS NF"); os.makedirs(os.path.dirname(p),exist_ok=True); json.dump(s,open(p,"w"),indent=4)' "$(VSCODE_SETTINGS)"

iterm2: font
ifneq ($(PKG),brew)
	$(error make iterm2 is macOS only)
endif
	[ -d /Applications/iTerm.app ] || brew install --cask iterm2
	mkdir -p "$(HOME)/Library/Application Support/iTerm2/DynamicProfiles"
	python3 -c 'import json,os; p=json.load(open("configs/iterm2.json")); p["Guid"]="$(ITERM_GUID)"; p["Name"]="Buster"; json.dump({"Profiles":[p]}, open(os.path.expanduser("~/Library/Application Support/iTerm2/DynamicProfiles/init.json"),"w"))'
	defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "$(ITERM_GUID)"
	touch $(HOME)/.hushlogin
	@echo "Restart iTerm2 to apply"

git:
	cp dotfiles/.gitignore_global $(HOME)/.gitignore_global
	git config --global core.excludesfile $(HOME)/.gitignore_global

macos:
ifneq ($(PKG),brew)
	$(error make macos is macOS only)
endif
	sh configs/macos.sh $(filter-out macos,$(MAKECMDGOALS))

MACOS_SECTIONS := all keyboard dock finder trackpad mouse screenshots
.PHONY: $(MACOS_SECTIONS)
$(MACOS_SECTIONS):
	@:

ssh:
	mkdir -p $(HOME)/.ssh
	grep -qxF "$(SSH_KEY)" $(HOME)/.ssh/authorized_keys 2>/dev/null || echo "$(SSH_KEY)" >> $(HOME)/.ssh/authorized_keys
	chmod 700 $(HOME)/.ssh && chmod 600 $(HOME)/.ssh/authorized_keys
ifeq ($(PKG),brew)
	sudo systemsetup -setremotelogin on
endif