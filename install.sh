#!/bin/bash -


# GIT
mkdir -p $HOME/git
git clone https://github.com/magicmonty/bash-git-prompt.git $HOME/git/
ln -s $HOME/.dotfiles/git/gitconfig $HOME/.gitconfig
ln -s $HOME/.dotfiles/git/gitignore $HOME/.gitignore

# BASH
ln -s $HOME/.dotfiles/bashrc $HOME/.bashrc

# VIM
curl -fLo $HOME/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
ln -s $HOME/.dotfiles/vim/vimrc $HOME/.vimrc
ln -s $HOME/.dotfiles/vim/template $HOME/.vim/template
vim +PlugInstall +qall

# TMUX
ln -s $HOME/.dotfiles/tmux.conf $HOME/.tmux.conf
