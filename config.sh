# Everything the replication depends on, in one place. Sourced by every script; any value can be
# overridden from the environment (e.g. `HCH_COMMIT=latest bin/run.sh`).

# The benchmark (Pharo code of the experiment), pinned to the commit of branch `better` the paper used.
HCH_REPO="${HCH_REPO:-https://github.com/omarabedelkader/HeuristicCompletion-History.git}"
HCH_BRANCH="${HCH_BRANCH:-better}"
HCH_COMMIT="${HCH_COMMIT:-55032e816639505c17d35ea1a59fc3d8bb3c52f8}"   # 'latest' = tip of HCH_BRANCH

# Its dependency (BaselineOfExtendedHeuristicCompletionBenchmarks), pinned instead of following `main`.
HCB_REPO="${HCB_REPO:-https://github.com/omarabedelkader/HeuristicCompletion-Benchmarks.git}"
HCB_COMMIT="${HCB_COMMIT:-5448370158ce0196e18cb195707136f648ad4c12}"

# Pharo 14 image + VM.
PHARO_URL="${PHARO_URL:-https://get.pharo.org/64/140+vm}"

# Where things live.
#   STORE: persistent (sources, base image, checkpoints, results). Survives between jobs.
#   WORK:  fast scratch where images run. The same absolute path on every machine, because a saved
#          image remembers the absolute paths of its git clones.
STORE="${STORE:-$HOME/hvh-store}"
WORK="${WORK:-/tmp/hvh-$(id -un)}"

# The 30 projects of the paper (selectors of CooHistoryExperimentConfiguration). The longest ones
# come first, so they start first when PARALLEL is smaller than the number of projects.
PAPER_PROJECTS=(fastPython fastTypescript toplo chatPharo glorp openPonk fastJava druid album bloc
  polyMath gitProjectHealth mooseIDE chanel famix pharoLauncher treeSitter osSubprocess microdown
  dataFrame alexandrie voyage pillar fame teapot seaside mooseCI tinyLogger roassal moose)

# 24 extra projects, defined by the package (pharo/src/HVH-Replication/
# CooHistoryExperimentConfiguration.extension.st), to fill a big node. Their results go to
# $STORE/results-extra and never into the paper results. EXTRA=0 runs the paper's 30 only.
# Tried and left out: kendrick (its baseline does not load in Pharo 14: "Conflicting repositories"),
# willow, buoy, stargate (ba-st baselines that do not load in Pharo 14), mapless (the benchmark's
# CoTypeInferencer fails on it: #lookupSelector: sent to nil).
EXTRA_PROJECTS=(soil molecule pyramid telescope xmlParser materialDesignLite cormas muTalk coypu
  pharoLanguageServer fast moTion aiGraphAlgorithms petitParser2 taskIt codeParadise p3 openAPI
  mongoTalk grease parasol neoCSV neoJSON reStore)

if [ "${EXTRA:-1}" = 1 ]; then ALL_PROJECTS=("${PAPER_PROJECTS[@]}" "${EXTRA_PROJECTS[@]}")
else ALL_PROJECTS=("${PAPER_PROJECTS[@]}"); fi

is_extra() { local e; for e in "${EXTRA_PROJECTS[@]}"; do [ "$e" = "$1" ] && return 0; done; return 1; }
results_of() { if is_extra "$1"; then echo "$STORE/results-extra/$1"; else echo "$STORE/results/$1"; fi; }

PARALLEL="${PARALLEL:-0}"                         # images at once; 0 = all projects
CHECKPOINT_MINUTES="${CHECKPOINT_MINUTES:-30}"   # minutes between two checkpoints of an image
RETRY_FAILED="${RETRY_FAILED:-0}"                # 1 = run again the projects that failed before
