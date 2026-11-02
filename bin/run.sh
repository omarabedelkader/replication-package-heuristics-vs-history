#!/usr/bin/env bash
# Run, or continue, the History experiment of every project, then aggregate the results once all of
# them are finished. Every project is split into units (config.sh: one per strategy and slice of the
# call sites); this script is a worker that runs units in parallel images on this machine until no
# unit is left. Several workers can share one $STORE (one per machine, e.g. one per Grid'5000 node):
# a unit is claimed by creating the directory $STORE/claims/<unit>, which is atomic on NFS too.
# Safe to start again at any moment (after a crash, at the next job, ...):
#   - a finished unit ($STORE/state/<unit>.done) is skipped;
#   - a unit with a checkpoint ($STORE/checkpoints/<unit>.tar.*) resumes at the commit after it;
#   - any other unit starts from the base image.
# When the last unit of a project is done, bin/merge-units.py joins them into the project's results.
#
#   bin/run.sh                      all projects
#   bin/run.sh microdown roassal    only these ones
#
# Every image runs in $WORK/units/<unit> with its own pharo-local, HOME, TMPDIR and results.
# Touching $WORK/checkpoint-request makes every image save a checkpoint after its current commit.
set -uo pipefail
PKG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PKG/config.sh"

if [ "$#" -gt 0 ]; then PROJECTS=("$@"); else PROJECTS=("${ALL_PROJECTS[@]}"); fi
# Physical cores, not hardware threads: two images on one core would slow each other down, and
# every completion's time is measured.
CORES="$(lscpu -p=core,socket 2>/dev/null | grep -v '^#' | sort -u | wc -l | tr -d ' ')"
[ "${CORES:-0}" -gt 0 ] || CORES="$(sysctl -n hw.physicalcpu 2>/dev/null || nproc)"
[ "$PARALLEL" -gt 0 ] 2>/dev/null || PARALLEL=$(( CORES > 4 ? CORES - 2 : CORES ))
MAX_ATTEMPTS="${MAX_ATTEMPTS:-20}"   # runs of a unit before it is declared failed (crash loop guard)
# A claim names its worker: <OAR job or "local">@<host>:<pid>.
OWNER="${OAR_JOB_ID:-local}@$(hostname):$$"

log() { echo "==> [$(date '+%F %T')] $*"; }

"$PKG/bin/prepare.sh" || exit 1

mkdir -p "$STORE/state" "$STORE/checkpoints" "$STORE/units" "$STORE/logs" "$STORE/claims" "$WORK/units"
VM_DIR="$STORE/base/vm-$(uname -s)-$(uname -m)"

# The VM and the base image are copied to the fast local disk once per machine.
if [ ! -f "$WORK/bench-base.image" ] || ! cmp -s "$STORE/base/versions.txt" "$WORK/versions.txt"; then
  log "Installing the VM and the base image in $WORK"
  rm -rf "$WORK/pharo-vm"
  cp -R "$VM_DIR/pharo-vm" "$VM_DIR/pharo" "$WORK/"
  cp "$STORE/base/bench-base.image" "$STORE/base/bench-base.changes" "$STORE/base/"*.sources "$WORK/"
  cp "$STORE/base/versions.txt" "$WORK/versions.txt"
fi

# Libraries that baselines build into the VM's lib/ (the TreeSitter grammars) are kept in
# $STORE/base/vm-libs and given to every VM: the baseline then finds them and skips building them,
# which asks the GitHub API for the latest release (60 requests an hour per address, shared by all
# the images of a cluster). Same release, so nothing measured changes.
share_vm_libs() { # directory of a VM lib/ to harvest from
  mkdir -p "$STORE/base/vm-libs"
  local f
  for f in "$1"/libtree-sitter*; do
    [ -f "$f" ] && [ ! -e "$STORE/base/vm-libs/$(basename "$f")" ] && cp "$f" "$STORE/base/vm-libs/"
  done
  return 0
}
mkdir -p "$STORE/base/vm-libs"
cp -n "$STORE/base/vm-libs/"* "$WORK/pharo-vm/lib/" 2>/dev/null

