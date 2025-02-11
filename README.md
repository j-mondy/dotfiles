# Josh's Dotfiles

Pardon the dust while this gets set up.

Based off of [this dotfiles tutorial](https://www.atlassian.com/git/tutorials/dotfiles). Following up with this as well: <https://medium.com/@simontoth/best-way-to-manage-your-dotfiles-2c45bb280049>. A bootstrap file may be needed, we'll see.

## initialize - first machine
```bash
mkdir .dotfiles
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
dotfiles config --local status.showUntrackedFiles no
echo "alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'" $HOME/.bashrc
```

## init - second machine

```bash
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
git clone --bare git@github.com:mondyjosh/dotfiles.git $HOME/.dotfiles
dotfiles config --local status.showUntrackedFiles no
dotfiles checkout
```

## TODOs
- [ ] Add Ansible as submodule
- [ ] Add Neovim as submodule
- [ ] Identify other submodules
