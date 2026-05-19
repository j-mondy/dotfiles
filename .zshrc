# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Load plugins - Add wisely, as too many plugins slow down shell startup
plugins=(
    git
    keychain
    ssh-agent
    zsh-autosuggestions
    zsh-nvm
    zsh-syntax-highlighting
)

# Case-insensitive completion
autoload -U compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Adjust agents that keychain manages
zstyle :omz:plugins:keychain agents gpg,ssh

# Source oh-my-zsh
source $ZSH/oh-my-zsh.sh

# Source zsh profile
source ~/.zsh_profile

# Add Homebrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"

# Set theme to starship
eval "$(starship init zsh)"