# The VM launcher puts its own lib/ (an old libssh2, libgit2, libcrypto...) first in LD_LIBRARY_PATH,
# and every command an image runs inherits it: the system git then crashes ("undefined symbol:
# libssh2_session_set_read_timeout"). TreeSitter's postLoad runs `git clone`, for example.
# These shims run the system tools with the system libraries.
mkdir -p "$WORK/bin"
for tool in git gcc cc make curl wget unzip tar; do
  real="$(PATH="${PATH//$WORK\/bin:/}" command -v "$tool")" || continue
  printf '#!/bin/sh\nunset LD_LIBRARY_PATH\nexec %s "$@"\n' "$real" > "$WORK/bin/$tool"
  chmod +x "$WORK/bin/$tool"
done

# Release the claims of workers that are gone: a worker of this machine whose process ended, or a
# worker of an OAR job that is not running any more. Without an answer from oarstat, the claims of
# other machines are kept.
running_jobs="$(oarstat -u -J 2>/dev/null | python3 -c 'import json, sys
try: print(" ".join(k for k, v in json.load(sys.stdin).items() if v.get("state") == "Running"))
except Exception: pass' 2>/dev/null)"
for claim in "$STORE/claims"/*/; do
  [ -d "$claim" ] || continue
  owner="$(cat "$claim/owner" 2>/dev/null)"
  job="${owner%%@*}"; where="${owner#*@}"; host="${where%%:*}"; pid="${where##*:}"
  if [ "$host" = "$(hostname)" ]; then
    kill -0 "$pid" 2>/dev/null || rm -rf "$claim"
  elif [ "$job" != local ] && [ -n "$running_jobs" ]; then
    case " $running_jobs " in *" $job "*) ;; *) rm -rf "$claim" ;; esac
  fi
done

claim() { # name: atomically take $STORE/claims/<name>
  mkdir "$STORE/claims/$1" 2>/dev/null || return 1
  echo "$OWNER" > "$STORE/claims/$1/owner"
}

release() { # name: give back a claim of this worker (never another worker's)
  [ "$(cat "$STORE/claims/$1/owner" 2>/dev/null)" = "$OWNER" ] && rm -rf "$STORE/claims/$1"
  return 0
}

archive_of() { ls "$STORE/checkpoints/$1".tar.* 2>/dev/null | head -1; }

decompress() { # archive
  case "$1" in
    *.zst) zstd -dc -q "$1" ;;
    *.gz) gzip -dc "$1" ;;
  esac
}

snapshot_crashed() { # log: did the last attempt die inside a snapshot?
  awk '/^======== /{seg=""} {seg=seg $0 "\n"} END{printf "%s", seg}' "$1" \
    | grep -aq 'SnapshotOperation>>performSnapshot'
}

started_replay() { # log: did the last attempt replay at least one commit?
  awk '/^======== /{seg=""} {seg=seg $0 "\n"} END{printf "%s", seg}' "$1" | grep -aq '\[hvh .*Commit [0-9]*/'
}

free_gb() { awk '/MemAvailable/ {print int($2 / 1048576)}' /proc/meminfo 2>/dev/null || echo 999; }

unit_finished() { [ -f "$STORE/state/$1.done" ] || [ -f "$STORE/state/$1.failed" ]; }

