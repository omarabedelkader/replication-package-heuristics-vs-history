# Replication package: heuristics vs. history in code completion

This package reruns, from scratch, the History experiment of
[HeuristicCompletion-History](https://github.com/omarabedelkader/HeuristicCompletion-History)
(branch `better`) on its 30 Pharo projects. It produces the per-project results, the summary and
the `paper-results/` folder the paper reads.

It is built for long runs on shared clusters (Grid'5000). Every image saves a **checkpoint**
between two commits of the replay. When a job hits its walltime, you submit the job again and every
project goes on from its last checkpoint.

## What is pinned

| What | Version |
|---|---|
| Benchmark | `HeuristicCompletion-History` @ `55032e8` (branch `better`) |
| Its dependency | `HeuristicCompletion-Benchmarks` @ `5448370` (locked, instead of following `main`) |
| Pharo | Pharo 14 image and VM from `get.pharo.org/64/140+vm`, downloaded once and reused by every later job |

All of these are set in `config.sh`. `HCH_COMMIT=latest` follows the tip of `better` instead.
Every repository is cloned over HTTPS, so no SSH key is needed.

The 30 studied projects are loaded from their branches and replayed over their last 200
first-parent commits, exactly as the benchmark defines them. Running the package later
therefore replays more recent histories.

### Extra projects

To use a whole node, the package also defines 24 **extra projects**, which are not in the paper:
Soil, Molecule, Pyramid, Telescope, XMLParser, MaterialDesignLite, Cormas, MuTalk, Coypu,
PharoLanguageServer, FAST, MoTion, AIGraphAlgorithms, PetitParser2, TaskIt, CodeParadise, P3,
OpenAPI, MongoTalk, Grease, Parasol, NeoCSV, NeoJSON and ReStore (`config.sh` lists the projects
that were tried and left out, and why). They are defined in
`pharo/src/HVH-Replication/CooHistoryExperimentConfiguration.extension.st` in the same way as the
paper's projects: last 200 first-parent commits of the branch that is loaded.

Their results go to `STORE/results-extra/`, with their own summary, and `STORE/results-all/`
summarizes all 54 projects. `paper-results/` still covers only the paper's 30. `EXTRA=0` runs only
the 30 (`EXTRA=0 g5k/submit.sh`).

## Quick start on Grid'5000 (Rennes)

```bash
ssh rennes.g5k
git clone https://github.com/omarabedelkader/replication-package-heuristics-vs-history.git
cd replication-package-heuristics-vs-history
g5k/submit.sh                 # reserves tonight 19:00 -> 09:00 (14 h) on a CPU-only node
```

To continue an unfinished replication, run the same command again, for example the next day.
Nothing is ever redone:

```bash
g5k/submit.sh                         # tonight again
g5k/submit.sh "2026-11-05 19:00:00"   # a given start
NIGHTS=3 g5k/submit.sh                # tonight and the 2 following nights at once
g5k/submit.sh now                     # as soon as a node is free
bin/status.sh                         # progress of every project
```

`submit.sh` reserves **paradoxe** (Rennes, default queue): 2 × Xeon Gold 5320, 52 cores, 384 GiB,
no GPU. It is the most powerful CPU-only node of Rennes that accepts advance reservations. The
abaca queue (roazhon15: 2 × EPYC 9555, 128 cores) refuses reservations, but takes immediate jobs:
`NODES="abaca:roazhon15" g5k/submit.sh now`.

Each project uses one core: one Pharo VM. So 30 cores is all the run can use, and the per-core
speed is what matters. To use another site, set `NODES`, for example
`NODES="abaca:grdix" g5k/submit.sh` on Nancy or `NODES="default:chirop" g5k/submit.sh` on Lille.
Submit from the site whose home holds the store, because Grid'5000 homes are per site.

## How it works

```
config.sh             pins, project list, knobs
bin/prepare.sh        clone pinned sources, download Pharo, build the base image (once, cached)
bin/run.sh            start / resume every unfinished project, all in parallel, then summarize
bin/save-checkpoint.sh  called by an image after it saved itself: archives its directory
bin/status.sh         done / failed / checkpointed / to start, with the last replayed commit
bin/summarize.sh      Pharo summary + paper-results (also usable on partial results)
g5k/submit.sh         OAR reservation (19:00, 14 h, CPU-only node, fallbacks)
g5k/job.sh            the OAR job: lock, checkpoint signal, bin/run.sh
pharo/install.st      loads the benchmark (group Bench) + the additions into Pharo 14
pharo/run-project.st  one experiment
pharo/src/HVH-Replication   the additions (Tonel package)
```

- **Storage.** `STORE` (default `~/hvh-store`) is persistent: sources, base image, checkpoints,
  results and logs. `WORK` (default `/tmp/hvh-$USER`) is the node's local disk, where the images
  run. It has the same absolute path on every node, because a saved image remembers the
  absolute paths of its git clones. Each image also has its own `HOME` and `TMPDIR`, because some
  baselines write in `~/Documents` (TreeSitter clones its grammars there with the system `git`).
  The commands an image runs (`git`, `gcc`, `make`, ...) go through shims that drop the VM's
  `LD_LIBRARY_PATH`: with it, the system `git` crashes on the VM's bundled `libssh2`.
- **Checkpoints.** After each replayed commit, an image saves itself if 30 minutes have passed
  (`CHECKPOINT_MINUTES`). It then calls `save-checkpoint.sh`, which writes
  `STORE/checkpoints/<project>.tar.zst` (about 20 MB for TinyLogger, a few hundred MB for the big
  ones) while the image waits, so the archive is always consistent. OAR signals the job 30 minutes
  before the walltime, and every image then saves a checkpoint after its current commit.
- **Resuming.** The archive is extracted at the same path and the saved image is reopened. The
  replay process carries on at the next commit, with its session, history, statistics,
  benchmarks and CSV logs exactly as they were. Projects that are done are skipped. A project
  whose experiment raises an error is marked failed and not retried (`RETRY_FAILED=1` retries it).
- **Removed classes.** Checking out an older commit can remove a class that registered itself for
  image startup/shutdown (`ClapCommandLineHandler` in pharoLauncher, `GPHBridge` in
  gitProjectHealth), and saving the image then fails on it. Such handlers are set aside during the
  snapshot and put back at the same place right after. Every image, fresh or resumed, first
  reloads `HVH-Replication` from the package (`pharo/update.st`), so a checkpoint saved by an older
  version of the additions runs the current one.
- **The additions change nothing that is measured.** `HVH-Replication` only clones over HTTPS,
  closes and reopens the two CSV logs around a snapshot, and adds the checkpoint call (plus a
  progress line) at the end of `CooHistoryExperimentRunner>>replayCommits:session:benchmarks:`.

## Running elsewhere (any Linux or macOS machine)

```bash
bin/run.sh                      # all 30 projects (PARALLEL=8 bin/run.sh to limit)
bin/run.sh microdown roassal    # some of them
```

Requirements: bash, git, curl, tar, zstd (or gzip) and python3 (for `paper-results`). Ctrl-C or
a crash loses at most the last 30 minutes of each project: run `bin/run.sh` again to continue.

## Outputs

- `STORE/results/<project>/`: CSV observations (`*-callsites.csv`, `*-ranks.csv`), STON results,
  figures and LaTeX tables per project
- `STORE/results/summary.{md,csv,tex,svg,png}` (the paper's 30), plus `STORE/results-extra/` and
  `STORE/results-all/` with their own summaries
- `STORE/paper-results/`: `results-macros.tex`, `tables/*.tex`, `data/*.dat` and `summary.json`
- `STORE/logs/<project>.log`: one log per project, with every attempt appended

## Validation

TinyLogger was run twice side by side: once straight through, and once with a checkpoint every
minute, killed with `kill -9` after commit 8 and resumed from its archive. The resumed run
replayed the same 72 commits, and its `tinylogger-callsites.csv` is byte-identical to the
uninterrupted one, including every history column.

The two `ranks.csv` files differ on 580 of 49,873 rows, in every strategy (Baseline included).
These differences already appear at commit 7, which was benchmarked before the first checkpoint,
so they come from run-to-run variation in the benchmark itself, not from the checkpoints
(TinyLogger message MRR: 0.591 vs 0.594).
