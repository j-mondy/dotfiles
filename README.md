# mondyjosh's dotfiles

Based off of [this dotfiles tutorial](https://www.atlassian.com/git/tutorials/dotfiles). 

One slight change, I am using `.config` in place of `.cfg`, so the revised initialization script (that will probably need to be added to a bootstrap here):

```bash
git init --bare $HOME/.config --initial-branch=main
alias config='/usr/bin/git --git-dir=$HOME/.config/ --work-tree=$HOME'
config config --local status.showUntrackedFiles no
echo "alias config='/usr/bin/git --git-dir=$HOME/.config/ --work-tree=$HOME'" >> $HOME/.bashrc
```

Pardon the dust while this gets set up.
