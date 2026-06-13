#!/usr/bin/env bash
# Bootstrap — symlink dotfiles to $HOME
# Safe: backs up existing files before overwriting

set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

backup() {
    local target="$1"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        local backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
        echo "  Backing up $target → $backup"
        mv "$target" "$backup"
    fi
}

link() {
    local src="$DOTFILES/$1"
    local dest="$HOME/$2"
    if [ -L "$dest" ]; then
        local current
        current="$(readlink "$dest")"
        if [ "$current" = "$src" ]; then
            echo "  ✓ $dest (already linked)"
            return
        fi
    fi
    backup "$dest"
    ln -sf "$src" "$dest"
    echo "  linked $dest → $src"
}

echo "Linking dotfiles..."
link zshrc       .zshrc
link zshenv      .zshenv
link zprofile    .zprofile
link bash_profile .bash_profile
link bashrc      .bashrc
link gitconfig   .gitconfig
link gitignore_global .gitignore_global
link cargo/config.toml .cargo/config.toml

echo ""
echo "Done. Open a new terminal to apply."
echo "Backups saved with .bak.<timestamp> suffix."
