#!/usr/bin/env bash
# memlib.sh — shared memory-inspection helpers for the memctl toolkit.
#
# Sourced by: memtop, memwatch, memgate, cg
#
# macOS note: "free RAM" is a meaningless number here. The kernel deliberately
# keeps free pages near zero by filling them with cache. The metrics that
# actually predict an OOM are:
#   - available  = free + inactive + purgeable   (reclaimable without swapping)
#   - wired      = pinned, NOT reclaimable, NOT compressible  (GPU/ComfyUI lives here)
#   - compressor = pages the VM had to compress  (real pressure has begun)
#   - swapins    = pages read back from disk     (pressure is hurting)

MEM_PAGE_SIZE="$(sysctl -n hw.pagesize)"
MEM_TOTAL_MB=$(( $(sysctl -n hw.memsize) / 1048576 ))

# Populate MEM_* globals from a single vm_stat call.
# Sets: MEM_AVAILABLE_MB MEM_WIRED_MB MEM_COMPRESSED_MB MEM_ACTIVE_MB MEM_FREE_MB
mem_sample() {
  local free inactive purgeable wired compressed active

  # One vm_stat call; strip trailing dots. Missing keys default to 0 so this
  # degrades gracefully across macOS versions rather than emitting empty math.
  eval "$(vm_stat | awk -F: '
    function clean(v) { gsub(/[ .]/, "", v); return v == "" ? 0 : v }
    /^Pages free/                  { print "free="       clean($2) }
    /^Pages inactive/              { print "inactive="   clean($2) }
    /^Pages purgeable/             { print "purgeable="  clean($2) }
    /^Pages wired down/            { print "wired="      clean($2) }
    /^Pages active/                { print "active="     clean($2) }
    /^Pages occupied by compressor/{ print "compressed=" clean($2) }
  ')"

  free=${free:-0}; inactive=${inactive:-0}; purgeable=${purgeable:-0}
  wired=${wired:-0}; active=${active:-0}; compressed=${compressed:-0}

  local to_mb=$(( MEM_PAGE_SIZE / 1024 ))
  MEM_FREE_MB=$(( free * to_mb / 1024 ))
  MEM_AVAILABLE_MB=$(( (free + inactive + purgeable) * to_mb / 1024 ))
  MEM_WIRED_MB=$(( wired * to_mb / 1024 ))
  MEM_ACTIVE_MB=$(( active * to_mb / 1024 ))
  MEM_COMPRESSED_MB=$(( compressed * to_mb / 1024 ))
}

# Swap bytes currently in use, in MB.
mem_swap_used_mb() {
  sysctl -n vm.swapusage | awk '{
    v = $6; sub(/M$/, "", v); sub(/G$/, "", v)
    if ($6 ~ /G$/) v = v * 1024
    printf "%d", v
  }'
}

# Resident set of every process, grouped into human-meaningful families.
# Firefox alone is ~10 processes; per-process output hides the real total.
mem_by_family() {
  /bin/ps -Ao rss=,comm= | awk '
    {
      rss = $1
      $1 = ""
      cmd = substr($0, 2)

      if      (cmd ~ /Firefox/)                 fam = "Firefox"
      else if (cmd ~ /rust-analyzer/)           fam = "rust-analyzer"
      else if (cmd ~ /Antigravity/)             fam = "Antigravity IDE"
      else if (cmd ~ /Zed|zed/)                 fam = "Zed"
      else if (cmd ~ /ollama/)                  fam = "ollama"
      else if (cmd ~ /ComfyUI|python|Python/)   fam = "python/ComfyUI"
      else if (cmd ~ /rustc|cargo|ld$|lto/)     fam = "rustc/cargo"
      else if (cmd ~ /node|npx/)                fam = "node"
      else if (cmd ~ /claude|codex|grok/)       fam = "AI agents"
      else if (cmd ~ /ffmpeg/)                  fam = "ffmpeg"
      else if (cmd ~ /Docker|com.docker/)       fam = "Docker"
      else                                      fam = "other"

      total[fam] += rss
      count[fam] += 1
    }
    END { for (f in total) printf "%d\t%d\t%s\n", total[f]/1024, count[f], f }
  ' | sort -rn
}

# Largest single processes, for when a family total needs a culprit.
mem_top_processes() {
  local n="${1:-10}"
  /bin/ps -Ao rss=,pid=,comm= | sort -rn | head -"$n" | awk '{
    rss = $1; pid = $2; $1 = ""; $2 = ""
    printf "%d\t%s\t%s\n", rss/1024, pid, substr($0, 3)
  }'
}

mem_fmt_gb() { awk -v mb="$1" 'BEGIN { printf "%.1f GB", mb/1024 }'; }
