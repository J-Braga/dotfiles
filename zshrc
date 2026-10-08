# Function to check if pre-commit hook exists
check_pre_commit() {
    local repo_path="$1"  # Accept folder path as argument
    local current_dir
    current_dir=$(basename "$PWD")
    # Check if the current directory is the specified repo folder
    if [ "$current_dir" = "$repo_path" ]; then
        if [ ! -f ".git/hooks/pre-commit" ]; then
            # Copy the pre-commit hook from ~/work/hooks/pre-commits
            if [ -f "$HOME/work/hooks/pre-commits" ]; then
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
    builtin cd "$@" || return
    rm -f '.DS_Store'
    ls -FGlAhp
    check_pre_commit "magnet_deployments"
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
export EDITOR='nvim'

# Add my alias that is in git
if [ -f ~/.config/alias ]; then
    source ~/.config/alias
fi

# Source custom alias, usually alias outside of git, enviroment/host specific alias
if [ -f ~/.work_alias ]; then
    source ~/.work_alias
fi

# vi mode
bindkey -v
export KEYTIMEOUT=1

# Suggest from history only; completion suggestions spawn helper zsh workers.
ZSH_AUTOSUGGEST_STRATEGY=(history)

# Let the Oh My Zsh theme render the active virtualenv without rewriting PS1.
export VIRTUAL_ENV_DISABLE_PROMPT=1

# virtualenvwrapper is installed via `uv tool install` (see install.sh), which
# isolates its module in its own venv. Point the omz plugin at that interpreter
# so it can import the module. Guarded so a machine without it stays quiet.
if [ -x "$HOME/.local/share/uv/tools/virtualenvwrapper/bin/python" ]; then
  export VIRTUALENVWRAPPER_PYTHON="$HOME/.local/share/uv/tools/virtualenvwrapper/bin/python"
fi

plugins=(
  git
  macos
  zsh-autosuggestions
  fast-syntax-highlighting
  virtualenvwrapper
  azure
  aws
)

source $ZSH/oh-my-zsh.sh

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

zstyle ':completion:*' list-colors 'di=34' 'ln=36' 'so=35' 'pi=33' 'ex=32' 'bd=34;46' 'cd=34;46' 'su=30;41' 'sg=30;46' 'tw=30;42' 'ow=30;43'

if (( ${+FAST_HIGHLIGHT_STYLES} )); then
  FAST_HIGHLIGHT_STYLES[default]='none'
  FAST_HIGHLIGHT_STYLES[unknown-token]='fg=1,bold'
  FAST_HIGHLIGHT_STYLES[reserved-word]='fg=15'
  FAST_HIGHLIGHT_STYLES[alias]='fg=2'
  FAST_HIGHLIGHT_STYLES[builtin]='fg=2'
  FAST_HIGHLIGHT_STYLES[function]='fg=15'
  FAST_HIGHLIGHT_STYLES[command]='fg=2'
  FAST_HIGHLIGHT_STYLES[precommand]='fg=2'
  FAST_HIGHLIGHT_STYLES[subcommand]='fg=11'
  FAST_HIGHLIGHT_STYLES[single-hyphen-option]='fg=4'
  FAST_HIGHLIGHT_STYLES[double-hyphen-option]='fg=4'
  FAST_HIGHLIGHT_STYLES[path]='fg=6'
  FAST_HIGHLIGHT_STYLES[path-to-dir]='fg=6,underline'
  FAST_HIGHLIGHT_STYLES[path_pathseparator]='fg=8'
  FAST_HIGHLIGHT_STYLES[single-quoted-argument]='fg=14'
  FAST_HIGHLIGHT_STYLES[double-quoted-argument]='fg=14'
  FAST_HIGHLIGHT_STYLES[back-dollar-quoted-argument]='fg=14'
  FAST_HIGHLIGHT_STYLES[back-or-dollar-double-quoted-argument]='fg=14'
  FAST_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=14'
  FAST_HIGHLIGHT_STYLES[comment]='fg=2'
  FAST_HIGHLIGHT_STYLES[variable]='fg=4'
  FAST_HIGHLIGHT_STYLES[assign]='fg=15'
  FAST_HIGHLIGHT_STYLES[redirection]='fg=11'
  FAST_HIGHLIGHT_STYLES[globbing]='fg=4,bold'
  FAST_HIGHLIGHT_STYLES[history-expansion]='fg=11,bold'
  FAST_HIGHLIGHT_STYLES[mathnum]='fg=6'
  FAST_HIGHLIGHT_STYLES[correct-subtle]='fg=8'
  FAST_HIGHLIGHT_STYLES[incorrect-subtle]='fg=1'
  FAST_HIGHLIGHT_STYLES[bracket-level-1]='fg=6,bold'
  FAST_HIGHLIGHT_STYLES[bracket-level-2]='fg=11,bold'
  FAST_HIGHLIGHT_STYLES[bracket-level-3]='fg=4,bold'
  FAST_HIGHLIGHT_STYLES[here-string-text]='bg=18'
  FAST_HIGHLIGHT_STYLES[here-string-var]='fg=14,bg=18'
  FAST_HIGHLIGHT_STYLES[subtle-bg]='bg=18'
fi

# Restore arrow keys for history navigation.
bindkey '^[[A' .up-line-or-history
bindkey '^[OA' .up-line-or-history
bindkey '^[[B' .down-line-or-history
bindkey '^[OB' .down-line-or-history
bindkey -a '^[[A' .up-line-or-history
bindkey -a '^[OA' .up-line-or-history
bindkey -a '^[[B' .down-line-or-history
bindkey -a '^[OB' .down-line-or-history

# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char
bindkey "^A" vi-beginning-of-line
# Change cursor shape for different vi modes.
autoload -Uz add-zle-hook-widget

_cursor_keymap_select() {
  if [[ ${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'   # block cursor for command mode
  else
    echo -ne '\e[5 q'   # beam cursor for insert mode
  fi
}
add-zle-hook-widget keymap-select _cursor_keymap_select

_cursor_line_init() {
  echo -ne '\e[5 q'     # beam cursor when a new line starts
}
add-zle-hook-widget line-init _cursor_line_init

echo -ne '\e[5 q' # Use beam shape cursor on startup.
preexec() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.
# Edit line in vim with ctrl-e:

#autoload edit-command-line; zle -N edit-command-line
#bindkey '^e' edit-command-line

# autosuggest-execute '^ '
# CTRL+SPACE to access autosuggest
bindkey '^ ' autosuggest-accept

autoload -U +X bashcompinit && bashcompinit

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

if [ -f ~/.work_zshrc ]; then
  source ~/.work_zshrc
fi

export PATH=$PATH:/usr/local/sbin
#export NVIM_LISTEN_ADDRESS='/tmp/nvimsocket nvim'

export PATH="$PATH:$HOME/.local/bin"
[ -f ~/.config/forgejo/token.env ] && source ~/.config/forgejo/token.env

if [ -d "/opt/homebrew/share/android-commandlinetools/bin" ]; then
  export PATH="$PATH:/opt/homebrew/share/android-commandlinetools/bin"
fi
export PATH="$PATH:$(go env GOPATH)/bin"
