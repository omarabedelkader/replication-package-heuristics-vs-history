#!/usr/bin/env bash
# The OAR job (submitted by g5k/submit.sh): a bin/run.sh worker on the reserved node.
# OAR sends SIGUSR2 to this script --checkpoint seconds before the walltime: every image is then
# asked to save a checkpoint after its current commit, so that the next job loses almost nothing.
set -uo pipefail
PKG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PKG/config.sh"
mkdir -p "$STORE" "$WORK"

echo "==> Job ${OAR_JOB_ID:-?} on $(hostname): $(nproc) cores, $(free -g | awk '/Mem:/ {print $2}') GiB"
echo "    STORE=$STORE  WORK=$WORK  PACKAGE=$PKG"

# Several jobs (one per node) can share the store: bin/run.sh is a worker that claims units.
request_checkpoint() {
  echo "==> [$(date +%T)] Walltime is near: asking every image for a checkpoint"
  touch "$WORK/checkpoint-request"
}
trap request_checkpoint USR2

# Use most of the node: one image per core (bin/run.sh).
"$PKG/bin/run.sh" &
pid=$!
# `wait` returns early when a signal is trapped: wait again until bin/run.sh really ends.
while kill -0 "$pid" 2>/dev/null; do wait "$pid"; status=$?; done
exit "${status:-0}"
