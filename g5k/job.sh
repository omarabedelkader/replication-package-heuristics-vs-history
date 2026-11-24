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

# One job may hold several nodes (g5k/submit.sh with HOSTS > 1): a bin/run.sh worker on each, all
# sharing the store (a worker claims units). Several jobs can share the store as well.
mapfile -t NODES_OF_JOB < <(sort -u "${OAR_NODEFILE:-/dev/null}" 2>/dev/null)
[ "${#NODES_OF_JOB[@]}" -gt 0 ] || NODES_OF_JOB=("$(hostname)")
is_here() { [ "$1" = "$(hostname)" ] || [ "${1%%.*}" = "$(hostname -s)" ]; }
echo "    nodes: ${NODES_OF_JOB[*]}"

# The settings a remote worker must see as this script does (oarsh starts a fresh environment).
FORWARD=""
for v in OAR_JOB_ID EXTRA PAIRED PARALLEL CORES STORE WORK MIN_FREE_GB CHECKPOINT_MINUTES \
         RETRY_FAILED MAX_ATTEMPTS HCH_REPO HCH_BRANCH HCH_COMMIT HCB_REPO HCB_COMMIT PHARO_URL; do
  [ -n "${!v+x}" ] && FORWARD+=" $v=$(printf %q "${!v}")"
done

request_checkpoint() {
  echo "==> [$(date +%T)] Walltime is near: asking every image of every node for a checkpoint"
  for node in "${NODES_OF_JOB[@]}"; do
    if is_here "$node"; then touch "$WORK/checkpoint-request"
    else oarsh "$node" "touch $(printf %q "$WORK/checkpoint-request")" & fi
  done
}
trap request_checkpoint USR2

# Use most of each node: one image per core (bin/run.sh).
pids=()
for node in "${NODES_OF_JOB[@]}"; do
  if is_here "$node"; then
    "$PKG/bin/run.sh" &
  else
    echo "    worker on $node: output in $STORE/oar/${OAR_JOB_ID:-local}-${node%%.*}.out"
    oarsh "$node" "env$FORWARD $(printf %q "$PKG/bin/run.sh")" \
      > "$STORE/oar/${OAR_JOB_ID:-local}-${node%%.*}.out" 2>&1 < /dev/null &
  fi
  pids+=($!)
done
# `wait` returns early when a signal is trapped: wait again until every worker really ends.
status=0
for pid in "${pids[@]}"; do
  s=0
  while kill -0 "$pid" 2>/dev/null; do wait "$pid"; s=$?; done
  [ "$s" -eq 0 ] || status=$s
done
exit "$status"
