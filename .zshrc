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

# Adjust agents that keychain manages
zstyle :omz:plugins:keychain agents gpg,ssh

# Source oh-my-zsh
source $ZSH/oh-my-zsh.sh

# Source zsh profile
source ~/.zsh_profile

# Set theme to starship
eval "$(starship init zsh)"
