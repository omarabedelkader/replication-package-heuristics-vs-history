#!/usr/bin/env bash
# The OAR job (submitted by g5k/submit.sh): runs or continues bin/run.sh on the reserved node.
# OAR sends SIGUSR2 to this script --checkpoint seconds before the walltime: every image is then
# asked to save a checkpoint after its current commit, so that the next job loses almost nothing.
set -uo pipefail
PKG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PKG/config.sh"
mkdir -p "$STORE" "$WORK"

echo "==> Job ${OAR_JOB_ID:-?} on $(hostname): $(nproc) cores, $(free -g | awk '/Mem:/ {print $2}') GiB"
echo "    STORE=$STORE  WORK=$WORK  PACKAGE=$PKG"

# One job at a time on the store: two jobs would resume the same checkpoints twice.
LOCK="$STORE/job.lock"
if [ -f "$LOCK" ]; then
  other="$(cat "$LOCK")"
  if [ "$other" != "${OAR_JOB_ID:-}" ] && oarstat -j "$other" -s 2>/dev/null | grep -q Running; then
    echo "Job $other is still running on this store; nothing to do." >&2
    exit 0
  fi
fi
echo "${OAR_JOB_ID:-$$}" > "$LOCK"

request_checkpoint() {
  echo "==> [$(date +%T)] Walltime is near: asking every image for a checkpoint"
  touch "$WORK/checkpoint-request"
}
trap request_checkpoint USR2

# Use most of the node: every project at once (30 images, one core each).
"$PKG/bin/run.sh" &
pid=$!
# `wait` returns early when a signal is trapped: wait again until bin/run.sh really ends.
while kill -0 "$pid" 2>/dev/null; do wait "$pid"; status=$?; done
rm -f "$LOCK"
exit "${status:-0}"
