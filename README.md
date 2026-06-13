# dotfiles

Personal macOS developer dotfiles — Apple Silicon (M5 Pro).

## Files

| File | Purpose |
|------|---------|
| `zshrc` | Interactive shell: PATH, tools, aliases |
| `zshenv` | All zsh invocations: cargo, wasmedge |
| `zprofile` | Login shells: Homebrew |
| `bash_profile` | Rare bash: composer |
| `bashrc` | Rare bash: cargo |
| `gitconfig` | Git: delta pager, LFS, user |
| `gitignore_global` | Global gitignore (DS_Store, etc.) |
| `cargo/config.toml` | Cargo: sparse registry |

## Install

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

## Architecture

- **zshenv** — Always loaded. Only idempotent env setup (cargo, wasmedge).
- **zprofile** — Login shells only. Homebrew shell env.
- **zshrc** — Interactive shells. PATH additions, tool config, aliases.

## Tool Stack

| Tool | Replaces | Install |
|------|----------|---------|
| eza | ls | `brew install eza` |
| bat | cat | `brew install bat` |
| fd | find | `brew install fd` |
| ripgrep | grep | `brew install ripgrep` |
| dust | du | `brew install dust` |
| procs | ps | `brew install procs` |
| bottom | top | `brew install bottom` |
| delta | git diff | `brew install git-delta` |
| fnm | nvm | `brew install fnm` |

## Notes

- Each tool sourced exactly once across all shell config files
- `/etc/paths.d/` cleaned to only: `homebrew`, `100-rvictl`
- No `~/.profile` (empty) or `~/.zlogin` (not needed)

## Shell Environment for AI Agents

If you're an AI agent (or human) working on this machine, use these tools **directly**:

| Use this | Not this | Why |
|----------|----------|-----|
| `rg "pattern"` | `grep -rn "pattern" .` | rg is recursive by default, no -r/-n flags needed |
| `eza --icons --git` | `ls -la` | eza shows git status + icons |
| `bat file.rs` | `cat file.rs` | bat adds syntax highlighting |
| `fd "\.rs$"` | `find . -name "*.rs"` | fd has simpler glob syntax |
| `dust` | `du -sh *` | dust is visual + faster |
| `procs` | `ps aux` | procs is cleaner output |
| `btm` | `top` | bottom is interactive + better |

**Why it matters:** `grep`, `find`, `ls` etc. are aliased to their Rust replacements. But the flags are incompatible — e.g. `grep -r` means recursive, but `rg -r` means replace. Using the native tool directly avoids silent breakage.