merge_if_complete() { # project: once all its units are done, join them into its results
  local p="$1" u units
  [ -f "$STORE/state/$p.done" ] || [ -f "$STORE/state/$p.failed" ] && return 0
  units=($(units_of "$p"))
  for u in "${units[@]}"; do unit_finished "$u" || return 0; done
  claim "merge-$p" || return 0
  for u in "${units[@]}"; do
    if [ -f "$STORE/state/$u.failed" ]; then
      touch "$STORE/state/$p.failed"; log "FAILED $p: its unit $u failed"
      release "merge-$p"; return 0
    fi
  done
  if python3 "$PKG/bin/merge-units.py" "$(results_of "$p")" "${units[@]/#/$STORE/units/}" >> "$STORE/logs/merge.log" 2>&1; then
    touch "$STORE/state/$p.done"; log "done   $p: ${#units[@]} unit(s) merged into $(results_of "$p")"
  else
    touch "$STORE/state/$p.failed"; log "FAILED $p: merge failed, see $STORE/logs/merge.log"
  fi
  release "merge-$p"
}

run_unit() { # unit
  local u="$1" p dir="$WORK/units/$1" plog="$STORE/logs/$1.log" archive attempts mode status
  p="$(project_of "$u")"
  archive="$(archive_of "$u")"
  attempts=$(( $(cat "$STORE/state/$u.attempts" 2>/dev/null || echo 0) + 1 ))
  echo "$attempts" > "$STORE/state/$u.attempts"

  rm -rf "$dir"
  if [ -n "$archive" ]; then
    mode=resume
    if ! decompress "$archive" | tar -xf - -C "$WORK/units"; then
      log "FAILED $u: cannot extract $archive"; touch "$STORE/state/$u.failed"
      release "$u"; return
    fi
  else
    mode=start
    mkdir -p "$dir/results" "$dir/tmp" "$dir/home"
    cp "$WORK/bench-base.image" "$dir/run.image"
    cp "$WORK/bench-base.changes" "$dir/run.changes"
    sed -e "s|@PROJECT@|$p|g" -e "s|@OUTPUT@|$dir/results|g" "$PKG/pharo/run-project.st" > "$dir/run.st"
  fi
  # Both a fresh and a resumed image first reload the current additions (pharo/update.st).
  sed -e "s|@PKG@|$PKG|g" "$PKG/pharo/update.st" > "$dir/update.st"
  # Every image has its own copy of the VM (40 MB): some baselines install files in its lib/ (the
  # TreeSitter grammars), and images side by side would collide there. The copy is archived with
  # a checkpoint, so the files a baseline installed are still there when the image is resumed.
  if [ -L "$dir/pharo-vm" ] || [ ! -d "$dir/pharo-vm" ]; then
    rm -f "$dir/pharo-vm"; cp -R "$WORK/pharo-vm" "$dir/pharo-vm"
  fi
  rm -f "$dir/pharo" "$dir"/*.sources
  cp "$WORK/pharo" "$dir/pharo"
  for sources in "$WORK"/*.sources; do ln -s "$sources" "$dir/"; done

  log "$mode $u: $(strategy_of "$u"), slice $(slice_of "$u") (attempt $attempts)"
  echo "======== $(date '+%F %T') $mode on $(hostname) (attempt $attempts)" >> "$plog"
  (
    cd "$dir" || exit 1
    export TMPDIR="$dir/tmp"
    # One HOME per image: some baselines write in ~/Documents (TreeSitter clones its grammars
    # there), and images running side by side must not share it.
    mkdir -p "$dir/home"; export HOME="$dir/home"
    export PATH="$WORK/bin:$PATH"
    export HVH_STRATEGY="$(strategy_of "$u")" HVH_SLICE="$(slice_of "$u")"
    export HVH_CHECKPOINT_MINUTES="$CHECKPOINT_MINUTES"
    export HVH_CHECKPOINT_REQUEST="$WORK/checkpoint-request"
    export HVH_CHECKPOINT_HOOK="'$PKG/bin/save-checkpoint.sh' '$u'"
    # A resumed image goes on with its saved process; 'st update.st' only reloads the additions, and
    # without --quit the image stays open meanwhile.
    if [ "$mode" = start ]; then exec ./pharo run.image st --quit update.st run.st
    else exec ./pharo run.image st update.st; fi
  ) 2>&1 | grep -av --line-buffered -e '^## Bench' -e '^# Running' >> "$plog"
  # The benchmark prints one line per call site and strategy (gigabytes for a big project): only
  # these lines are left out of the log.
  status=${PIPESTATUS[0]}

  share_vm_libs "$dir/pharo-vm/lib"
  if ls "$dir/results/"*-results.ston >/dev/null 2>&1; then
    rm -rf "$STORE/units/$u.tmp"
    cp -R "$dir/results" "$STORE/units/$u.tmp"
    rm -rf "$STORE/units/$u"; mv "$STORE/units/$u.tmp" "$STORE/units/$u"
    touch "$STORE/state/$u.done"
    rm -f "$STORE/checkpoints/$u".tar.*
    rm -rf "$dir"
    log "done   $u"
  elif [ "$attempts" -lt "$MAX_ATTEMPTS" ] && snapshot_crashed "$plog"; then
    # The image died while saving a checkpoint: not a failure of the experiment. It resumes from
    # the previous checkpoint, or starts again.
    log "stopped $u (exit $status) while saving a checkpoint: it will continue"
  elif [ "$attempts" -lt 8 ] && ! started_replay "$plog"; then
    # Failed while loading the project, before its first commit: most often the network (a clone
    # from GitHub fails with "SSL error" when hundreds of images clone at once). Tried again, up to
    # 8 times, after a random pause so that the retries do not all clone at the same moment.
    log "stopped $u (exit $status) while loading the project: it will be tried again"
    sleep $(( 30 + RANDOM % 120 ))
  elif [ "$status" = 1 ] || [ "$attempts" -ge "$MAX_ATTEMPTS" ]; then
    # exit 1 = the experiment itself signalled an error (see run-project.st): running it again gives the same.
    touch "$STORE/state/$u.failed"
    log "FAILED $u (exit $status, attempt $attempts), see $plog"
  else
    log "stopped $u (exit $status): it continues from its last checkpoint"
  fi
  release "$u"
  merge_if_complete "$p"
}

# The units: the biggest projects first (config.sh lists them so) and, within a project, slice by slice.
todo=()
for p in "${PROJECTS[@]}"; do
  if [ -f "$STORE/state/$p.done" ]; then continue; fi
  if [ -f "$STORE/state/$p.failed" ]; then
    [ "$RETRY_FAILED" = 1 ] || continue
    rm -f "$STORE/state/$p.failed"
    for u in $(units_of "$p"); do rm -f "$STORE/state/$u.failed" "$STORE/state/$u.attempts"; done
  fi
  for u in $(units_of "$p"); do todo+=("$u"); done
done
log "worker $OWNER on $(hostname): ${#todo[@]} unit(s) of ${#PROJECTS[@]} project(s) to share, up to $PARALLEL image(s) here"

while true; do
  waiting=0
  for u in "${todo[@]}"; do
    unit_finished "$u" && continue
    [ -d "$STORE/claims/$u" ] && continue
    waiting=$((waiting + 1))
    [ "$(jobs -rp | wc -l)" -lt "$PARALLEL" ] || continue
    [ "$(free_gb)" -ge "$MIN_FREE_GB" ] || continue
    claim "$u" || continue
    run_unit "$u" &
    sleep 1
  done
  # Nothing left to claim and nothing running here: this worker is done.
  if [ "$waiting" = 0 ] && [ "$(jobs -rp | wc -l)" = 0 ]; then break; fi
  sleep 15
done
wait

for p in "${PROJECTS[@]}"; do merge_if_complete "$p"; done
"$PKG/bin/status.sh"
remaining=0
for p in "${ALL_PROJECTS[@]}"; do
  [ -f "$STORE/state/$p.done" ] || [ -f "$STORE/state/$p.failed" ] || remaining=$((remaining + 1))
done
if [ "$remaining" = 0 ]; then
  if claim summary; then "$PKG/bin/summarize.sh"; release summary; fi
else
  log "$remaining project(s) not finished yet (other workers may still be running them)."
fi
