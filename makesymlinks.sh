#!/bin/bash
############################
# .make.sh
# This script creates symlinks from the home directory to any desired dotfiles in ~/dotfiles
############################

########## Variables

dir=~/.dotfiles                    # dotfiles directory
olddir=~/.dotfiles_old             # old dotfiles backup directory
files="bashrc vimrc bash-it gitconfig neofetch"    # list of files/folders to symlink in homedir

##########

# create dotfiles_old in homedir
echo -n "Creating $olddir for backup of any existing dotfiles in ~ ..."
mkdir -p $olddir
echo "done"

# change to the dotfiles directory
echo -n "Changing to the $dir directory ..."
cd $dir
echo "done"

# move any existing dotfiles in homedir to dotfiles_old directory, then create symlinks from the homedir to any files in the ~/dotfiles directory specified in $files
for file in $files; do
  echo "Moving any existing dotfiles from ~ to $olddir"
  mv ~/.$file $olddir
  echo "Creating symlink to $file in home directory."
  ln -s $dir/$file ~/.$file
done

install_bash_it () {
  # Clone Bash-it repository from GitHub only if it isn't already present
  if [[ ! -d $dir/bash-it/ ]]; then
    git clone --depth=1 https://github.com/Bash-it/bash-it.git
    chmod +x $dir/bash-it/install.sh
    /bin/bash $dir/bash-it/install.sh -i -n
  fi
}

install_bash_it

# setup custom aliases
if [[ -d $dir/bash-it/ ]]; then
  ln -s $dir/aliases $dir/bash-it/aliases/custom.aliases.bash
  echo "Creating symlink for custom Bash-it aliases."
fi
