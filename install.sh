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

install_brew() {
    if ! which brew >/dev/null 2>&1; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    brew install --cask font-mononoki-nerd-font

    # Neovim nightly
    brew install --HEAD neovim

    brew install zig
    brew install lazygit
    brew install uv
    brew install stylua
    brew install tmux
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
    if [ ! -f ~/.zshrc ]; then
        # Link new zsh file
        ln -s "$DOTFILES/zshrc" ~/.zshrc
    fi

    # Link my alias's if it does not exists
    if [ ! -f ~/.config/alias ]; then
        ln -s "$DOTFILES/alias" ~/.config/alias
    fi

    # Create my work alias's file if it does not exists
    if [ ! -f ~/.work_alias ]; then
        touch ~/.work_alias
    fi

    # Link the nvim configuration
    if [ ! -d ~/.config/nvim ]; then
        ln -s "$DOTFILES/nvim" ~/.config/nvim
    fi

    # Link my alacritty config if it does not exist
    if [ ! -f ~/.config/alacritty/alacritty.yml ]; then
        mkdir -p ~/.config/alacritty
        ln -s "$DOTFILES/alacritty.yml" ~/.config/alacritty/alacritty.yml
    fi

    # Link my tmux config if it does not exist
    if [ ! -f ~/.tmux.conf ]; then
        ln -s "$DOTFILES/tmux.conf" ~/.tmux.conf
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
    install_zsh
    install_brew
    link_dotfiles
    install_ghostty
    apply_mac_default
fi
