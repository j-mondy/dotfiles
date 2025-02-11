# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# User specific environment and startup programs
alias config='/usr/bin/git --git-dir=$HOME/.config/ --work-tree=$HOME'
