Dotfiles
========
This repository includes all of my custom dotfiles.  They can be cloned anywhere; `~/.dotfiles/` is the default location.  The included setup
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

Shell configuration
-------------------

`~/.shellenv`, `~/.profile`, and `~/.bashrc` link to this repository. The shared
POSIX environment adds existing `~/bin` and `~/.local/bin` directories once.
Both login shells and interactive Bash load it; ordinary scripts inherit PATH.
An already duplicated inherited PATH is not rewritten; use a fresh login after
migrating. Bash-it is loaded only when its entrypoint is readable.

Keep host-specific Bash settings in `~/.bashrc.local` (loaded before Bash-it,
so it can override `BASH_IT` and `BASH_IT_THEME`). Login-only settings belong in
`~/.profile.local`. These files live outside the repository. If you have a
`~/.bash_profile` or `~/.bash_login`, make it source `~/.profile`.

To install only the shell configuration:

```bash
./makesymlinks.sh --shell-only
```

Installation preserves replaced files under a unique `~/.dotfiles_old/install.*`
directory and skips links already pointing to the expected target. Inspect the
backups and move any additional host customizations to the local files above.
The installer resolves its checkout directory and creates absolute symlinks.
After moving the checkout, rerun the installer. `BASH_IT` defaults to
`~/.bash-it`; an exported value or `~/.bashrc.local` can override it.

`bash-it.version` pins Bash-it to a shared baseline revision;
`bash-it.enabled` records the enabled component symlinks. A fresh installation
clones that revision and restores the baseline plus the custom aliases.
Existing additional components are retained. Existing Bash-it checkouts with a
different revision or tracked modifications cause installation to stop rather
than overwrite them. To upgrade, review and test the new revision, then update
the pin and component manifest together. The pin ensures reproducibility; it
is not a claim that this older version is the latest available.

Neofetch host settings
----------------------

Disk display defaults to `/`. Put additional host settings in
`~/.neofetch.local`, which is loaded after the shared configuration. For example:

```bash
if command -v mountpoint >/dev/null 2>&1 && mountpoint -q /mnt/tank; then
    disk_show+=(/mnt/tank)
fi
```

Package aliases are selected according to installed tools. Optional
update-notifier helpers are enabled only when executable; a missing reboot
marker is treated as no pending reboot notification.
