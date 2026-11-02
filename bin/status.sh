#!/usr/bin/env bash
# Where every project stands: its units done / running (claimed) / failed / to start, and the
# least advanced running unit ("commit x/y" of its replay).
PKG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PKG/config.sh"

pdone=0; pfailed=0; tdone=0; trun=0; tfail=0; ttotal=0
printf '%-20s %-8s %6s %6s %6s %6s  %s\n' PROJECT STATE UNITS DONE RUN FAILED "LEAST ADVANCED RUNNING UNIT"
for p in "${ALL_PROJECTS[@]}"; do
  n=0; d=0; r=0; f=0; slowest=""; slowest_value=2
  for u in $(units_of "$p"); do
    n=$((n + 1))
    if [ -f "$STORE/state/$u.done" ] || [ -f "$STORE/state/$p.done" ]; then d=$((d + 1))
    elif [ -f "$STORE/state/$u.failed" ]; then f=$((f + 1))
    elif [ -d "$STORE/claims/$u" ]; then
      r=$((r + 1))
      progress="$(grep -a '\[hvh .*Commit [0-9]*/[0-9]* done' "$STORE/logs/$u.log" 2>/dev/null | tail -1 | sed 's/.*Commit //; s/ done//')"
      value="$(awk -F/ -v p="${progress:-0/1}" 'BEGIN { split(p, a, "/"); print a[1] / a[2] }')"
      if awk -v a="$value" -v b="$slowest_value" 'BEGIN { exit !(a < b) }'; then
        slowest_value="$value"; slowest="$u commit ${progress:-0 (loading)}"
      fi
    fi
  done
  if [ -f "$STORE/state/$p.done" ]; then state=done; pdone=$((pdone + 1))
  elif [ -f "$STORE/state/$p.failed" ]; then state=FAILED; pfailed=$((pfailed + 1))
  elif [ "$r" -gt 0 ] || [ "$d" -gt 0 ]; then state=running
  else state=to-start; fi
  tdone=$((tdone + d)); trun=$((trun + r)); tfail=$((tfail + f)); ttotal=$((ttotal + n))
  printf '%-20s %-8s %6s %6s %6s %6s  %s\n' "$p" "$state" "$n" "$d" "$r" "$f" "$slowest"
done
echo
echo "projects: ${#ALL_PROJECTS[@]}, done $pdone, failed $pfailed"
echo "units: $ttotal, done $tdone, running $trun, failed $tfail, to start $((ttotal - tdone - trun - tfail))"
du -sh "$STORE" 2>/dev/null | sed 's/^/store size: /'
