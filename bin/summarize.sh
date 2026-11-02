#!/usr/bin/env bash
# Aggregate the finished projects into the summary (Pharo) and the paper folder (Python):
#   $STORE/results/summary.{svg,png,md,csv,tex}           the 30 projects of the paper
#   $STORE/results-extra/summary.*, $STORE/results-all/summary.*   the extra projects, and all
#   $STORE/paper-results/   tables, plot data and number macros of the paper
# bin/run.sh calls it once every project is finished; it can be called by hand at any time
# for an overview of the projects finished so far.
set -euo pipefail
PKG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PKG/config.sh"
HCH="$STORE/src/HeuristicCompletion-History"

summary() { # results directory: summary.{svg,png,md,csv,tex} of the projects in it
  local dir="$1" name; name="$(basename "$1")"
  echo "==> Writing the summary of $(ls -d "$dir"/*/ 2>/dev/null | wc -l | tr -d ' ') project(s) in $dir"
  (
    cd "$WORK"
    printf "(CooHistoryExperimentSummary fromDirectory: '%s') exportTo: '%s'.\nSmalltalk exitSuccess.\n" "$dir" "$dir" > "summary-$name.st"
    cp bench-base.image "summary-$name.image"; cp bench-base.changes "summary-$name.changes"
    ./pharo "summary-$name.image" st --quit "summary-$name.st" > "$STORE/logs/summary-$name.log" 2>&1 || true
    rm -f "summary-$name.image" "summary-$name.changes" "summary-$name.st"
  )
  if command -v rsvg-convert >/dev/null; then
    rsvg-convert -b white "$dir/summary.svg" -o "$dir/summary.png" || true
  elif command -v magick >/dev/null; then
    magick -background white "$dir/summary.svg" "$dir/summary.png" || true
  fi
}

# The paper: its 30 projects only.
RESULTS="$STORE/results"
summary "$RESULTS"

# The extra projects alone, and all projects together (results-all links to both).
if ls -d "$STORE/results-extra"/*/ >/dev/null 2>&1; then
  summary "$STORE/results-extra"
  rm -rf "$STORE/results-all"; mkdir -p "$STORE/results-all"
  for d in "$STORE/results"/*/ "$STORE/results-extra"/*/; do ln -s "${d%/}" "$STORE/results-all/"; done
  summary "$STORE/results-all"
fi

# make-paper-results.sh writes next to the results directory: $STORE/paper-results
"$HCH/scripts/make-paper-results.sh" "$RESULTS"
[ -f "$RESULTS/summary.md" ] && cat "$RESULTS/summary.md"
echo "Paper results: $STORE/paper-results"
