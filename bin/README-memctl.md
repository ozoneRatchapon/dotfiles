# memctl — machine-wide memory governor

Built because 48 GB gets exhausted by *four* competitors at once, not one:
ComfyUI/MLX (GPU, **wired**), ollama (resident models), several editors each
running their own rust-analyzer, and `cargo` fanning out to 18 rustc processes.

## The one macOS fact that drives all of this

On Apple Silicon the GPU allocates from the **same** pool as the CPU, and those
pages are **wired** — the kernel cannot compress them, cannot page them out,
cannot reclaim them under pressure. When ComfyUI holds 30 GB wired, your
effective RAM for builds and editors is 18 GB, not 48 GB.

So "free RAM" is the wrong number to watch. The tools here watch:

| metric | meaning |
|---|---|
| `available` | free + inactive + purgeable — what can actually be handed out |
| `wired` | pinned, unreclaimable — GPU/ML jobs live here |
| `compressed` | >0 means the VM has started compressing; pressure has begun |
| `swap` | >0 means pressure is already hurting |

## Commands

| command | what it does |
|---|---|
| `memtop` | who is eating RAM right now, grouped by app family + a go/no-go verdict |
| `memdoctor` | full audit of every OOM risk on this machine, with the fix for each |
| `memgate` | admission control — hold a command until the machine can afford it |
| `cg` | memory-aware `cargo`; picks `--jobs` from available RAM, queues via memgate |
| `memwatch` | background recorder; dumps a process snapshot when headroom collapses |

### memgate

Wraps **any** heavy command, not just Rust:

```bash
memgate --need 24 --slot gpu --max 1 -- python main.py      # ComfyUI
memgate --need 6  -- ffmpeg -i in.mp4 out.mp4
memgate --need 12 -- cargo bench
```

- `--need GB` — refuse to launch until that much is *available*
- `--slot NAME --max N` — at most N holders of that slot across all terminals
  and editors, so two projects queue instead of colliding
- `--timeout SEC` — give up and exit 75 (`EX_TEMPFAIL`); `0` waits forever

Slots are `mkdir`-based (atomic on APFS; macOS has no `flock(1)`). A slot whose
owner died — crash, OOM kill, Ctrl-C — is reaped by the next waiter via a
`kill -0` liveness check, so a killed build cannot deadlock the queue forever.

### cg

Drop-in for `cargo`. Budgets 2–4 GB per job depending on the subcommand
(`bench` and anything `--release` cost more, because this workspace sets
`lto = "fat"` + `codegen-units = 1`), clamps to 2..12 jobs, and takes the
`cargo` slot with `--max 1`.

```bash
cg build --release     # instead of: cargo build --release
CG_JOBS=4 cg bench     # force the job count
CG_GATE=0 cg check     # skip the queue
```

Sets `CARGO_BUILD_JOBS` rather than appending `--jobs`, so `cg run -- args` and
`cg test -- --nocapture` still work.

### memwatch

```bash
memwatch            # foreground
memwatch --once     # single sample
memwatch --report   # lowest-ever available, peak wired, spike list
```

Samples every 10s to `~/.local/state/memwatch/memwatch.tsv`. When available
memory drops below 6 GB (or swap exceeds 2 GB) it writes a full process
snapshot to `~/.local/state/memwatch/spikes/`. **That snapshot is the point** —
after the next OOM it says what actually ate the RAM instead of leaving you to
infer it from config.

Install as a LaunchAgent (`com.ozone.memwatch.plist`) so it is always on:

```bash
launchctl load ~/Library/LaunchAgents/com.ozone.memwatch.plist
launchctl unload ~/Library/LaunchAgents/com.ozone.memwatch.plist   # to stop
```

## Layout

- `memlib.sh` — shared sampling helpers, sourced by the rest
- `memtop`, `memdoctor`, `memgate`, `cg`, `memwatch` — symlinked into `~/.local/bin`
- state in `~/.local/state/memwatch/` (`memwatch.tsv`, `spikes/`, `slots/`)
