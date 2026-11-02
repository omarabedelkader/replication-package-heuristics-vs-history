#!/usr/bin/env bash
# One-off helper for job 4236248, whose bin/run.sh started before the snapshot fix: every 2 minutes,
# restart (with the current bin/run.sh) any project it marked failed because its image died while
# saving a checkpoint. Later jobs do not need it: bin/run.sh itself no longer counts that as a failure.
PKG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PKG/config.sh"
while true; do
  for f in "$STORE"/state/*.failed; do
    [ -e "$f" ] || continue
    p="$(basename "$f" .failed)"
    if awk '/^======== /{seg=""} {seg=seg $0 "\n"} END{printf "%s", seg}' "$STORE/logs/$p.log" \
         | grep -aq 'SnapshotOperation>>performSnapshot'; then
      echo "==> [$(date '+%F %T')] restarting $p (its image died while saving a checkpoint)"
      rm -f "$f"
      "$PKG/bin/run.sh" "$p" &
    fi
  done
  sleep 120
done
