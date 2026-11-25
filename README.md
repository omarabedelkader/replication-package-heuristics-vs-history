# Replication package: heuristics vs. history in code completion

This package reruns, from scratch, the History experiment of
[HeuristicCompletion-History](https://github.com/omarabedelkader/HeuristicCompletion-History)
(branch `better`) on 29 of its 30 Pharo projects (Druid is left out: see `config.sh`). It produces the per-project results, the summary and
the `paper-results/` folder the paper reads.

It is built for long runs on shared clusters (Grid'5000):

- every project is split into **units** that run in parallel, on one or several nodes: 8 units
  per slice of the call sites, so that even the projects whose single commits take hours finish in
  one night;
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

The 29 studied projects are loaded from their branches and replayed over their last 200
first-parent commits, exactly as the benchmark defines them. Running the package later
therefore replays more recent histories.

### Extra projects

The package also defines 71 **extra projects**, which are not in the paper. The first 22:
Soil, Molecule, Pyramid, Telescope, XMLParser, MaterialDesignLite, MuTalk, Coypu,
PharoLanguageServer, FAST, MoTion, AIGraphAlgorithms, PetitParser2, TaskIt, P3, OpenAPI, MongoTalk, Grease, Parasol, NeoCSV, NeoJSON and ReStore (`config.sh` lists the projects
that were tried and left out, and why). They are defined in
`pharo/src/HVH-Replication/CooHistoryExperimentConfiguration.extension.st` in the same way as the
paper's projects: last 200 first-parent commits of the branch that is loaded.

49 more were added on 2026-11-25, to study 100 projects: Pharo projects on GitHub (Tonel or
FileTree, with a `BaselineOf`) with a commit since mid-2024, that load in Pharo 14. Candidates were
first checked with `bin/load-test.sh`, which loads each project in a fresh copy of the base image as a
run starts (`pharo/load-test.st`), without completing anything, and reports how many commits its replay
would have. Of 67 candidates, 52 loaded; the 49 with the longest replays were kept (`config.sh` gives
the reason for each one left out):

```bash
bin/load-test.sh magritte smacc     # one line per project in $STORE/load-test/results.txt
```

Their results go to `STORE/results-extra/` and `STORE/paper-results-extra/`, and
`STORE/paper-results-all/` covers all 100 projects. `paper-results/` still covers only the paper's 29. `EXTRA=0` runs only
the 29 (`EXTRA=0 g5k/submit.sh`).

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
bin/load-test.sh      can these projects be run? loads each one as a run starts, completes nothing
bin/summarize.sh      paper-results (Python analysis of the CSV observations)
bin/analyze.py        that analysis (see Analysis below)
g5k/submit.sh         OAR reservation (19:00, 14 h, CPU-only node, fallbacks)
g5k/job.sh            the OAR job: checkpoint signal, one bin/run.sh worker
pharo/install.st      loads the benchmark (group Bench) + the additions into Pharo 14
pharo/run-project.st  one experiment
pharo/src/HVH-Replication   the additions (Tonel package)
```

- **Units.** Each completion is independent of the others: a strategy answers a call site from
  the image and the history of the previous commits, and no strategy changes either. A unit
  therefore loads the project and replays every commit with the full history, exactly like a
  whole run, but completes only the call sites of its share (`HVH_SLICE`, a stable hash of the
  call site id modulo the number of units of the project), with every strategy (`PAIRED=1`, the
  default) or with one (`PAIRED=0`, `HVH_STRATEGY`). A project has `UNITS_PER_SLICE` (8) units per
  slice; `config.sh` gives 8 slices to toplo, fastPython and glorp, 4 to druid and fastTypescript,
  2 to 8 others, 1 to the rest. `UNITS_PER_SLICE` stays at 8 although 7 configurations are run
  now: the share of a unit depends on it, so a different value would give the units already done,
  claimed or checkpointed in `STORE` other call sites. `bin/merge-units.py` concatenates the units' `ranks.csv` rows (each row comes from one
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
  closes and reopens the two CSV logs around a snapshot, adds the checkpoint call (plus a
  progress line) at the end of `CooHistoryExperimentRunner>>replayCommits:session:benchmarks:`,
  and leaves out one configuration (below).
- **History after self is not run.** `HVH-Replication` overrides
  `CooHistoryExperimentRunner>>benchmarksForSession:` without it, so the images run 7
  configurations: Baseline, Semantic, History, Dependency, Hybrid, Hybrid H→D and Hybrid D→H.
  The others do not depend on it (each completes the call sites on its own). An image resumed
  from a checkpoint saved before this change goes on with the benchmarks it had built, so
  `HvhReplication class>>benches:id:`, which every completion goes through, also refuses it:
  from its next commit on, that image completes nothing with it. Rows written before stay in the
  CSV files and are ignored by the analysis.

## Running elsewhere (any Linux or macOS machine)

```bash
bin/run.sh                      # all 29 projects (PARALLEL=8 bin/run.sh to limit)
bin/run.sh microdown roassal    # some of them
```

Requirements: bash, git, curl, tar, zstd (or gzip) and python3 (for `paper-results`). Ctrl-C or
a crash loses at most the last 30 minutes of each project: run `bin/run.sh` again to continue.

## Outputs

- `STORE/results/<project>/`: the merged CSV observations (`*-callsites.csv`, `*-ranks.csv`) and
  the STON statistics of each project (`STORE/results-extra/` for the extra projects)
- `STORE/units/<unit>/`: the raw results of each unit
- `STORE/paper-results/`: `results-macros.tex`, `tables/*.tex`, `data/*.dat` and `summary*.json`
  for the paper's 29 projects; `paper-results-extra/` and `paper-results-all/` likewise
- `STORE/logs/<unit>.log`: one log per unit, with every attempt appended

## Analysis

`bin/summarize.sh` runs `bin/analyze.py`, the benchmark's own analysis
(`scripts/analyze_history_benchmarks.py` @ `55032e8`) with three changes. Every number they share is
computed in the same way: on the same data, its outputs are byte-identical to the pinned script's
once the History after self rows are removed.

- **History after self is not reported.** It is no longer run (see How it works); the rows of
  results made before are ignored when the ranks are read, and it appears in no table, plot data
  or macro.
- **Five candidates** (`tables/mrr-top5.tex`, `summary-top5.json`, `\resTopFive...` macros): the
  table of `mrr.tex` when the engine shows five candidates instead of ten. The benchmark logs the rank
  of the expected token in the first ten proposals of one ordered list (`completion first: 10`); the
  first five of that list are what `completion first: 5` answers, so a token ranked 6 to 10 counts as
  absent and no new run is needed. Hit@10 and the completion times (measured for ten candidates) are
  left out. `CUTOFFS` in `bin/analyze.py` sets the lengths analysed.
- **Test and non-test code** (`tables/mrr-test.tex`, `tables/mrr-nontest.tex`, `summary-test.json`,
  `summary-nontest.json`, `\resTest...` and `\resNonTest...` macros): the table of `mrr.tex` over the
  call sites in test code and over the others. A call site is in test code when its method is in a test
  package (a name segment `Tests` or `Test`, or ending with `Tests`, or `Test` followed by a capital or
  a digit, such as `Bloc-UnitedTests` or `Famix-Test1-Entities`, but not `Microdown-BookTester`) or in
  a class named `*Test`, `*Tests` or `*TestCase` (the tests that Druid and OpenPonk keep in their main
  packages). The two tables partition the call sites of `mrr.tex`; a project without such call sites
  has a row of dashes.

After each analysis, `bin/summarize.sh` runs `bin/implications.py` on the same folder. It only reads
the summaries above and `repo-features.csv`, and writes the two summary tables of the paper's body:
`tables/overall.tex` (every configuration over all call sites: MRR@10, MRR@5, test and non-test code,
Hit@1/10, completion time; message and class-name completion side by side) and
`tables/implications.tex` (message completion per third of the projects by the share of expected tokens
found in the history and by pace of development, and per kind of code), with their numbers as
`\imp...` and `\pop...` macros in `implications-macros.tex`. The per-project tables stay in the
paper's supplementary material.

## Project properties

To relate the results to the projects, `bin/repo-features.py` measures from git, for every project,
properties over exactly the commits it replayed, and `bin/analyze.py` (third argument, passed by
`bin/summarize.sh`) relates them to the gains of History in two tables:
`tables/project-features.tex` (the properties of every project, the share of its tokens found in the
history and the gains of History) and `tables/feature-correlations.tex` (Spearman's ρ of every
property with every gain, with Holm's correction over the properties). The paper's projects are the
exploration set and the extra projects the confirmation set: a relation found in the first is
believable when it holds in the second.

| Property | Definition (replayed commits only) | Related work |
|---|---|---|
| Re-edit rate | share of the method changes of a commit (from the second one) to a method already changed earlier in the replay | changed-entity locality (Kim et al., ICSE 2007); history-based completion (Robbes and Lanza, ASE 2008); localness (Tu et al., FSE 2014) |
| Authors, top author share | people who authored the replayed changes (merged branches included); share of the most active one | ownership (Bird et al., FSE 2011) |
| Pull-request merges | share of replayed commits that merge a branch: a whole reviewed change per replay step | perils of mining GitHub (Kalliamvakou et al., MSR 2014) |
| Age, replayed span | first commit of the repository to the last replayed one; time covered by the replay | |
| Test code share | share of the method changes in test code (the rule of the test tables) | |
| Methods per commit | median number of methods a commit changes | code churn (Nagappan and Ball, ICSE 2005) |
| Dependencies | other projects the Metacello baseline loads | |
| Software tool | application domain "software tools" of Borges et al. (ICSME 2016), classified from each README (`DOMAINS` in the script) | |

The selection of projects follows Nagappan et al. (FSE 2013, "Diversity in software engineering
research") and Baltes and Ralph (EMSE 2022, "Sampling in software engineering research").

**How the replayed commits are found.** The benchmark replays the last first-parent commits of the
version it loaded (a tag, a branch, or a commit no ref points to any more). The script finds that
version as the one whose first-parent history puts every commit of the call sites at its replay
index (for Album and PharoLauncher, the unique commit that many first-parent steps after the newest
call-site commit); a project for which no single version fits is left out.

**How the measure was checked.** Methods are compared across files and formats (a method that only
moves to another file, folder or format, as when Glorp went from FileTree to Tonel, is not a change;
a change of category or layout is, as for Pharo). For each project, `sites_confirmed` is the share of
the methods whose call sites the benchmark completed that git shows changed by the same commit. On
the run of 2026-11-02 it is at least 87% for 41 of the 51 projects (100% for TinyLogger, Seaside,
FASTJava, Fame, ...; Microdown 99.7%, 1,990 changes against the benchmark's 1,994). It is low for
XMLParser (23%), Glorp (30%), Grease (31%), Chanel (55%) and MoTion (58%): there the benchmark counted
many more changes than git (Glorp: 29,865 against 6,238) because loading a commit announced methods
that it did not change (all of Glorp when its files moved to `src/`, the same few methods at every
commit), so their history holds methods no developer changed at that time.

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

**History after self removed (2026-11-24).** TinyLogger was run in its 8 units, first with the
previous version of the package (which ran History after self): 4 units finished, 2 were killed by
`kill -9` after a checkpoint (after commits 7 and 3). The run was then finished with this version:
the 2 checkpointed units resumed with the benchmarks of the previous version and the 2 others
started fresh. The units started fresh have no History after self row; the resumed units have none
after their checkpoint commit; every call site of the merged results (1,056) has the 7
configurations at the same prefixes, and `bin/summarize.sh` reports exactly these 7.
