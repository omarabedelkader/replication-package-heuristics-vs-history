# Replication package: heuristics vs. history in code completion

This package reruns, from scratch, the History experiment of
[HeuristicCompletion-History](https://github.com/omarabedelkader/HeuristicCompletion-History)
(branch `better`) on its 30 Pharo projects. It produces the per-project results, the summary and
the `paper-results/` folder the paper reads.

It is built for long runs on shared clusters (Grid'5000):

- every project is split into **units** that run in parallel, on one or several nodes: one unit
  per strategy (8) and per slice of the call sites, so that even the projects whose single commits
  take hours finish in one night;
- every image saves a **checkpoint** between two commits of the replay. When a job hits its
  walltime, you submit the job again and every unit goes on from its last checkpoint.

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

To use the nodes fully, the package also defines 23 **extra projects**, which are not in the paper:
Soil, Molecule, Pyramid, Telescope, XMLParser, MaterialDesignLite, Cormas, MuTalk, Coypu,
PharoLanguageServer, FAST, MoTion, AIGraphAlgorithms, PetitParser2, TaskIt, P3, OpenAPI, MongoTalk, Grease, Parasol, NeoCSV, NeoJSON and ReStore (`config.sh` lists the projects
that were tried and left out, and why). They are defined in
`pharo/src/HVH-Replication/CooHistoryExperimentConfiguration.extension.st` in the same way as the
paper's projects: last 200 first-parent commits of the branch that is loaded.

Their results go to `STORE/results-extra/` and `STORE/paper-results-extra/`, and
`STORE/paper-results-all/` covers all 53 projects. `paper-results/` still covers only the paper's 30. `EXTRA=0` runs only
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
HOSTS=4 WALLTIME=12:00:00 g5k/submit.sh now   # 4 nodes at once: they share the units
bin/status.sh                         # progress of every project
```

`submit.sh` reserves **paradoxe** (Rennes, default queue): 2 × Xeon Gold 5320, 52 cores, 384 GiB,
no GPU. It is the most powerful CPU-only node of Rennes that accepts advance reservations. The
abaca queue (roazhon15: 2 × EPYC 9555, 128 cores) refuses reservations, but takes immediate jobs:
`NODES="abaca:roazhon15" g5k/submit.sh now`.

A Pharo VM uses one core, so `bin/run.sh` runs one image per physical core (hyperthreads are not
counted: every completion's time is measured). The 704 units use as many nodes as you give them;
4 paradoxe nodes (200 images) run the whole replication in one night. To use another site, set `NODES`, for example
`NODES="abaca:grdix" g5k/submit.sh` on Nancy or `NODES="default:chirop" g5k/submit.sh` on Lille.
Submit from the site whose home holds the store, because Grid'5000 homes are per site.

## How it works

```
config.sh             pins, project list, knobs
bin/prepare.sh        clone pinned sources, download Pharo, build the base image (once, cached)
bin/run.sh            worker: claims units, starts / resumes them in parallel, merges, summarizes
bin/merge-units.py    joins the units of a project into its results
bin/save-checkpoint.sh  called by an image after it saved itself: archives its directory
bin/status.sh         per project: units done / running / failed, least advanced running unit
bin/summarize.sh      paper-results (Python analysis of the CSV observations)
g5k/submit.sh         OAR reservation (19:00, 14 h, CPU-only node, fallbacks)
g5k/job.sh            the OAR job: checkpoint signal, one bin/run.sh worker
pharo/install.st      loads the benchmark (group Bench) + the additions into Pharo 14
pharo/run-project.st  one experiment
pharo/src/HVH-Replication   the additions (Tonel package)
```

- **Units.** Each completion is independent of the others: a strategy answers a call site from
  the image and the history of the previous commits, and no strategy changes either. A unit
  therefore loads the project and replays every commit with the full history, exactly like a
  whole run, but completes only the call sites of its strategy (`HVH_STRATEGY`) and slice
  (`HVH_SLICE`, a stable hash of the call site id modulo the number of slices; `config.sh` gives
  8 slices to toplo, fastPython and glorp, 4 to druid and fastTypescript, 2 to 8 others, 1 to the
  rest). `bin/merge-units.py` concatenates the units' `ranks.csv` rows (each row comes from one
  unit) and takes the union of their `callsites.csv` rows. The project statistics of the STON
  file are the same in every unit: they are counted before a call site is left to another unit.
  Units are claimed by creating `STORE/claims/<unit>` (atomic on NFS), so any number of workers,
  one per node, share them. Pharo's per-project figures and `summary.md` read all the
  benchmarks of one image and are not produced; the paper's numbers come from the CSV files.
- **Storage.** `STORE` (default `~/hvh-store`) is persistent: sources, base image, checkpoints,
  results and logs. `WORK` (default `/tmp/hvh-$USER`) is the node's local disk, where the images
  run. It has the same absolute path on every node, because a saved image remembers the
  absolute paths of its git clones. Each image also has its own `HOME` and `TMPDIR`, because some
  baselines write in `~/Documents` (TreeSitter clones its grammars there with the system `git`).
  The commands an image runs (`git`, `gcc`, `make`, ...) go through shims that drop the VM's
  `LD_LIBRARY_PATH`: with it, the system `git` crashes on the VM's bundled `libssh2`. Every image
  has its own copy of the VM, because TreeSitter builds its grammars into the VM's `lib/`; the
  grammars built once are kept in `STORE/base/vm-libs` and given to every VM, so TreeSitter does
  not ask the GitHub API again (60 requests an hour per address). The benchmark's line per call
  site and strategy is left out of the logs (gigabytes per project). A unit that fails before its
  first commit (a clone from GitHub failing under load) is tried again, up to 8 times.
- **Checkpoints.** After each replayed commit, an image saves itself if 30 minutes have passed
  (`CHECKPOINT_MINUTES`). It then calls `save-checkpoint.sh`, which writes
  `STORE/checkpoints/<unit>.tar.zst` (about 20 MB for TinyLogger, a few hundred MB for the big
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

- `STORE/results/<project>/`: the merged CSV observations (`*-callsites.csv`, `*-ranks.csv`) and
  the STON statistics of each project (`STORE/results-extra/` for the extra projects)
- `STORE/units/<unit>/`: the raw results of each unit
- `STORE/paper-results/`: `results-macros.tex`, `tables/*.tex`, `data/*.dat` and `summary.json`
  for the paper's 30 projects; `paper-results-extra/` and `paper-results-all/` likewise
- `STORE/logs/<unit>.log`: one log per unit, with every attempt appended

## Validation

TinyLogger was run twice side by side: once straight through, and once with a checkpoint every
minute, killed with `kill -9` after commit 8 and resumed from its archive. The resumed run
replayed the same 72 commits, and its `tinylogger-callsites.csv` is byte-identical to the
uninterrupted one, including every history column.

The two `ranks.csv` files differ on 580 of 49,873 rows, in every strategy (Baseline included).
These differences already appear at commit 7, which was benchmarked before the first checkpoint,
so they come from run-to-run variation in the benchmark itself, not from the checkpoints
(TinyLogger message MRR: 0.591 vs 0.594).

**Units.** TinyLogger was run split into its 8 units and merged, and unsplit, side by side on the
same loaded node (2026-11-02, paradoxe). Both have the same 1,055 call sites, described
identically, and the same 48,680 (strategy, call site, prefix) observations; 98.2% of the ranks
are identical and every strategy's MRR is within 0.005 of the unsplit run's. Two unsplit runs made
at different times that evening (the node half loaded, then fully loaded) agree on only 92.4% of
the ranks (message Baseline MRR 0.211 vs 0.223): the benchmark varies more with the machine's load
than with the split.
