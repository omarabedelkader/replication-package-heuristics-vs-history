#!/usr/bin/env bash
# Can these projects be run? Each one is loaded in a fresh copy of the base image, the way a run starts
# (pharo/load-test.st), several at once. Nothing is completed and the store's results are not touched.
#
#   bin/load-test.sh PROJECT...            configuration selectors, e.g. magritte smacc
#   bin/load-test.sh --replay PROJECT...   stricter: runs the real experiment (pharo/run-project.st)
#                                          on 1/8 of the call sites for REPLAY_MINUTES (default 10)
#
# Loading is not enough: a project may load at its last commit but none of its older commits (no
# commit is replayed), or break the benchmark once loaded. --replay passes only if commits were
# replayed and call sites completed, with no "Experiment failed".
#
# One line per project goes to $STORE/load-test/results.txt (and the full log of each image to
# $STORE/load-test/<project>.log):
#   LOADTEST OK <project> commits=<replayable>/<window> packages=<n> <first packages>
#   LOADTEST FAIL <project>: <reason>          (TIMEOUT when it took more than LOADTEST_MINUTES)
# Environment: PARALLEL (default: cores - 2), LOADTEST_MINUTES (default 45).
set -uo pipefail
PKG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PKG/config.sh"
REPLAY=0; [ "${1:-}" = --replay ] && { REPLAY=1; shift; }
[ $# -gt 0 ] || { echo "usage: bin/load-test.sh [--replay] PROJECT..." >&2; exit 2; }
log() { echo "==> [$(date '+%F %T')] $*"; }

"$PKG/bin/prepare.sh" || exit 1
CORES="$(lscpu -p=core,socket 2>/dev/null | grep -v '^#' | sort -u | wc -l | tr -d ' ')"
[ "${CORES:-0}" -gt 0 ] || CORES="$(sysctl -n hw.physicalcpu 2>/dev/null || nproc)"
[ "$PARALLEL" -gt 0 ] 2>/dev/null || PARALLEL=$(( CORES > 4 ? CORES - 2 : CORES ))
MINUTES="${LOADTEST_MINUTES:-45}"
[ "$REPLAY" = 1 ] && MINUTES="${REPLAY_MINUTES:-10}"
OUT="$STORE/load-test"
LT="$WORK/load-test"
mkdir -p "$OUT" "$LT"

# The VM, the base image and the tool shims, as bin/run.sh sets them up.
VM_DIR="$STORE/base/vm-$(uname -s)-$(uname -m)"
rm -rf "$LT/pharo-vm"
cp -R "$VM_DIR/pharo-vm" "$VM_DIR/pharo" "$LT/"
cp "$STORE/base/bench-base.image" "$STORE/base/bench-base.changes" "$STORE/base/"*.sources "$LT/"
cp -n "$STORE/base/vm-libs/"* "$LT/pharo-vm/lib/" 2>/dev/null
mkdir -p "$LT/bin"
for tool in git gcc cc make curl wget unzip tar; do
  real="$(PATH="${PATH//$LT\/bin:/}" command -v "$tool")" || continue
  printf '#!/bin/sh\nunset LD_LIBRARY_PATH\nexec %s "$@"\n' "$real" > "$LT/bin/$tool"
  chmod +x "$LT/bin/$tool"
done

test_one() { # project
  local p="$1" dir="$LT/$1" line status
  rm -rf "$dir"; mkdir -p "$dir/tmp" "$dir/home"
  cp "$LT/bench-base.image" "$dir/run.image"; cp "$LT/bench-base.changes" "$dir/run.changes"
  cp -R "$LT/pharo-vm" "$dir/pharo-vm"; cp "$LT/pharo" "$dir/pharo"
  for sources in "$LT"/*.sources; do ln -s "$sources" "$dir/"; done
  sed -e "s|@PKG@|$PKG|g" "$PKG/pharo/update.st" > "$dir/update.st"
  sed -e "s|@PROJECT@|$p|g" "$PKG/pharo/load-test.st" > "$dir/load-test.st"
  mkdir -p "$dir/results"
  sed -e "s|@PROJECT@|$p|g" -e "s|@OUTPUT@|$dir/results|g" "$PKG/pharo/run-project.st" > "$dir/run.st"
  (
    cd "$dir" || exit 1
    export TMPDIR="$dir/tmp" HOME="$dir/home" PATH="$LT/bin:$PATH"
    export HVH_SLICE=0/8 HVH_CHECKPOINT_MINUTES=100000
    if [ "$REPLAY" = 1 ]; then exec timeout "${MINUTES}m" ./pharo run.image st --quit update.st run.st
    else exec timeout "${MINUTES}m" ./pharo run.image st --quit update.st load-test.st; fi
  ) 2>&1 | grep -av --line-buffered -e '^## Bench' -e '^# Running' > "$OUT/$p.log"
  status=${PIPESTATUS[0]}
  line="$(grep -a '^LOADTEST ' "$OUT/$p.log" | tail -1)"
  if [ "$REPLAY" = 1 ]; then
    local commits sites window
    commits="$(grep -ao 'Commit [0-9]*/[0-9]* done' "$OUT/$p.log" | tail -1 | cut -d' ' -f2)"
    window="$(grep -ao '^Replaying [0-9]*' "$OUT/$p.log" | head -1 | cut -d' ' -f2)"
    sites=$(( $(cat "$dir"/results/*-callsites.csv 2>/dev/null | wc -l) - 1 ))
    if grep -aq 'Experiment failed' "$OUT/$p.log"; then
      line="LOADTEST FAIL $p: experiment failed after ${commits:-no commit}: $(grep -a -A1 'Experiment failed' "$OUT/$p.log" | head -1 | cut -c1-160)"
    elif [ -z "$commits" ] || [ "$sites" -le 0 ]; then
      line="LOADTEST FAIL $p: nothing replayed in $MINUTES minutes (window ${window:-?}, $(grep -ac 'Error loading initial' "$OUT/$p.log") initial commits failed to load)"
    else
      line="LOADTEST OK $p replayed=$commits window=${window:-?} callsites=$sites (1/8, $MINUTES minutes)"
    fi
  fi
  if [ -z "$line" ]; then
    if [ "$status" = 124 ]; then line="LOADTEST FAIL $p: TIMEOUT after $MINUTES minutes"
    else line="LOADTEST FAIL $p: the image ended (exit $status) without an answer, see $OUT/$p.log"; fi
  fi
  echo "$line" >> "$OUT/results.txt"
  log "$line"
  rm -rf "$dir"
}

log "load test of $# project(s) on $(hostname), $PARALLEL at once, at most $MINUTES minutes each"
for p in "$@"; do
  while [ "$(jobs -rp | wc -l)" -ge "$PARALLEL" ]; do sleep 5; done
  test_one "$p" &
  sleep 2
done
wait
log "done: $(grep -c " OK " "$OUT/results.txt") OK, $(grep -c " FAIL " "$OUT/results.txt") FAIL in $OUT/results.txt"
