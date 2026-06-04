#!/usr/bin/env bash
set -euo pipefail

# Resolve the dotfiles repo dir so symlinks are stable regardless of CWD.
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -d ~/.config ]; then
    mkdir -p ~/.config
fi

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}";;
esac

# Install a brew formula/cask only if it isn't already present.
# Usage: brew_install <name> [extra brew args...]
brew_install() {
    local pkg="$1"; shift
    if brew list "$pkg" >/dev/null 2>&1; then
        echo "  $pkg already installed, skipping"
    else
        brew install "$@" "$pkg"
    fi
}

install_brew() {
    if ! which brew >/dev/null 2>&1; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    brew_install font-mononoki-nerd-font --cask
    brew_install neovim --HEAD   # neovim nightly
    brew_install zig
    brew_install lazygit
    brew_install uv
    brew_install stylua
    brew_install tmux

    # virtualenvwrapper.sh must be on PATH for the oh-my-zsh virtualenvwrapper
    # plugin (see plugins=() in zshrc). uv symlinks it into ~/.local/bin.
    if ! uv tool list 2>/dev/null | grep -q '^virtualenvwrapper'; then
        uv tool install virtualenvwrapper
    fi
}

install_zsh() {
    # Clone zsh plugins
    if [ ! -d ~/.oh-my-zsh ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi

    #autosuggesions plugin
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
        echo "installing zsh-autosuggestions"
        git clone https://github.com/zsh-users/zsh-autosuggestions.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    fi

    #zsh-syntax-highlighting plugin
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
        echo "installing zsh-syntax-highlighting"
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    fi

    #zsh-fast-syntax-highlighting plugin
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting" ]; then
        echo "installing fast-syntax-highlighting"
        git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting"
    fi

    #zsh-autocomplete plugin
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autocomplete" ]; then
        echo "installing zsh-autocomplete"
        git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autocomplete"
    fi
}

install_ghostty() {
    if ! which ghostty >/dev/null 2>&1; then
        echo "installing ghostty"
        brew install --cask ghostty
        rm -f ~/Library/Application\ Support/com.mitchellh.ghostty/config
        ln -s "$DOTFILES/ghostty" ~/Library/Application\ Support/com.mitchellh.ghostty/config
    fi
}

link_dotfiles() {
    # ln -sfn: force-overwrite stale/broken links and don't follow an existing
    # symlinked dir. Idempotent, so re-running always repairs links.
    mkdir -p ~/.config/alacritty

    ln -sfn "$DOTFILES/zshrc" ~/.zshrc
    ln -sfn "$DOTFILES/alias" ~/.config/alias
    ln -sfn "$DOTFILES/nvim" ~/.config/nvim
    ln -sfn "$DOTFILES/alacritty.yml" ~/.config/alacritty/alacritty.yml
    ln -sfn "$DOTFILES/tmux.conf" ~/.tmux.conf

    # Create my work alias file if it does not exist (never clobber it — it
    # holds machine-specific aliases, not a symlink into the repo).
    if [ ! -e ~/.work_alias ]; then
        touch ~/.work_alias
    fi
}

apply_mac_default() {
    defaults write com.apple.dock static-only -bool true
    killall Dock

    defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
    defaults write com.apple.finder _FXSortFoldersFirst -bool true
    killall Finder

    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
}

if [ "${machine}" = "Mac" ]; then
    install_brew
    install_zsh
    install_ghostty
    link_dotfiles
    apply_mac_default
fi
