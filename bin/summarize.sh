#!/usr/bin/env bash
# Aggregate the finished projects into the summary (Pharo) and the paper folder (Python):
#   $STORE/results/summary.{svg,png,md,csv,tex}
#   $STORE/paper-results/   tables, plot data and number macros of the paper
# bin/run.sh calls it once every project is finished; it can be called by hand at any time
# for an overview of the projects finished so far.
set -euo pipefail
PKG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PKG/config.sh"
RESULTS="$STORE/results"
HCH="$STORE/src/HeuristicCompletion-History"

echo "==> Writing the summary of $(ls -d "$RESULTS"/*/ 2>/dev/null | wc -l | tr -d ' ') project(s)"
cd "$WORK"
cat > summary.st <<EOF
(CooHistoryExperimentSummary fromDirectory: '$RESULTS') exportTo: '$RESULTS'.
Smalltalk exitSuccess.
EOF
cp bench-base.image summary.image; cp bench-base.changes summary.changes
./pharo summary.image st --quit summary.st > "$STORE/logs/summary.log" 2>&1 || true
rm -f summary.image summary.changes

if command -v rsvg-convert >/dev/null; then
  rsvg-convert -b white "$RESULTS/summary.svg" -o "$RESULTS/summary.png"
elif command -v magick >/dev/null; then
  magick -background white "$RESULTS/summary.svg" "$RESULTS/summary.png"
fi

# make-paper-results.sh writes next to the results directory: $STORE/paper-results
"$HCH/scripts/make-paper-results.sh" "$RESULTS"
[ -f "$RESULTS/summary.md" ] && cat "$RESULTS/summary.md"
echo "Paper results: $STORE/paper-results"
