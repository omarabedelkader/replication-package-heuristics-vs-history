#!/usr/bin/env bash
# Run, or continue, the History experiment of every project, then aggregate the results once all of
# them are finished. Safe to start again at any moment (after a crash, at the next job, ...):
#   - a finished project ($STORE/state/<p>.done) is skipped;
#   - a project with a checkpoint ($STORE/checkpoints/<p>.tar.*) resumes at the commit after it;
#   - any other project starts from the base image.
#
#   bin/run.sh                      all projects
#   bin/run.sh microdown roassal    only these ones
#
# Every image runs in $WORK/projects/<p> with its own pharo-local, TMPDIR and results.
# Touching $WORK/checkpoint-request makes every image save a checkpoint after its current commit.
set -uo pipefail
PKG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PKG/config.sh"

if [ "$#" -gt 0 ]; then PROJECTS=("$@"); else PROJECTS=("${ALL_PROJECTS[@]}"); fi
[ "$PARALLEL" -gt 0 ] 2>/dev/null || PARALLEL="${#PROJECTS[@]}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-20}"   # jobs per project before it is declared failed (crash loop guard)

log() { echo "==> [$(date '+%F %T')] $*"; }

"$PKG/bin/prepare.sh" || exit 1

mkdir -p "$STORE/state" "$STORE/checkpoints" "$STORE/results" "$STORE/logs" "$WORK/projects"
VM_DIR="$STORE/base/vm-$(uname -s)-$(uname -m)"

# The VM and the base image are copied to the fast local disk once per machine.
if [ ! -f "$WORK/bench-base.image" ] || ! cmp -s "$STORE/base/versions.txt" "$WORK/versions.txt"; then
  log "Installing the VM and the base image in $WORK"
  rm -rf "$WORK/pharo-vm"
  cp -R "$VM_DIR/pharo-vm" "$VM_DIR/pharo" "$WORK/"
  cp "$STORE/base/bench-base.image" "$STORE/base/bench-base.changes" "$STORE/base/"*.sources "$WORK/"
  cp "$STORE/base/versions.txt" "$WORK/versions.txt"
fi

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

run_project() { # project
  local p="$1" dir="$WORK/projects/$1" plog="$STORE/logs/$1.log" archive attempts mode status out
  archive="$(archive_of "$p")"
  attempts=$(( $(cat "$STORE/state/$p.attempts" 2>/dev/null || echo 0) + 1 ))
  echo "$attempts" > "$STORE/state/$p.attempts"

  rm -rf "$dir"
  if [ -n "$archive" ]; then
    mode=resume
    if ! decompress "$archive" | tar -xf - -C "$WORK/projects"; then
      log "FAILED $p: cannot extract $archive"; return
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
  # Links to the VM are (re)made on every machine.
  rm -f "$dir/pharo" "$dir/pharo-vm" "$dir"/*.sources
  ln -s "$WORK/pharo" "$dir/pharo"; ln -s "$WORK/pharo-vm" "$dir/pharo-vm"
  for sources in "$WORK"/*.sources; do ln -s "$sources" "$dir/"; done

  log "$mode $p (attempt $attempts, log: $plog)"
  echo "======== $(date '+%F %T') $mode on $(hostname) (attempt $attempts)" >> "$plog"
  (
    cd "$dir" || exit 1
    export TMPDIR="$dir/tmp"
    # One HOME per image: some baselines write in ~/Documents (TreeSitter clones its grammars
    # there), and images running side by side must not share it.
    mkdir -p "$dir/home"; export HOME="$dir/home"
    export PATH="$WORK/bin:$PATH"
    export HVH_CHECKPOINT_MINUTES="$CHECKPOINT_MINUTES"
    export HVH_CHECKPOINT_REQUEST="$WORK/checkpoint-request"
    export HVH_CHECKPOINT_HOOK="'$PKG/bin/save-checkpoint.sh' '$p'"
    # A resumed image goes on with its saved process; 'st update.st' only reloads the additions, and
    # without --quit the image stays open meanwhile.
    if [ "$mode" = start ]; then exec ./pharo run.image st --quit update.st run.st
    else exec ./pharo run.image st update.st; fi
  ) >> "$plog" 2>&1
  status=$?

  if ls "$dir/results/"*-results.ston >/dev/null 2>&1; then
    out="$(results_of "$p")"; mkdir -p "$(dirname "$out")"
    rm -rf "$out.tmp"
    cp -R "$dir/results" "$out.tmp"
    rm -rf "$out"; mv "$out.tmp" "$out"
    touch "$STORE/state/$p.done"
    rm -f "$STORE/checkpoints/$p".tar.*
    rm -rf "$dir"
    log "done   $p"
  elif [ "$attempts" -lt "$MAX_ATTEMPTS" ] && snapshot_crashed "$plog"; then
    # The image died while saving a checkpoint (before HVH-Replication set aside the session
    # handlers of removed classes): not a failure of the experiment. It resumes from the previous
    # checkpoint, or starts again, at the next run.
    log "stopped $p (exit $status) while saving a checkpoint: it continues at the next run"
  elif [ "$status" = 1 ] || [ "$attempts" -ge "$MAX_ATTEMPTS" ]; then
    # exit 1 = the experiment itself signalled an error (see run-project.st): running it again gives the same.
    touch "$STORE/state/$p.failed"
    log "FAILED $p (exit $status, attempt $attempts), see $plog"
  else
    log "stopped $p (exit $status): it continues from its last checkpoint at the next run"
  fi
}

todo=()
for p in "${PROJECTS[@]}"; do
  if [ -f "$STORE/state/$p.done" ]; then continue; fi
  if [ -f "$STORE/state/$p.failed" ]; then
    [ "$RETRY_FAILED" = 1 ] || continue
    rm -f "$STORE/state/$p.failed" "$STORE/state/$p.attempts"
  fi
  todo+=("$p")
done
log "${#todo[@]} project(s) to run, $PARALLEL at a time: ${todo[*]:-none}"

for p in "${todo[@]}"; do
  while [ "$(jobs -rp | wc -l)" -ge "$PARALLEL" ]; do sleep 10; done
  run_project "$p" &
  sleep 2
done
wait

"$PKG/bin/status.sh"
remaining=0
for p in "${ALL_PROJECTS[@]}"; do
  [ -f "$STORE/state/$p.done" ] || [ -f "$STORE/state/$p.failed" ] || remaining=$((remaining + 1))
done
if [ "$remaining" = 0 ]; then
  "$PKG/bin/summarize.sh"
else
  log "$remaining project(s) not finished yet: run this again (or resubmit the job) to continue."
fi
