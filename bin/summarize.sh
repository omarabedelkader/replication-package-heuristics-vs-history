#!/usr/bin/env bash
# Aggregate the finished projects into the paper folder (Python analysis of the CSV observations):
#   $STORE/paper-results/        tables, plot data and number macros of the exploration set (29 projects)
#   $STORE/paper-results-extra/  the same for the confirmation set (71 projects)
#   $STORE/paper-results-all/    the same for all 100 projects: the paper-results/ folder of the paper
# bin/run.sh calls it once every project is finished; it can be called by hand at any time
# for an overview of the projects finished so far.
set -euo pipefail
PKG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PKG/config.sh"

# The paper reads the Python analysis of the raw observations (CSV files) of its projects:
# tables, plot data, number macros. The units of a project only hold the observations of their
# strategy, so the per-project figures of the Pharo exporters are not produced: everything comes
# from the merged CSV files. The analysis is bin/analyze.py: the benchmark's own script
# (scripts/analyze_history_benchmarks.py @ HCH_COMMIT) without History after self, plus the same
# MRR table with five candidates and for the call sites in test code and in the rest of the code.
# The properties of the projects, measured from git over the commits each one replayed
# (bin/repo-features.py: it clones every repository once into $STORE/repo-clones). Computed once;
# delete $STORE/repo-features.csv to compute them again. Without them (no network, for example),
# only the two tables of the properties are missing.
FEATURES="$STORE/repo-features.csv"
if [ ! -f "$FEATURES" ]; then
  echo "==> Measuring the properties of the projects into $FEATURES"
  python3 "$PKG/bin/repo-features.py" "$STORE" "$FEATURES" || { echo "    (failed: no property tables)"; rm -f "$FEATURES"; }
fi

analyze() { # results directory, output directory
  local n; n="$(ls -d "$1"/*/ 2>/dev/null | wc -l | tr -d ' ')"
  [ "$n" -gt 0 ] || return 0
  echo "==> Analysing $n project(s) of $1 into $2"
  rm -rf "$2"
  python3 "$PKG/bin/analyze.py" "$1" "$2" "$FEATURES"
  python3 "$PKG/bin/implications.py" "$2" "$FEATURES"   # the two summary tables of the paper's body
}

analyze "$STORE/results" "$STORE/paper-results"            # the exploration set
if ls -d "$STORE/results-extra"/*/ >/dev/null 2>&1; then
  analyze "$STORE/results-extra" "$STORE/paper-results-extra"   # the confirmation set
  rm -rf "$STORE/results-all"; mkdir -p "$STORE/results-all"
  for d in "$STORE/results"/*/ "$STORE/results-extra"/*/; do ln -s "${d%/}" "$STORE/results-all/"; done
  analyze "$STORE/results-all" "$STORE/paper-results-all"   # all the projects together
fi
echo "Paper results: $STORE/paper-results"
