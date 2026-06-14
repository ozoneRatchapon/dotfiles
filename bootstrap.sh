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
    # Ensure parent dir exists (e.g. ~/.local/bin, ~/Library/LaunchAgents)
    mkdir -p "$(dirname "$dest")"
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
echo "Linking scripts..."
link bin/mac-audit-weekly .local/bin/mac-audit-weekly
chmod +x "$DOTFILES/bin/mac-audit-weekly"

echo ""
echo "Linking LaunchAgents..."
link launchagents/com.ozone.mac-audit.plist Library/LaunchAgents/com.ozone.mac-audit.plist

echo ""
echo "Done. Open a new terminal to apply config changes."
echo ""
echo "To activate the weekly audit LaunchAgent (first time only):"
echo "  launchctl load ~/Library/LaunchAgents/com.ozone.mac-audit.plist"
echo ""
echo "To trigger a manual run now:"
echo "  launchctl start com.ozone.mac-audit"
echo ""
echo "To view the latest audit:"
echo "  audit-log"
echo ""
echo "Backups saved with .bak.<timestamp> suffix."
