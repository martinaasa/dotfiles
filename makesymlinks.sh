#!/usr/bin/env bash
set -euo pipefail

# The runtime configuration expects this documented installation location.
dir="$HOME/.dotfiles"
if [[ "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)" != "$(cd -- "$dir" && pwd -P)" ]]; then
    echo 'Install this repository at ~/.dotfiles first.' >&2
    exit 1
fi
case "${1-}" in
    '') files=(shellenv profile bashrc vimrc bash-it gitconfig neofetch) ;;
    --shell-only) files=(shellenv profile bashrc bash-it) ;;
    *) echo "Usage: $0 [--shell-only]" >&2; exit 2 ;;
esac

backup_dir=''
backup() {
    if [[ -z "$backup_dir" ]]; then
        mkdir -p "$HOME/.dotfiles_old"
        backup_dir=$(mktemp -d "$HOME/.dotfiles_old/install.XXXXXXXX")
        echo "Backup: $backup_dir"
    fi
    mv -- "$1" "$backup_dir/$2"
}
link_file() {
    local source=$1 target=$2 label=$3
    if [[ -L "$target" && "$(readlink -- "$target")" == "$source" ]]; then
        return
    fi
    if [[ -e "$target" || -L "$target" ]]; then
        backup "$target" "$label"
    fi
    ln -s -- "$source" "$target"
}

read -r version < "$dir/bash-it.version"
if [[ ! -e "$dir/bash-it" ]]; then
    git clone --no-checkout https://github.com/Bash-it/bash-it.git "$dir/bash-it"
    git -C "$dir/bash-it" checkout --detach "$version"
fi
if [[ "$(git -C "$dir/bash-it" rev-parse HEAD)" != "$version" ]]; then
    echo 'Bash-it differs from bash-it.version; reconcile it before installing.' >&2
    exit 1
fi
if [[ -n "$(git -C "$dir/bash-it" status --porcelain --untracked-files=no)" ]]; then
    echo 'Bash-it has tracked local changes; preserve them before installing.' >&2
    exit 1
fi

# Keep existing host additions; restore the versioned baseline on new hosts.
mkdir -p "$dir/bash-it/enabled"
while read -r name target; do
    [[ -n "$name" ]] || continue
    if [[ ! -f "$dir/bash-it/enabled/$target" ]]; then
        echo "Missing Bash-it component: $target" >&2
        exit 1
    fi
    link_file "$target" "$dir/bash-it/enabled/$name" "bash-it-$name"
done < "$dir/bash-it.enabled"
link_file "$dir/aliases" "$dir/bash-it/aliases/custom.aliases.bash" bash-it-custom-aliases

for file in "${files[@]}"; do
    link_file "$dir/$file" "$HOME/.$file" "$file"
done
if [[ -e "$HOME/.bash_profile" || -e "$HOME/.bash_login" ]]; then
    echo 'A Bash login file overrides ~/.profile; ensure it sources ~/.profile.' >&2
fi
