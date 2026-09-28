# Login environment for POSIX shells.
[ -r "$HOME/.shellenv" ] && . "$HOME/.shellenv"
if [ -n "${BASH_VERSION-}" ] && [ -r "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi
if [ -r "$HOME/.profile.local" ]; then
    . "$HOME/.profile.local"
fi
