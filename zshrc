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
alias zed-fork="$HOME/.cargo/target/release/zed"

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


# --- BATTERY STATUS (sleep-leak detector) ---
# Use: battery-status → charge, health, cycle count, power source, and which
#                        apps are preventing the Mac from deep-sleeping.
# Uses ioreg (fast) + pmset. `command grep` avoids the grep→rg alias trap.
battery-status() {
  local batt source pct state ioreg cycles max design health
  local leaks holders suspects

  # charge + power source (pmset)
  batt="$(pmset -g batt)"
  source="$(printf '%s' "$batt" | awk -F"'" '/drawing from/{print $2; exit}')"
  source="${source:-unknown}"
  pct="$(printf '%s' "$batt" | awk -F'\t' '/InternalBattery/{split($2,a,";"); gsub(/[^0-9]/,"",a[1]); print a[1]; exit}')"
  state="$(printf '%s' "$batt" | awk -F'\t' '/InternalBattery/{split($2,a,";"); gsub(/^ +| +$/,"",a[2]); print a[2]; exit}')"

  # battery details (ioreg — ~10ms; anchor to start-of-line to skip the BatteryData blob)
  ioreg="$(ioreg -rn AppleSmartBattery)"
  cycles="$(printf '%s' "$ioreg" | awk -F'= ' '/^[[:space:]]*"CycleCount"/{print $2; exit}')"
  max="$(printf '%s'    "$ioreg" | awk -F'= ' '/^[[:space:]]*"MaxCapacity"/{print $2; exit}')"
  design="$(printf '%s' "$ioreg" | awk -F'= ' '/^[[:space:]]*"DesignCapacity"/{print $2; exit}')"
  if [ -n "$max" ] && [ -n "$design" ]; then
    if [ "$max" -le 100 ] 2>/dev/null; then
      health="${max}%"
    else
      health="$(( max * 100 / design ))%"
    fi
  else
    health="?"
  fi

  # sleep-leak detector (the LINE.AudioService bug lives here)
  leaks="$(pmset -g assertions 2>/dev/null | command grep -c 'PreventUserIdleSystemSleep')"
  holders="$(pmset -g assertions 2>/dev/null \
    | command grep -oE 'pid [0-9]+\([^)]+\)' \
    | sed -E 's/pid [0-9]+\((.*)\)/\1/' | sort -u)"
  # system services allowed to hold assertions
  suspects="$(printf '%s\n' "$holders" \
    | command grep -ivE '^(powerd|WindowServer|coreaudiod|launchd|sharingd|kernel_task|bluetoothd|mds)$' \
    | paste -sd, -)"

  echo "Battery   ${pct:-?}%  · health ${health}  · ${cycles:-?} cycles"
  echo "Power     ${source}  · ${state:-—}"
  if [ -n "$suspects" ]; then
    echo "Sleep     ⚠ ${leaks} idle-sleep assertions — ${suspects} is blocking deep sleep"
    echo "          → quit/restart the culprit to restore sleep"
  else
    echo "Sleep     OK (${leaks} normal idle-sleep assertions)"
  fi
}

# --- AUDIT LOG (drift detection viewer) ---
# Use: audit-log → show the latest mac-audit run from the weekly LaunchAgent
audit-log() {
  local log="$HOME/Library/Logs/mac-audit.log"
  if [ ! -f "$log" ]; then
    echo "No audit log yet. Run 'mac-audit-weekly' or wait for the weekly LaunchAgent."
    return
  fi
  # Print from the last separator line to EOF (the most recent run)
  awk '/════════ mac-audit/{block=""} {block=block $0 "\n"} END{printf "%s", block}' "$log"
}
