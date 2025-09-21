# Function to check if pre-commit hook exists
check_pre_commit() {
    local repo_path="$1"  # Accept folder path as argument
    current_dir=$(basename "$PWD")
    # Check if the current directory is the specified repo folder
    if [ "$current_dir" = "$repo_path" ]; then
        if [ ! -f ".git/hooks/pre-commit" ]; then
            # Copy the pre-commit hook from ~/work/hooks/pre-commits
            if [ -f "~/work/hooks/pre-commits" ]; then
                cp ~/work/hooks/pre-commits .git/hooks/pre-commit
                chmod +x .git/hooks/pre-commit
            else
                echo "ERROR: Source pre-commit hook ~/work/hooks/pre-commits does not exist"
            fi
        fi
    fi
}

# Override cd 
cd() {
    builtin cd "$@";
    rm -f '.DS_Store'; ls -FGlAhp;
    check_pre_commit "magnet_deployments";
}

export TERM=xterm-256color
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
# Enable colors and change prompt:
autoload -U colors && colors
# History in cache directory:
# Vars
HISTSIZE=10000
HISTFILE=~/.zsh_history
SAVEHIST=10000
setopt inc_append_history # To save every command before it is executed
setopt share_history # setopt inc_append_history

# Basic auto/tab complete:
#zstyle ':completion:*' menu select
#zmodload zsh/complist
#_comp_options+=(globdots)		# Include hidden files.

#ZSH_THEME=robbyrussell
#ZSH_THEME="avit"
#ZSH_THEME=itchy
ZSH_THEME=bira

HIST_STAMPS="mm/dd/yyyy"

#Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='nvim'
else
  export EDITOR='nvim'
fi

# Add my alias that is in git
if [ -f ~/.config/alias ]; then
    source ~/.config/alias
fi

# Source custom alias, usually alias outside of git, enviroment/host specific alias
if [ -f ~/.work_alias ]; then
    source ~/.work_alias
fi

zstyle :omz:plugins:ssh-agent identities id_rsa 

plugins=(
  git
  macos
  zsh-autosuggestions
  zsh-syntax-highlighting
  fast-syntax-highlighting
  zsh-autocomplete
  ssh-agent
  virtualenvwrapper
  azure
  aws
)

source $ZSH/oh-my-zsh.sh

# vi mode
bindkey -v
export KEYTIMEOUT=1

# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char
bindkey "^A" vi-beginning-of-line
# Change cursor shape for different vi modes.
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'
  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[5 q"
}
zle -N zle-line-init
echo -ne '\e[5 q' # Use beam shape cursor on startup.
preexec() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.
# Edit line in vim with ctrl-e:
#
autoload edit-command-line; zle -N edit-command-line

bindkey '^e' edit-command-line

# autosuggest-execute '^ '
# CTRL+SPACE to access autosuggest
bindkey '^ ' autosuggest-accept

autoload -U +X bashcompinit && bashcompinit -U

if [ -d ~/.config/linters/ ]; then
  export PATH=$PATH:~/.config/linters/
fi
if [ -d ~/.gh_cli ]; then
  export PATH=$PATH:~/.gh_cli/bin/
fi

if [ -d ~/.gcp-sdk ]; then
  export PATH=$PATH:~/.gcp-sdk/bin/
fi

if [ -d ~/.sokol-tools-bin ]; then
  export PATH=$PATH:~/.sokol-tools-bin/bin/osx_arm64/
fi

if [ -d ~/.bin/zig ]; then
  export PATH=$PATH:~/.bin/zig
fi


export PATH=$PATH:/usr/local/sbin
#export NVIM_LISTEN_ADDRESS='/tmp/nvimsocket nvim'

# bun completions
#[ -s "~/.bun/_bun" ] && source "~/.bun/_bun"

# bun
#export BUN_INSTALL="$HOME/.bun"
#export PATH="$BUN_INSTALL/bin:$PATH"

export PATH="$PATH:~/.local/bin"

