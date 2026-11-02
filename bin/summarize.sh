#!/usr/bin/env bash
# Aggregate the finished projects into the paper folder (Python analysis of the CSV observations):
#   $STORE/paper-results/        tables, plot data and number macros of the paper (its 30 projects)
#   $STORE/paper-results-extra/  the same for the extra projects
#   $STORE/paper-results-all/    the same for all the projects
# bin/run.sh calls it once every project is finished; it can be called by hand at any time
# for an overview of the projects finished so far.
set -euo pipefail
PKG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PKG/config.sh"
HCH="$STORE/src/HeuristicCompletion-History"

# The paper reads the Python analysis of the raw observations (CSV files) of its 30 projects:
# tables, plot data, number macros. The units of a project only hold the observations of their
# strategy, so the per-project figures of the Pharo exporters are not produced: everything comes
# from the merged CSV files.
analyze() { # results directory, output directory
  local n; n="$(ls -d "$1"/*/ 2>/dev/null | wc -l | tr -d ' ')"
  [ "$n" -gt 0 ] || return 0
  echo "==> Analysing $n project(s) of $1 into $2"
  rm -rf "$2"
  python3 "$HCH/scripts/analyze_history_benchmarks.py" "$1" "$2"
}

analyze "$STORE/results" "$STORE/paper-results"            # the paper: its 30 projects
if ls -d "$STORE/results-extra"/*/ >/dev/null 2>&1; then
  analyze "$STORE/results-extra" "$STORE/paper-results-extra"
  rm -rf "$STORE/results-all"; mkdir -p "$STORE/results-all"
  for d in "$STORE/results"/*/ "$STORE/results-extra"/*/; do ln -s "${d%/}" "$STORE/results-all/"; done
  analyze "$STORE/results-all" "$STORE/paper-results-all"   # all the projects together
fi
echo "Paper results: $STORE/paper-results"
