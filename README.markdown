Dotfiles
========
This repository includes all of my custom dotfiles.  They should be cloned to
your home directory so that the path is `~/.dotfiles/`.  The included setup
script creates symlinks from your home directory to the files which are located
in `~/.dotfiles/`.

The setup script is smart enough to back up your existing dotfiles into a
`~/.dotfiles_old/` directory if you already have any dotfiles of the same name as
the dotfile symlinks being created in your home directory.

It will also clone Bash-it from https://github.com/Bash-it/bash-it as it's my prefered
way to handle Bash dotfiles.

So, to recap, the install script will:

1. Back up any existing dotfiles in your home directory to `~/.dotfiles_old/`
2. Create symlinks to the dotfiles in `~/.dotfiles/` in your home directory
3. Clone the `Bash-it` repository from Github

Installation
------------

``` bash
git clone https://github.com/martinaasa/dotfiles ~/.dotfiles
cd ~/.dotfiles
./makesymlinks.sh
```
