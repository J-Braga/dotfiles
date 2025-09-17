# prompt_install() {
# 	echo "$1 is not installed. Would you like to install it? (y/n) " >&2
# 	old_stty_cfg=$(stty -g)
# 	stty raw -echo
# 	answer=$( while ! head -c 1 | grep -i '[ny]' ;do true ;done )
# 	stty $old_stty_cfg && echo
# 	if echo "$answer" | grep -iq "^y" ;then
# 		if [ ${machine} == Mac ]; then
# 			echo
# 		fi
# 	fi
# }


# check_for_python() {
# 	echo "Checking if Python3 version 3.9 is installed"
# 	if ! [ -x "$(command -v python3.10)" ]; then
# 		echo "installing python3.10"
# 		brew install python3
# 		brew upgrade python3 
# 	else
# 		echo "python3 is installed"
# 	fi
# }

# check_default_shell() {
# 	if [ -z "${SHELL##*zsh*}" ] ;then
# 			echo "Default shell is zsh."
# 	else
# 		echo -n "Default shell is not zsh. Do you want to chsh -s \$(which zsh)? (y/n)"
# 		old_stty_cfg=$(stty -g)
# 		stty raw -echo
# 		answer=$( while ! head -c 1 | grep -i '[ny]' ;do true ;done )
# 		stty $old_stty_cfg && echo
# 		if echo "$answer" | grep -iq "^y" ;then
# 			chsh -s $(which zsh)
# 		else
# 			echo "Warning: Your configuration won't work properly. If you exec zsh, it'll exec tmux which will exec your default shell which isn't zsh."
# 		fi
# 	fi
# }

# echo "We're going to do the following:"
# echo "1. Grab dependencies"
# echo "2. Check to make sure you have brew, python3, zsh, neovim, and tmux installed"
# echo "Let's get started? (y/n)"
# old_stty_cfg=$(stty -g)
# stty raw -echo
# answer=$( while ! head -c 1 | grep -i '[ny]' ;do true ;done )
# stty $old_stty_cfg
# if echo "$answer" | grep -iq "^y" ;then
# 	echo
# else
# 	echo "Quitting, nothing was changed."
# 	exit 0
# fi

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
# if [ ${machine} == Mac ]; then
# fi


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

install_npm() {
	if [ ! -x "$(command -v nvm)"]; then
		curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
	else
		if [ ! -x "$(command -v node)" ]; then
			nvm install node
		fi

		if [ ! -x "$(command -v npm)" ]; then
			nvm install-latest-npm
			# install eslint after npm
			npm i -g eslint
		fi


	fi	
}

install_zsh() {
	# Clone zsh plugins
    if [ ! -d ~/.oh-my-zsh ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
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
    if [ ! -f ~/work_alias ]; then
        touch ~/work_alias
    fi

    # Link the nvim configuration
    if [ ! -d ~/.config/nvim ]; then
        ln -s $(pwd)/nvim ~/.config/nvim
    fi

    # Link my alacritty's if it does not exists
    if [ ! -f ~/.alacritty.yml ]; then
        ln -s $(pwd)alacritty.toml ~/.alacritty.toml
    fi

    # Link my tmux's if it does not exists
    if [ ! -f ~/.tmux.conf ]; then
        ln -s $(pwd)tmux.conf ~/.tmux.conf
    fi
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

install_nvim(){ 
	# TODO: Need to check version to update every day
	if [ ! -d ~/.nvim-osx64 ]; then
		curl -fsSLO https://github.com/neovim/neovim/releases/download/nightly/nvim-macos.tar.gz
		tar xzvf nvim-macos.tar.gz
		rm nvim-macos.tar.gz
		mv nvim-osx64 ~/.nvim-osx64
	fi

	#Install Plugin manager Packer 
	if [ ! -d ~/.local/share/nvim/site/pack/packer/start/ ]; then 
		git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim
	fi
}

apply_mac_default(){
  defaults write com.apple.dock static-only -bool true
  killall Dock

  defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
  killall Finder

  defaults write com.apple.finder _FXSortFoldersFirst -bool true
  killall Finder

}


install_zsh
link_dotfiles

#install_tmux
#install_lsp_on_mac
#install_nvim

# TODO

# generate ssh-key for new deployment 
