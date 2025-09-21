# Configure flake8 configuration file
if [ ! -d ~/.config ]; then
    mkdir ~/.config
fi

unameOut="$(uname -s)"
case "${unameOut}" in
	Linux*)     machine=Linux;;
	Darwin*)    machine=Mac;;
	CYGWIN*)    machine=Cygwin;;
	MINGW*)     machine=MinGw;;
	*)          machine="UNKNOWN:${unameOut}"
esac

install_tmux(){
  # Create a directory
  mkdir ~/tmux-install
  cd ~/tmux-install

  # Get the files
  curl -OL https://www.openssl.org/source/openssl-1.1.1q.tar.gz
  curl -OL https://github.com/tmux/tmux/releases/download/3.3a/tmux-3.3a.tar.gz
  curl -OL https://github.com/libevent/libevent/releases/download/release-2.1.12-stable/libevent-2.1.12-stable.tar.gz

  # Extract them
  tar xzf openssl-1.0.2l.tar.gz
  tar xzf tmux-2.3.tar.gz
  tar xzf libevent-2.0.22-stable.tar.gz

  # Compile openssl
  cd openssl-1.0.2l
  ./Configure darwin64-x86_64-cc --prefix=/usr/local --o
  make CFLAGS='-I/usr/local/ssl/include'
  make test
  sudo make install

  # Compile libevent
  cd ../libevent-2.0.22-stable
  ./configure 
  make
  sudo make install

  # Compile tmux
  cd ../tmux-3.3a
  LDFLAGS="-L/usr/local/lib" CPPFLAGS="-I/usr/local/include" LIBS="-lresolv" ./configure --prefix=/usr/local
  make
  sudo make install
  cd ~/
  rm -rf ~/tmux-install
  
}
install_stylua() {
	if [ ! -d ~/.config/linters/ ]; then
		mkdir ~/.config/linters/
		cd ~/.config/linters/ && curl -fsSLO https://github.com/JohnnyMorganz/StyLua/releases/download/v0.13.1/stylua-macos.zip
		unzip stylua-macos.zip
		rm stylua-macos.zip
		chmod +x stylua
	fi
}

#install_bun() { }

install_brew() {
    if ! which brew >/dev/null 2>&1; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    brew install font-mononoki-nerd

    brew install neovim-nightly
    
    brew install zig

    brew install lazygit

    brew install uv

}

install_zsh() {
	# Clone zsh plugins
    if [ ! -d ~/.oh-my-zsh ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi

    #autosuggesions plugin
    if [ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ]; then
        echo "installing zsh-autosuggestions"
        git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

    fi

    #zsh-syntax-highlighting plugin
    if [ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting ]; then
        echo "installing zsh-syntax-highlighting"
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    fi

    #zsh-fast-syntax-highlighting plugin
    if [ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting ]; then
        echo "installing fast-syntax-highlighting"
        git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
    fi

    #zsh-autocomplete plugin
    if [ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete ]; then
        echo "installing zsh-autocomplete"
        git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete
    fi


}

install_ghostty() {
    if ! which ghostty >/dev/null 2>&1; then
        echo "installing ghostty"
        brew install --cask ghostty
        rm ~/Library/Application\ Support/com.mitchellh.ghostty/config
        ln -s $(pwd)/ghostty ~/Library/Application\ Support/com.mitchellh.ghostty/config
    fi

}

link_dotfiles() { 
	if [ ! -f ~/.zshrc ]; then
        # Link new zsh file 
        ln -s $(pwd)/zshrc ~/.zshrc
    fi

    # Link my alias's if it does not exists
    if [ ! -f ~/.config/alias ]; then
        ln -s $(pwd)/alias ~/.config/alias
    fi

    # Create my work alias's file if it does not exists
    if [ ! -f ~/.work_alias ]; then
        touch ~/.work_alias
    fi

    # Link the nvim configuration
    if [ ! -d ~/.config/nvim ]; then
        ln -s $(pwd)/nvim ~/.config
    fi

    # Link my alacritty's if it does not exists
    if [ ! -f ~/.alacritty.toml ]; then
        ln -s $(pwd)alacritty.toml ~/.alacritty.toml
    fi

    # Link my tmux's if it does not exists
    #if [ ! -f ~/.tmux.conf ]; then
    #    ln -s $(pwd)tmux.conf ~/.tmux.conf
    #fi
}

install_python(){
	#install python version 3.10.4
	if ! [ -x "$(command -v python3.10)" ]; then
		curl -fsSLO https://www.python.org/ftp/python/3.10.4/python-3.10.4-macos11.pkg

		sudo installer -pkg python-3.10.4-macos11.pkg -target /
		rm python-3.10.4-macos11.pkg

		python3 -m pip install virtualenvwrapper virtualenv autopep8
	fi
	# if [ ! -f ~/.config/flake8 ]; then
	# 	ln -s $(pwd)/dotfiles/flake8 ~/.config/flake8
	# fi
}

#install_nvim() { }

apply_mac_default() {
    defaults write com.apple.dock static-only -bool true
    killall Dock

    defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
    killall Finder

    defaults write com.apple.finder _FXSortFoldersFirst -bool true
    killall Finder
}


if [ ${machine} == Mac ]; then
    install_zsh
    link_dotfiles
    #install_brew
    install_ghostty
    #apply_mac_default
 fi

#install_tmux
#install_lsp_on_mac
#install_nvim

