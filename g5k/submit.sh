#!/usr/bin/env bash
# Reserve a whole CPU node (no GPU) of the current Grid'5000 site and run g5k/job.sh on it.
# Run it on the frontend of the site whose home holds $STORE (by default: Rennes).
#
#   g5k/submit.sh                         tonight 19:00, 14 h (ends at 09:00 the next morning)
#   g5k/submit.sh "2026-11-03 19:00:00"   another start
#   g5k/submit.sh now                     as soon as possible (no advance reservation)
#   NIGHTS=3 g5k/submit.sh                tonight and the 2 following nights, 19:00 -> 09:00
#
# Submitting again is how an unfinished replication continues: every job resumes the checkpoints.
#
# Environment variables:
#   EXTRA       1 (default): the paper's 30 projects and the 24 extra ones; 0: the 30 only
#   WALLTIME    default 14:00:00
#   NODES       candidate "queue:cluster" pairs, tried in this order until one is accepted.
#               Default (Rennes): default:paradoxe  2 x Xeon Gold 5320, 52 cores, 384 GiB, no GPU.
#               The abaca queue refuses advance reservations, so its nodes (roazhon15: 128 Zen 5
#               cores) are only usable with `now`: NODES="abaca:roazhon15" g5k/submit.sh now
#               On Lille: NODES="default:chirop" (but the store must then live on Lille's home).
set -euo pipefail
PKG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PKG/config.sh"

START="${1:-$(date +%F) 19:00:00}"
WALLTIME="${WALLTIME:-14:00:00}"
NIGHTS="${NIGHTS:-1}"
read -r -a CANDIDATES <<< "${NODES:-default:paradoxe}"
mkdir -p "$STORE/oar"
chmod +x "$PKG"/bin/*.sh "$PKG"/g5k/*.sh

submit_one() { # start|now
  local start="$1" candidate queue cluster out
  for candidate in "${CANDIDATES[@]}"; do
    queue="${candidate%%:*}"; cluster="${candidate#*:}"
    args=(-q "$queue" -p "cluster='$cluster'" -l "host=1,walltime=$WALLTIME"
          --checkpoint 1800 -n hvh-replication
          -O "$STORE/oar/%jobid%.out" -E "$STORE/oar/%jobid%.err")
    [ "$start" = now ] || args+=(-r "$start")
    echo "--> $cluster ($queue queue), start: $start, walltime: $WALLTIME"
    if out="$(oarsub "${args[@]}" "env EXTRA=${EXTRA:-1} $PKG/g5k/job.sh" 2>&1)" \
       && ! grep -qiE "KO|not valid|error|rejected|denied" <<< "$out"; then
      echo "$out" | sed 's/^/    /'
      echo "    Accepted. Job output: $STORE/oar/<jobid>.out, progress: bin/status.sh"
      return 0
    fi
    echo "$out" | sed 's/^/    /'
    echo "    Not accepted, trying the next candidate."
  done
  echo "No candidate node accepted the job (start: $start)." >&2
  return 1
}

if [ "$START" = now ]; then submit_one now; exit; fi
day="${START%% *}"; time="${START#* }"
for ((n = 0; n < NIGHTS; n++)); do
  start="$(date -d "$day + $n day" +%F) $time"
  submit_one "$start" || true
done
