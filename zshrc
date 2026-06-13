# --- PATHS ---
export PATH="$HOME/.local/bin:$PATH"
export PATH="/Users/ozone/.avm/bin:$PATH"
export PATH="/Users/ozone/.antigravity/antigravity/bin:$PATH"
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# --- TOOLS ---

# Homebrew (also in .zprofile for login shells, but harmless to eval again)
eval "$(/opt/homebrew/bin/brew shellenv zsh)"

# Node (fnm — fast Node Manager)
eval "$(fnm env --use-on-cd)"

# Rust: loaded in .zshenv (available to all zsh invocations)

# Solana
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"


# --- ALIASES (Rust-powered replacements) ---
alias ls='eza --icons'
alias ll='eza -l --icons --git'
alias la='eza -la --icons --git'
alias lt='eza -T --icons --level=2'
alias cat='bat --paging=never'
alias find='fd'
alias grep='rg'
alias du='dust'
alias ps='procs'
alias top='btm'

# --- ZED FORK (auto_prompt) ---
alias zed-fork="$HOME/Projects/zed-fork/target/release/zed"

# --- BUILD CLEANUP ---
alias cargo-clean-all='rm -rf ~/.cargo/target && echo "Cleared shared target dir (~/.cargo/target)"'

# --- DNS TOGGLE (public WiFi fix) ---
# Use: dns-auto       → reset to network-provided DNS (fixes captive portal)
# Use: dns-cloudflare → set Cloudflare DNS (1.1.1.1, fast & private)
# Use: dns-status     → show current DNS
dns-auto() {
  sudo networksetup -setdnsservers Wi-Fi empty
  echo "DNS: auto (network-provided)"
  networksetup -getdnsservers Wi-Fi
}

dns-cloudflare() {
  sudo networksetup -setdnsservers Wi-Fi 1.1.1.1 1.0.0.1
  echo "DNS: Cloudflare (1.1.1.1)"
  networksetup -getdnsservers Wi-Fi
}

dns-status() {
  echo "Wi-Fi DNS:"
  networksetup -getdnsservers Wi-Fi
  echo ""
  echo "Active resolver:"
  scutil --dns | grep -A3 "nameserver\[0\]" | head -4
}
