#!/bin/bash -


# GIT
mkdir -p "$HOME/git"
git clone https://github.com/magicmonty/bash-git-prompt.git "$HOME/git/"
ln -s ".dotfiles/git/gitconfig" "$HOME/.gitconfig"
ln -s ".dotfiles/git/gitignore" "$HOME/.gitignore"

# BASH
ln -s .dotfiles/bash/bashrc .bashrc
mkdir -p .bash_history_dir
mkdir -p .bashrc_dir
mkdir -p scripts
ln -s ../.dotfiles/bash/common.sh "$HOME/scripts/common.sh"

# VIM
curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
ln -s ".dotfiles/vim/vimrc" "$HOME/.vimrc"
ln -s "../.dotfiles/vim/templates" "$HOME/.vim/templates"
ln -s "../.dotfiles/vim/colors" "$HOME/.vim/colors"
vim +PlugInstall +qall
echo "please install shellcheck https://github.com/koalaman/shellcheck/releases/download/stable/shellcheck-stable.linux.x86_64.tar.xz"
echo "Please install shfmt https://github.com/mvdan/sh/releases/download/v3.2.0/shfmt_v3.2.0_linux_amd64"

# TMUX
ln -s ".dotfiles/tmux.conf" "$HOME/.tmux.conf"
