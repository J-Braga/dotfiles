#!/usr/bin/env bash
set -euo pipefail

# Resolve the dotfiles repo dir so symlinks are stable regardless of CWD.
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REINSTALL=false

usage() {
    cat <<EOF
Usage: ./install.sh [--reinstall]

Options:
  --reinstall   Remove managed dotfile links, shell/plugin state, and Neovim
                generated state before running the normal install.
  -h, --help    Show this help.
EOF
}

for arg in "$@"; do
    case "$arg" in
        --reinstall|-reinstall)
            REINSTALL=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg" >&2
            usage >&2
            exit 1
            ;;
    esac
done

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

load_brew_env() {
    if command -v brew >/dev/null 2>&1; then
        return
    fi

    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
}

install_brew() {
    load_brew_env

    if ! command -v brew >/dev/null 2>&1; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        load_brew_env
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

reinstall_cleanup() {
    echo "Removing managed dotfiles and generated shell/editor state..."

    rm -f ~/.zshrc ~/.tmux.conf ~/.zcompdump*
    rm -rf ~/.config/alias
    rm -rf ~/.config/alacritty
    rm -rf ~/.config/nvim

    rm -rf ~/.oh-my-zsh

    rm -rf ~/.local/share/nvim
    rm -rf ~/.local/state/nvim
    rm -rf ~/.cache/nvim

    rm -f "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
}

install_zsh() {
    # Clone zsh plugins
    if [ ! -d ~/.oh-my-zsh ]; then
        RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
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

}

link_managed_path() {
    local source="$1"
    local target="$2"

    mkdir -p "$(dirname "$target")"
    rm -rf "$target"
    ln -sfn "$source" "$target"
    echo "linked $target -> $source"
}

install_ghostty() {
    if ! command -v ghostty >/dev/null 2>&1; then
        echo "installing ghostty"
        brew install --cask ghostty
    fi

    link_managed_path "$DOTFILES/ghostty" "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
}

link_dotfiles() {
    link_managed_path "$DOTFILES/zshrc" "$HOME/.zshrc"
    link_managed_path "$DOTFILES/alias" "$HOME/.config/alias"
    link_managed_path "$DOTFILES/nvim" "$HOME/.config/nvim"
    link_managed_path "$DOTFILES/alacritty.yml" "$HOME/.config/alacritty/alacritty.yml"
    link_managed_path "$DOTFILES/tmux.conf" "$HOME/.tmux.conf"

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
    if [ "$REINSTALL" = true ]; then
        reinstall_cleanup
    fi

    link_dotfiles
    install_brew
    install_zsh
    install_ghostty
    link_dotfiles
    apply_mac_default
fi
