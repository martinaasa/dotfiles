#!/usr/bin/env bash
set -euo pipefail

# Resolve the checkout location; home symlinks provide stable runtime paths.
dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
case "${1-}" in
    '') files=(shellenv profile bashrc vimrc bash-it gitconfig neofetch) ;;
    --shell-only) files=(shellenv profile bashrc bash-it) ;;
    *) echo "Usage: $0 [--shell-only]" >&2; exit 2 ;;
esac

backup_dir=''
ensure_backup() {
    if [[ -z "$backup_dir" ]]; then
        mkdir -p "$HOME/.dotfiles_old"
        backup_dir=$(mktemp -d "$HOME/.dotfiles_old/install.XXXXXXXX")
        echo "Backup: $backup_dir"
    fi
}
backup() {
    ensure_backup
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
    git -C "$dir/bash-it" checkout --no-overwrite-ignore --detach "$version"
fi
if [[ -n "$(git -C "$dir/bash-it" status --porcelain --untracked-files=no)" ]]; then
    echo 'Bash-it has tracked local changes; preserve them before installing.' >&2
    exit 1
fi
if [[ "$(git -C "$dir/bash-it" rev-parse HEAD)" != "$version" ]]; then
    if ! git -C "$dir/bash-it" cat-file -e "$version^{commit}" 2>/dev/null; then
        git -C "$dir/bash-it" fetch origin "$version"
    fi
    # Preserve the entire old checkout, including ignored local components.
    ensure_backup
    cp -a "$dir/bash-it" "$backup_dir/bash-it-checkout"
    # Never force checkout: Git must refuse conflicting local files.
    git -C "$dir/bash-it" checkout --no-overwrite-ignore --detach "$version"
fi

# Validate the whole manifest before changing enabled components or home links.
while read -r name target; do
    [[ -n "$name" ]] || continue
    if [[ ! -f "$dir/bash-it/enabled/$target" ]]; then
        # enabled may not exist on a fresh clone.
        if [[ ! -f "$dir/bash-it/${target#../}" ]]; then
            echo "Missing Bash-it component: $target" >&2
            exit 1
        fi
    fi
done < "$dir/bash-it.enabled"

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
