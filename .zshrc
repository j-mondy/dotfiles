# ~/.zshrc

# Homebrew - Add first to include it in PATH/FPATH for everything else
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"

# Add history
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt share_history hist_ignore_all_dups inc_append_history

# Case-insensitive completion
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Keychains for SSH/GPG agents
if command -v keychain >/dev/null; then
  eval "$(keychain --eval --quiet --agents gpg,ssh)"
fi

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
[ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"

# Source zsh profile
source ~/.zsh_profile

# Set prompt theme to starship
eval "$(starship init zsh)"

# Source plugins (syntax-highlighting MUST be sourced last)
source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
