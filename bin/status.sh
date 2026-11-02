#!/usr/bin/env bash
# Where every project stands: done, failed, checkpointed, started (running or interrupted before its
# first checkpoint) or not started, with its last replayed commit.
PKG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PKG/config.sh"

done=0; failed=0; partial=0; fresh=0
printf '%-18s %-13s %-9s %s\n' PROJECT STATE ATTEMPTS "LAST PROGRESS"
for p in "${ALL_PROJECTS[@]}"; do
  attempts="$(cat "$STORE/state/$p.attempts" 2>/dev/null || echo 0)"
  progress="$(grep -a '\[hvh .*Commit [0-9]*/[0-9]* done' "$STORE/logs/$p.log" 2>/dev/null | tail -1 | sed 's/.*Commit /commit /; s/ done//')"
  if [ -f "$STORE/state/$p.done" ]; then state=done; done=$((done + 1))
  elif [ -f "$STORE/state/$p.failed" ]; then state=FAILED; failed=$((failed + 1))
  elif ls "$STORE/checkpoints/$p".tar.* >/dev/null 2>&1; then state=checkpointed; partial=$((partial + 1))
  elif [ "$attempts" -gt 0 ]; then state=started; partial=$((partial + 1))
  else state=to-start; fresh=$((fresh + 1)); fi
  printf '%-18s %-13s %-9s %s\n' "$p" "$state" "$attempts" "$progress"
done
echo
echo "done: $done   failed: $failed   in progress: $partial   not started: $fresh"
du -sh "$STORE" 2>/dev/null | sed 's/^/store size: /'
