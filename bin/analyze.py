#!/usr/bin/env python3
"""Analyse the raw observations written by the History experiments.

Derived from scripts/analyze_history_benchmarks.py of HeuristicCompletion-History @ 55032e8 (the
pinned benchmark), with three changes; everything else computes exactly the same numbers:
  - History after self (HistoryAfterSelf) is left out. The replication no longer runs it
    (pharo/src/HVH-Replication); the rows of results made before are ignored when the ranks are read.
  - The completion list can be cut to its first k candidates (CUTOFFS, here 5): a token ranked
    after k counts as absent. The benchmark ranks the first ten proposals of one ordered candidate
    list (`completion first: 10`), and the first five of that list are what `completion first: 5`
    answers, so these numbers need no new run.
  - Call sites in test code and in the rest of the code are analysed separately (is_test_code).

Reads, for every project folder of a results directory (see bin/merge-units.py):
  <project>-callsites.csv  one line per benchmarked call site and where its expected token can come from
  <project>-ranks.csv      one line per call site, strategy and prefix: rank in the top ten (0 = absent), time
  <project>-results.ston   project statistics

Writes to the output directory:
  summary.json             every number computed below (all call sites, ten candidates)
  summary-top5.json        the same with five candidates
  summary-test.json        the same over the call sites in test code
  summary-nontest.json     the same over the other call sites
  tables/*.tex             LaTeX tables (booktabs); mrr.tex has three variants of the same layout:
                           mrr-top5.tex (five candidates), mrr-test.tex and mrr-nontest.tex
  data/*.dat               pgfplots data files
  results-macros.tex       \\newcommand macros for the numbers quoted in the text

Only the standard library is used. The statistical unit is the call site: the reciprocal ranks of a call
site's prefixes are averaged before any paired test, since the prefixes of one call site are not independent.

With a third argument, the properties of the projects written by bin/repo-features.py, it also writes
  tables/project-features.tex      the properties of every project and the gains of History
  tables/feature-correlations.tex  Spearman's rho of every property with every gain, per set of
                                   projects (paper: exploration, extra: confirmation)
  data/features.dat, summary-properties.json, and \\resProperty... macros

Usage: analyze.py RESULTS_DIR OUTPUT_DIR [PROPERTIES_CSV]
"""

import csv
import json
import math
import os
import re
import sys
from collections import defaultdict

# Every configuration reported, in display order; STRATEGIES is narrowed to the ones present in the
# data of every project when the results are loaded. The rows of any other configuration
# (HistoryAfterSelf, in results made before it was removed) are ignored when the ranks are read.
ALL_STRATEGIES = ["Baseline", "Semantic", "History", "Dependency", "Hybrid", "HybridHD", "HybridDH"]
STRATEGIES = list(ALL_STRATEGIES)
SHORT = {"Baseline": "B", "Semantic": "S", "History": "H", "Dependency": "D", "Hybrid": "Y",
         "HybridHD": "HD", "HybridDH": "DH"}
LABEL = {"HybridHD": "Hybrid H$\\to$D", "HybridDH": "Hybrid D$\\to$H"}
KINDS = ["message", "variable"]
PREFIXES = range(2, 9)
# The benchmark ranks the first TOP proposals; CUTOFFS are the shorter lists also analysed.
TOP = 10
CUTOFFS = [5]
ALL_COMPARISONS = [("History", "Semantic"), ("Dependency", "Semantic"), ("History", "Dependency"),
                   ("Hybrid", "History"), ("Hybrid", "Dependency"),
                   ("HybridHD", "Dependency"), ("HybridHD", "Hybrid"),
                   ("HybridDH", "Dependency"), ("HybridHD", "HybridDH")]
COMPARISONS = list(ALL_COMPARISONS)
# Display names of the configurations (CooHistoryExperimentConfiguration class >> #name:), keyed by the
# result folder. A project whose folder holds no complete results (failed, timed out or stopped) is still
# listed in the per-project tables, with "--" in every cell.
DISPLAY_NAMES = {"album": "Album", "alexandrie": "Alexandrie", "bloc": "Bloc", "chanel": "Chanel",
                 "chatPharo": "ChatPharo", "dataFrame": "DataFrame", "druid": "Druid", "fame": "Fame",
                 "famix": "FAMIX", "fastJava": "FASTJava", "fastPython": "FASTPython",
                 "fastTypescript": "FASTTypescript", "gitProjectHealth": "GitProjectHealth", "glorp": "Glorp",
                 "microdown": "Microdown", "moose": "Moose", "mooseCI": "MooseCI", "mooseIDE": "MooseIDE",
                 "openPonk": "OpenPonk", "osSubprocess": "OSSubprocess", "pharoLauncher": "PharoLauncher",
                 "pillar": "Pillar", "polyMath": "PolyMath", "roassal": "Roassal", "seaside": "Seaside",
                 "teapot": "Teapot", "tinyLogger": "TinyLogger", "toplo": "Toplo", "treeSitter": "TreeSitter",
                 "voyage": "Voyage"}
GROUPS = ["history only", "structure only", "both", "neither"]
DEPTH_BINS = [(0, 0), (1, 10), (11, 50), (51, 200), (201, 1000), (1001, 10 ** 9)]

csv.field_size_limit(10 ** 8)


# ---------------------------------------------------------------- statistics

def mean(values):
    values = list(values)
    return sum(values) / len(values) if values else float("nan")


def median(values):
    values = sorted(values)
    if not values:
        return float("nan")
    middle = len(values) // 2
    return values[middle] if len(values) % 2 else (values[middle - 1] + values[middle]) / 2


def percentile(values, q):
    values = sorted(values)
    if not values:
        return float("nan")
    position = (len(values) - 1) * q
    low, high = math.floor(position), math.ceil(position)
    return values[low] + (values[high] - values[low]) * (position - low)


def ranks_with_ties(values):
    order = sorted(range(len(values)), key=lambda i: values[i])
    ranks = [0.0] * len(values)
    i = 0
    while i < len(order):
        j = i
        while j + 1 < len(order) and values[order[j + 1]] == values[order[i]]:
            j += 1
        for k in range(i, j + 1):
            ranks[order[k]] = (i + j) / 2 + 1
        i = j + 1
    return ranks


def normal_two_sided_p(z):
    return math.erfc(abs(z) / math.sqrt(2))


def wilcoxon(differences):
    """Paired Wilcoxon signed-rank test, zero differences dropped, normal approximation with tie
    correction. Answers (n, p, matched-pairs rank-biserial correlation)."""
    nonzero = [d for d in differences if d != 0]
    n = len(nonzero)
    if n == 0:
        return 0, 1.0, 0.0
    ranks = ranks_with_ties([abs(d) for d in nonzero])
    positive = sum(r for r, d in zip(ranks, nonzero) if d > 0)
    negative = sum(r for r, d in zip(ranks, nonzero) if d < 0)
    expected = n * (n + 1) / 4
    ties = defaultdict(int)
    for r in ranks:
        ties[r] += 1
    variance = n * (n + 1) * (2 * n + 1) / 24 - sum(t ** 3 - t for t in ties.values()) / 48
    z = 0.0 if variance <= 0 else (positive - expected) / math.sqrt(variance)
    return n, normal_two_sided_p(z), (positive - negative) / (positive + negative)


def holm(p_values):
    order = sorted(range(len(p_values)), key=lambda i: p_values[i])
    adjusted = [0.0] * len(p_values)
    running = 0.0
    for position, index in enumerate(order):
        running = max(running, min(1.0, (len(p_values) - position) * p_values[index]))
        adjusted[index] = running
    return adjusted


def spearman(xs, ys):
    """Spearman correlation with a t approximation of its two-sided p-value."""
    n = len(xs)
    if n < 3:
        return float("nan"), float("nan")
    rx, ry = ranks_with_ties(xs), ranks_with_ties(ys)
    mx, my = mean(rx), mean(ry)
    covariance = sum((a - mx) * (b - my) for a, b in zip(rx, ry))
    spread = math.sqrt(sum((a - mx) ** 2 for a in rx) * sum((b - my) ** 2 for b in ry))
    rho = covariance / spread if spread else float("nan")
    if math.isnan(rho) or abs(rho) >= 1:
        return rho, 0.0 if not math.isnan(rho) else float("nan")
    t = rho * math.sqrt((n - 2) / (1 - rho ** 2))
    return rho, student_t_two_sided_p(t, n - 2)


def student_t_two_sided_p(t, dof):
    # regularized incomplete beta via continued fraction (Numerical Recipes betacf)
    x = dof / (dof + t * t)
    return incomplete_beta(dof / 2, 0.5, x)


def incomplete_beta(a, b, x):
    if x <= 0:
        return 0.0
    if x >= 1:
        return 1.0
    front = math.exp(math.lgamma(a + b) - math.lgamma(a) - math.lgamma(b) + a * math.log(x) + b * math.log(1 - x))
    if x < (a + 1) / (a + b + 2):
        return front * beta_fraction(a, b, x) / a
    return 1 - front * beta_fraction(b, a, 1 - x) / b


def beta_fraction(a, b, x):
    tiny = 1e-300
    c, d = 1.0, 1 - (a + b) * x / (a + 1)
    d = 1 / (d if abs(d) > tiny else tiny)
    h = d
    for m in range(1, 300):
        m2 = 2 * m
        for numerator in (m * (b - m) * x / ((a + m2 - 1) * (a + m2)),
                          -(a + m) * (a + b + m) * x / ((a + m2) * (a + m2 + 1))):
            d = 1 + numerator * d
            d = 1 / (d if abs(d) > tiny else tiny)
            c = 1 + numerator / c
            c = c if abs(c) > tiny else tiny
            h *= d * c
        if abs(d * c - 1) < 3e-14:
            break
    return h


# ---------------------------------------------------------------- loading

def read_statistics(ston_file):
    text = open(ston_file).read()
    statistics = {key: int(value) for key, value in re.findall(r"#(\w+):(\d+)", text)}
    statistics["project"] = re.search(r"#project:'([^']*)'", text).group(1)
    return statistics


def load_project(folder):
    files = os.listdir(folder)
    callsites_file = next((f for f in files if f.endswith("-callsites.csv")), None)
    ranks_file = next((f for f in files if f.endswith("-ranks.csv")), None)
    ston_file = next((f for f in files if f.endswith("-results.ston")), None)
    if not (callsites_file and ranks_file and ston_file):
        return None
    statistics = read_statistics(os.path.join(folder, ston_file))
    callsites = {}
    with open(os.path.join(folder, callsites_file), newline="") as stream:
        for row in csv.DictReader(stream):
            callsites[(row["kind"], row["id"])] = row
    scope_of = {key: ("test" if is_test_code(row) else "nontest") for key, row in callsites.items()}
    observations = defaultdict(dict)  # (kind, id) -> {(strategy, prefix): rank}
    # (kind, strategy, scope) -> [ms]; scope None: a row whose call site is not described
    times = defaultdict(list)
    with open(os.path.join(folder, ranks_file), newline="") as stream:
        for row in csv.DictReader(stream):
            if row["strategy"] not in ALL_STRATEGIES:
                continue  # a configuration that is not reported (HistoryAfterSelf)
            key = (row["kind"], row["id"])
            observations[key][(row["strategy"], int(row["prefix"]))] = int(row["rank"])
            times[(row["kind"], row["strategy"], scope_of.get(key))].append(int(row["ms"]))
    return {"statistics": statistics, "callsites": callsites, "observations": observations, "times": times}


def times_of(project, kind, strategy, scope):
    """Completion times of one kind and strategy: every row of the project for the scope "all"
    (described call site or not, as in the pinned script), else the rows of the scope's call sites."""
    scopes = ("test", "nontest", None) if scope == "all" else (scope,)
    return [t for s in scopes for t in project["times"].get((kind, strategy, s), ())]


# A call site is in test code when its method is in a test package or in a test class. A Pharo test
# package has a name segment Tests or Test, or one that ends with Tests or starts with Test followed
# by a capital or a digit (Bloc-UnitedTests, Famix-Test1-Entities, Famix-TestGenerators), but not
# Tester (Microdown-BookTester, a tool that checks books). A test class (a TestCase) is named *Test,
# *Tests or *TestCase; checking the class finds the tests that projects such as Druid and OpenPonk
# keep in their main packages, checking the package finds the fixtures and resources of the tests.
TEST_PACKAGE_SEGMENT = re.compile(r"Tests$|^Test(?![a-z])")
TEST_CLASS = re.compile(r"(Test|Tests|TestCase)$")


def is_test_code(callsite):
    package = callsite.get("package") or ""
    class_name = callsite.get("class") or ""
    if class_name.endswith(" class"):  # a class-side method
        class_name = class_name[:-len(" class")]
    return (any(TEST_PACKAGE_SEGMENT.search(segment) for segment in package.split("-"))
            or bool(TEST_CLASS.search(class_name)))


def in_scope(callsite, scope):
    return scope == "all" or (scope == "test") == is_test_code(callsite)


def reciprocal(rank, cutoff):
    """Reciprocal rank when only the first `cutoff` candidates are shown (0 = absent)."""
    return 1.0 / rank if 0 < rank <= cutoff else 0.0


def shown(rank, cutoff):
    """The rank when only the first `cutoff` candidates are shown (0 = absent)."""
    return rank if 0 < rank <= cutoff else 0


def is_true(value):
    return value.strip().lower() == "true"


def group_of(callsite):
    in_history = is_true(callsite["in_history"])
    in_structure = is_true(callsite["in_own_package"]) or is_true(callsite["in_dependency"])
    if in_history and in_structure:
        return "both"
    if in_history:
        return "history only"
    if in_structure:
        return "structure only"
    return "neither"


def complete_callsites(project, kind, scope="all"):
    """The call sites of the scope answered by every strategy for the same prefixes (the paired population)."""
    result = []
    for (callsite_kind, identifier), ranks in project["observations"].items():
        if callsite_kind != kind or (kind, identifier) not in project["callsites"]:
            continue
        if not in_scope(project["callsites"][(kind, identifier)], scope):
            continue
        prefixes = sorted({prefix for (_, prefix) in ranks})
        if all((strategy, prefix) in ranks for strategy in STRATEGIES for prefix in prefixes):
            result.append((project["callsites"][(kind, identifier)], ranks, prefixes))
    return result


# ---------------------------------------------------------------- analysis

def callsite_rr(ranks, prefixes, strategy, cutoff):
    return mean(reciprocal(ranks[(strategy, prefix)], cutoff) for prefix in prefixes)


def analyse(projects, cutoff=TOP, scope="all"):
    """Every number of the paper over the call sites of `scope`, when the first `cutoff` candidates are shown."""
    summary = {"cutoff": cutoff, "scope": scope, "projects": {}, "pooled": {}, "correlations": {}}
    for name, project in sorted(projects.items(), key=lambda item: item[0].lower()):
        statistics = project["statistics"]
        entry = {"statistics": statistics}
        for kind in KINDS:
            population = complete_callsites(project, kind, scope)
            entry[kind] = analyse_population(population, cutoff)
            entry[kind]["latency"] = {
                strategy: {"median": median(times_of(project, kind, strategy, scope)),
                           "p95": percentile(times_of(project, kind, strategy, scope), 0.95)}
                for strategy in STRATEGIES}
        summary["projects"][name] = entry

    for kind in KINDS:
        pooled_population = []
        for project in projects.values():
            pooled_population.extend(complete_callsites(project, kind, scope))
        summary["pooled"][kind] = analyse_population(pooled_population, cutoff)
        summary["pooled"][kind]["macro"] = {
            strategy: mean(summary["projects"][name][kind]["mrr"][strategy]
                           for name in summary["projects"] if summary["projects"][name][kind]["callsites"])
            for strategy in STRATEGIES}
        summary["pooled"][kind]["projects_where_best"] = projects_where_best(summary, kind)
        summary["pooled"][kind]["latency"] = {
            strategy: {"median": median([t for p in projects.values() for t in times_of(p, kind, strategy, scope)]),
                       "p95": percentile([t for p in projects.values() for t in times_of(p, kind, strategy, scope)], 0.95)}
            for strategy in STRATEGIES}
        adjust_per_project_tests(summary, kind)
        summary["correlations"][kind] = correlations(summary, kind)
    return summary


def analyse_population(population, cutoff=TOP):
    result = {"callsites": len(population), "observations": sum(len(p) for (_, _, p) in population)}
    result["mrr"], result["hit"], result["prefix_mrr"] = {}, {}, {}
    for strategy in STRATEGIES:
        reciprocal_ranks = [reciprocal(ranks[(strategy, prefix)], cutoff) for (_, ranks, prefixes) in population for prefix in prefixes]
        all_ranks = [shown(ranks[(strategy, prefix)], cutoff) for (_, ranks, prefixes) in population for prefix in prefixes]
        result["mrr"][strategy] = mean(reciprocal_ranks)
        result["hit"][strategy] = {k: mean(1.0 if 0 < r <= k else 0.0 for r in all_ranks) for k in (1, 5, 10)}
        result["prefix_mrr"][strategy] = {
            prefix: mean(reciprocal(ranks[(strategy, prefix)], cutoff) for (_, ranks, prefixes) in population if prefix in prefixes)
            for prefix in PREFIXES}

    callsites = [c for (c, _, _) in population]
    result["hit_rates"] = {
        "in_history": mean(1.0 if is_true(c["in_history"]) else 0.0 for c in callsites),
        "in_own_package": mean(1.0 if is_true(c["in_own_package"]) else 0.0 for c in callsites),
        "in_dependency": mean(1.0 if is_true(c["in_dependency"]) else 0.0 for c in callsites),
        "in_structure": mean(1.0 if is_true(c["in_own_package"]) or is_true(c["in_dependency"]) else 0.0 for c in callsites)}

    result["groups"] = {}
    for group in GROUPS:
        members = [(c, r, p) for (c, r, p) in population if group_of(c) == group]
        result["groups"][group] = {"callsites": len(members),
                                   "mrr": {s: mean(callsite_rr(r, p, s, cutoff) for (_, r, p) in members) for s in STRATEGIES}}

    result["receivers"] = {}
    for receiver in sorted({c["receiver"] for c in callsites}):
        members = [(c, r, p) for (c, r, p) in population if c["receiver"] == receiver]
        result["receivers"][receiver] = {"callsites": len(members),
                                         "mrr": {s: mean(callsite_rr(r, p, s, cutoff) for (_, r, p) in members) for s in STRATEGIES}}

    size_column = None
    if callsites:
        size_column = "history_selectors" if callsites[0]["kind"] == "message" else "history_classes"
    result["depth"] = []
    for low, high in DEPTH_BINS:
        members = [(c, r, p) for (c, r, p) in population if low <= int(c[size_column]) <= high] if size_column else []
        result["depth"].append({"low": low, "high": high, "callsites": len(members),
                                "mrr": {s: mean(callsite_rr(r, p, s, cutoff) for (_, r, p) in members) for s in STRATEGIES}})

    result["tests"] = {}
    for first, second in COMPARISONS:
        differences = [callsite_rr(r, p, first, cutoff) - callsite_rr(r, p, second, cutoff) for (_, r, p) in population]
        n, p_value, effect = wilcoxon(differences)
        result["tests"][f"{first}-{second}"] = {
            "delta_mrr": mean(differences) if differences else float("nan"),
            "n_nonzero": n, "p": p_value, "rank_biserial": effect,
            "wins": sum(1 for d in differences if d > 0), "losses": sum(1 for d in differences if d < 0)}
    return result


def projects_where_best(summary, kind):
    counts = {strategy: 0 for strategy in STRATEGIES}
    for entry in summary["projects"].values():
        if entry[kind]["callsites"]:
            mrr = entry[kind]["mrr"]
            counts[max(STRATEGIES, key=lambda s: mrr[s])] += 1
    return counts


def adjust_per_project_tests(summary, kind):
    """Holm correction over the projects, for each comparison."""
    names = [n for n in summary["projects"] if summary["projects"][n][kind]["callsites"]]
    for comparison in (f"{a}-{b}" for a, b in COMPARISONS):
        adjusted = holm([summary["projects"][n][kind]["tests"][comparison]["p"] for n in names])
        for name, value in zip(names, adjusted):
            summary["projects"][name][kind]["tests"][comparison]["p_holm"] = value


def correlations(summary, kind):
    rows = [(n, e) for n, e in summary["projects"].items() if e[kind]["callsites"]]
    gain = [e[kind]["mrr"]["History"] - e[kind]["mrr"]["Dependency"] for _, e in rows]
    history_gain = [e[kind]["mrr"]["History"] - e[kind]["mrr"]["Semantic"] for _, e in rows]
    hit_gap = [e[kind]["hit_rates"]["in_history"] - e[kind]["hit_rates"]["in_structure"] for _, e in rows]
    hit_history = [e[kind]["hit_rates"]["in_history"] for _, e in rows]
    rework = [e["statistics"].get("historyMethods", 0) / max(1, e["statistics"].get("methods", 1)) for _, e in rows]
    result = {}
    for label, xs, ys in (("hit_gap_vs_history_minus_dependency", hit_gap, gain),
                          ("hit_history_vs_history_minus_semantic", hit_history, history_gain),
                          ("rework_vs_history_minus_dependency", rework, gain),
                          ("rework_vs_history_minus_semantic", rework, history_gain)):
        rho, p_value = spearman(xs, ys)
        result[label] = {"rho": rho, "p": p_value, "n": len(xs)}
    result["points"] = [{"project": n, "hit_gap": x, "history_minus_dependency": y, "rework": r,
                         "hit_history": h, "history_minus_semantic": g}
                        for (n, _), x, y, r, h, g in zip(rows, hit_gap, gain, rework, hit_history, history_gain)]
    return result


# ---------------------------------------------------------------- output

def fmt(value, digits=3):
    return "--" if value is None or (isinstance(value, float) and math.isnan(value)) else f"{value:.{digits}f}"


def percent(value):
    return "--" if value is None or (isinstance(value, float) and math.isnan(value)) else f"{100 * value:.1f}\\%"


def p_label(value):
    if value is None or math.isnan(value):
        return "--"
    return "$<$0.001" if value < 0.001 else f"{value:.3f}"


def latex_name(name):
    return name.replace("_", "\\_").replace("&", "\\&")


def bold_best(values):
    if all(math.isnan(v) for v in values):
        return [fmt(v) for v in values]  # no call site (a scope empty in every project)
    best = max(v for v in values if not math.isnan(v))
    return [f"\\best{{{fmt(v)}}}" if fmt(v) == fmt(best) else fmt(v) for v in values]


SEPARATOR = "!{\\color{black!40}\\vrule width 0.6pt}"  # thin gray line between column groups


def shade_header(text):
    """Gray background on the header rows of a table (between \\toprule and the first \\midrule).
    The paper defines the colors tabhead and bestbg and the macro \\best{} (bold on a shaded cell)."""
    lines, inside = [], False
    for line in text.split("\n"):
        if line.startswith("\\toprule"):
            inside = True
        elif line.startswith("\\midrule"):
            inside = False
        elif inside and line.lstrip().startswith("\\cmidrule"):
            continue  # a rule inside the header would cut the gray band
        elif inside and line.rstrip().endswith("\\\\"):
            line = "\\rowcolor{tabhead}" + line
        lines.append(line)
    return "\n".join(lines)


def write(path, text):
    if path.endswith(".tex") and os.sep + "tables" + os.sep in path:
        text = shade_header(text)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as stream:
        stream.write(text)


def project_rows(summary, kind=None):
    """(name, entry) for every project in name order; entry is None for a project without results."""
    rows = [(name, entry) for name, entry in summary["projects"].items()
            if kind is None or entry[kind]["callsites"]]
    return sorted(rows, key=lambda row: row[0].lower())


def missing_row(name, cells):
    return latex_name(name) + " & " + " & ".join(["--"] * cells) + "\\\\"


def table_subjects(summary):
    """Subject projects, laid out in two side-by-side halves to halve the height of the table."""
    header = "Project & Pkgs & Methods & Commits & Changes & Msg. & Var."
    rows = []
    for name, entry in project_rows(summary):
        if entry is None:
            rows.append(f"{latex_name(name)} & " + " & ".join(["--"] * 6))
            continue
        s = entry["statistics"]
        rows.append(f"{latex_name(name)} & {s.get('packages', 0)} & {s.get('methods', 0):,} & "
                    f"{s.get('commitsAnalyzed', 0)} & {s.get('historyMethods', 0):,} & "
                    f"{entry['message']['callsites']:,} & {entry['variable']['callsites']:,}")
    total = lambda key: sum(e["statistics"].get(key, 0) for e in summary["projects"].values())
    total_row = (f"\\multicolumn{{14}}{{c}}{{\\textbf{{Total:}} {total('packages')} packages, {total('methods'):,} methods, "
                 f"{total('commitsAnalyzed'):,} commits, {total('historyMethods'):,} changes, "
                 f"{summary['pooled']['message']['callsites']:,} message and {summary['pooled']['variable']['callsites']:,} class-name call sites}}")
    half = (len(rows) + 1) // 2
    left, right = rows[:half], rows[half:]
    blank = " & ".join([""] * 7)
    right += [blank] * (half - len(right))
    lines = ["\\begin{tabular}{lrrrrrr" + SEPARATOR + "lrrrrrr}", "\\toprule",
             f"{header} & {header}\\\\", "\\midrule"]
    lines += [f"{a} & {b}\\\\" for a, b in zip(left, right)]
    lines += ["\\bottomrule", "\\end{tabular}"]
    return "\n".join(lines) + "\n"


def table_mrr(summary, kind):
    lines = ["\\begin{tabular}{l" + "r" * len(STRATEGIES) + "}", "\\toprule",
             "Project & " + " & ".join(SHORT[s] for s in STRATEGIES) + "\\\\", "\\midrule"]
    for name, entry in project_rows(summary, kind):
        if entry is None:
            lines.append(missing_row(name, len(STRATEGIES)))
            continue
        lines.append(latex_name(name) + " & " + " & ".join(bold_best([entry[kind]["mrr"][s] for s in STRATEGIES])) + "\\\\")
    pooled = summary["pooled"][kind]
    lines += ["\\midrule",
              "Mean of projects & " + " & ".join(bold_best([pooled["macro"][s] for s in STRATEGIES])) + "\\\\",
              "All call sites & " + " & ".join(bold_best([pooled["mrr"][s] for s in STRATEGIES])) + "\\\\",
              "Best in (projects) & " + " & ".join(str(pooled["projects_where_best"][s]) for s in STRATEGIES) + "\\\\",
              "\\bottomrule", "\\end{tabular}"]
    return "\n".join(lines) + "\n"


def reference_code(strategy):
    """The code of a configuration in a table header; Semantic, the reference of the superscripts, underlined."""
    return f"\\underline{{{SHORT[strategy]}}}" if strategy == "Semantic" else SHORT[strategy]


def table_mrr_both(summary, part="main"):
    """Message and class-name MRR@10 per project, side by side. Next to every value, a small superscript
    gives its change relative to Semantic in percent, in green or red (\\dif, \\up, \\down)."""
    n = len(STRATEGIES)
    spec = "r@{}l" * n
    separator = SEPARATOR
    # multicolumn cells drop the separator of the column spec, so the last cell of the message half repeats it
    code_cells = lambda last_sep: " & ".join(
        f"\\multicolumn{{2}}{{c{separator if last_sep and k == n - 1 else ''}}}{{{reference_code(st)}}}" for k, st in enumerate(STRATEGIES))
    lines = ["\\begin{tabular}{l" + spec + separator + spec + "}", "\\toprule",
             f"& \\multicolumn{{{2 * n}}}{{c{separator}}}{{Message completion}} & \\multicolumn{{{2 * n}}}{{c}}{{Class-name completion}}\\\\",
             f"\\cmidrule(lr){{2-{2 * n + 1}}}\\cmidrule(lr){{{2 * n + 2}-{4 * n + 1}}}",
             f"{'Project' if part == 'main' else ''} & {code_cells(True)} & {code_cells(False)}\\\\", "\\midrule"]

    def diff(value, reference):
        if math.isnan(value) or math.isnan(reference):
            return ""
        percent_change = round((value - reference) / reference * 100) if reference else 0
        if percent_change > 0:
            return f"\\dif{{\\up{{+{percent_change}\\%}}}}"
        if percent_change < 0:
            return f"\\dif{{\\down{{{percent_change}\\%}}}}"
        return "\\dif{0\\%}"

    def cells(values):
        texts = bold_best(values)
        reference = values[STRATEGIES.index("Semantic")] if "Semantic" in STRATEGIES else None
        out = []
        for strategy, value, text in zip(STRATEGIES, values, texts):
            out += [text, "" if reference is None or strategy == "Semantic" else diff(value, reference)]
        return out

    def half(entry, kind):
        if entry is None or not entry[kind]["callsites"]:
            return ["--", ""] * n
        return cells([entry[kind]["mrr"][s] for s in STRATEGIES])

    m, v = summary["pooled"]["message"], summary["pooled"]["variable"]
    if part == "breakdown":
        # MRR@10 over all call sites, split by origin of the expected token and by kind of receiver
        lines.append("\\textit{By origin of the token}" + " &" * (4 * n) + "\\\\")
        for group in GROUPS:
            gm, gv = m["groups"][group], v["groups"][group]
            left = cells([gm["mrr"][s] for s in STRATEGIES]) if gm["callsites"] else ["--", ""] * n
            right = cells([gv["mrr"][s] for s in STRATEGIES]) if gv["callsites"] else ["--", ""] * n
            lines.append(f"\\quad {group} & " + " & ".join(left + right) + "\\\\")
        lines += ["\\midrule", "\\textit{By kind of receiver}" + " &" * (2 * n)
                  + f" & \\multicolumn{{{2 * n}}}{{c}}{{\\textit{{does not apply: a class name has no receiver}}}}\\\\"]
        for receiver, r in sorted(m["receivers"].items(), key=lambda item: -item[1]["callsites"]):
            lines.append(f"\\quad \\texttt{{{receiver}}} & " + " & ".join(cells([r["mrr"][s] for s in STRATEGIES]) + [""] * (2 * n)) + "\\\\")
        lines += ["\\bottomrule", "\\end{tabular}"]
        return "\n".join(lines) + "\n"
    for name, entry in project_rows(summary):
        lines.append(latex_name(name) + " & " + " & ".join(half(entry, "message") + half(entry, "variable")) + "\\\\")
    best_in = lambda pooled: [c for s in STRATEGIES for c in (str(pooled["projects_where_best"][s]), "")]
    plain = lambda values: [c for value in values for c in (value, "")]
    both = lambda get: cells([get(m, s) for s in STRATEGIES]) + cells([get(v, s) for s in STRATEGIES])
    lines += ["\\midrule",
              "Mean of projects & " + " & ".join(both(lambda p, s: p["macro"][s])) + "\\\\",
              "All call sites & " + " & ".join(both(lambda p, s: p["mrr"][s])) + "\\\\",
              "Best in (projects) & " + " & ".join(best_in(m) + best_in(v)) + "\\\\",
              "\\midrule"]
    for k in (k for k in (1, 5, 10) if k <= summary["cutoff"]):
        lines.append(f"Hit@{k} & " + " & ".join(both(lambda p, s: p["hit"][s][k])) + "\\\\")
    if summary["cutoff"] == TOP:
        # The times were measured for the first TOP candidates: they are not shown for a shorter list.
        lines += ["\\midrule"]
        for label, key, row_label in (("median", "median", "Time, median (ms)"), ("p95", "p95", "Time, 95th pct.\\ (ms)")):
            lines.append(f"{row_label} & " + " & ".join(
                plain([fmt(m["latency"][s][key], 0) for s in STRATEGIES]) + plain([fmt(v["latency"][s][key], 0) for s in STRATEGIES])) + "\\\\")
    lines += ["\\bottomrule", "\\end{tabular}"]
    return "\n".join(lines) + "\n"


def table_hits(summary):
    lines = ["\\begin{tabular}{ll" + "r" * len(STRATEGIES) + "}", "\\toprule",
             "Kind & Metric & " + " & ".join(SHORT[s] for s in STRATEGIES) + "\\\\", "\\midrule"]
    for kind in KINDS:
        pooled = summary["pooled"][kind]
        rows = [("MRR@10", [pooled["mrr"][s] for s in STRATEGIES])]
        rows += [(f"Hit@{k}", [pooled["hit"][s][k] for s in STRATEGIES]) for k in (1, 5, 10)]
        for index, (label, values) in enumerate(rows):
            first = ("\\multirow{4}{*}{" + kind.capitalize() + "}") if index == 0 else ""
            lines.append(f"{first} & {label} & " + " & ".join(bold_best(values)) + "\\\\")
        if kind != KINDS[-1]:
            lines.append("\\midrule")
    lines += ["\\bottomrule", "\\end{tabular}"]
    return "\n".join(lines) + "\n"


def table_hit_rates(summary, kind):
    lines = ["\\begin{tabular}{lrrrrr}", "\\toprule",
             "Project & In hist. & In own pkg. & In dep. & H$-$S & H$-$D\\\\", "\\midrule"]
    for name, entry in project_rows(summary, kind):
        if entry is None:
            lines.append(missing_row(name, 5))
            continue
        e = entry[kind]
        lines.append(f"{latex_name(name)} & {percent(e['hit_rates']['in_history'])} & "
                     f"{percent(e['hit_rates']['in_own_package'])} & {percent(e['hit_rates']['in_dependency'])} & "
                     f"{e['mrr']['History'] - e['mrr']['Semantic']:+.3f} & {e['mrr']['History'] - e['mrr']['Dependency']:+.3f}\\\\")
    pooled = summary["pooled"][kind]
    lines += ["\\midrule",
              f"All & {percent(pooled['hit_rates']['in_history'])} & {percent(pooled['hit_rates']['in_own_package'])} & "
              f"{percent(pooled['hit_rates']['in_dependency'])} & "
              f"{pooled['mrr']['History'] - pooled['mrr']['Semantic']:+.3f} & {pooled['mrr']['History'] - pooled['mrr']['Dependency']:+.3f}\\\\",
              "\\bottomrule", "\\end{tabular}"]
    return "\n".join(lines) + "\n"


def table_groups(summary):
    lines = ["\\begin{tabular}{llr" + "r" * len(STRATEGIES) + "}", "\\toprule",
             "Kind & Origin of the token & Sites & " + " & ".join(SHORT[s] for s in STRATEGIES) + "\\\\", "\\midrule"]
    for kind in KINDS:
        groups = summary["pooled"][kind]["groups"]
        for index, group in enumerate(GROUPS):
            g = groups[group]
            first = ("\\multirow{4}{*}{" + kind.capitalize() + "}") if index == 0 else ""
            values = bold_best([g["mrr"][s] for s in STRATEGIES]) if g["callsites"] else ["--"] * len(STRATEGIES)
            lines.append(f"{first} & {group} & {g['callsites']:,} & " + " & ".join(values) + "\\\\")
        if kind != KINDS[-1]:
            lines.append("\\midrule")
    lines += ["\\bottomrule", "\\end{tabular}"]
    return "\n".join(lines) + "\n"


def table_receivers(summary):
    receivers = summary["pooled"]["message"]["receivers"]
    lines = ["\\begin{tabular}{lr" + "r" * len(STRATEGIES) + "}", "\\toprule",
             "Receiver & Sites & " + " & ".join(SHORT[s] for s in STRATEGIES) + "\\\\", "\\midrule"]
    for receiver, r in sorted(receivers.items(), key=lambda item: -item[1]["callsites"]):
        lines.append(f"\\texttt{{{receiver}}} & {r['callsites']:,} & " + " & ".join(bold_best([r["mrr"][s] for s in STRATEGIES])) + "\\\\")
    lines += ["\\bottomrule", "\\end{tabular}"]
    return "\n".join(lines) + "\n"


def signed(text):
    """Color a signed number: \\up{} (positive) or \\down{} (negative), both defined in the paper."""
    value = float(re.sub(r"[^0-9.+-]", "", text.split("$")[0]) or 0)
    if value > 0:
        return f"\\up{{{text}}}"
    if value < 0:
        return f"\\down{{{text}}}"
    return text


def table_origin_tests(summary):
    """Per project, for message and class-name completion: where the expected token comes from,
    and the gain of History over Semantic and over Dependency."""
    group = "rrr" + SEPARATOR + "rr"
    lines = ["\\begin{tabular}{l" + group + SEPARATOR + group + "}", "\\toprule",
             "& \\multicolumn{5}{c" + SEPARATOR + "}{Message completion} & \\multicolumn{5}{c}{Class-name completion}\\\\",
             "& \\multicolumn{3}{c" + SEPARATOR + "}{Token found in} & \\multicolumn{2}{c" + SEPARATOR + "}{H minus}"
             " & \\multicolumn{3}{c" + SEPARATOR + "}{Token found in} & \\multicolumn{2}{c}{H minus}\\\\",
             "Project & history & own pkg. & dep. & S & D & history & own pkg. & dep. & S & D\\\\", "\\midrule"]

    def half(e):
        if e is None or not e["callsites"]:
            return ["--"] * 5
        rates, mrr = e["hit_rates"], e["mrr"]
        return [percent(rates["in_history"]), percent(rates["in_own_package"]), percent(rates["in_dependency"]),
                signed(f"{mrr['History'] - mrr['Semantic']:+.3f}"), signed(f"{mrr['History'] - mrr['Dependency']:+.3f}")]

    for name, entry in project_rows(summary):
        lines.append(latex_name(name) + " & " + " & ".join(half(entry["message"]) + half(entry["variable"])) + "\\\\")
    pooled = summary["pooled"]
    lines += ["\\midrule", "All & " + " & ".join(half(pooled["message"]) + half(pooled["variable"])) + "\\\\",
              "\\bottomrule", "\\end{tabular}"]
    return "\n".join(lines) + "\n"


def table_breakdown(summary):
    """MRR@10 by origin of the token (both kinds) and by kind of receiver (messages)."""
    n = len(STRATEGIES)
    lines = ["\\begin{tabular}{lr" + "r" * n + "}", "\\toprule",
             "& Sites & " + " & ".join(SHORT[s] for s in STRATEGIES) + "\\\\", "\\midrule"]
    section = lambda title: f"\\multicolumn{{{n + 2}}}{{l}}{{\\textit{{{title}}}}}\\\\"
    for kind, title in (("message", "Message, by origin of the token"), ("variable", "Class name, by origin of the token")):
        lines.append(section(title))
        for group in GROUPS:
            g = summary["pooled"][kind]["groups"][group]
            values = bold_best([g["mrr"][s] for s in STRATEGIES]) if g["callsites"] else ["--"] * n
            lines.append(f"\\quad {group} & {g['callsites']:,} & " + " & ".join(values) + "\\\\")
    lines.append(section("Message, by kind of receiver"))
    receivers = summary["pooled"]["message"]["receivers"]
    for receiver, r in sorted(receivers.items(), key=lambda item: -item[1]["callsites"]):
        lines.append(f"\\quad \\texttt{{{receiver}}} & {r['callsites']:,} & " + " & ".join(bold_best([r["mrr"][s] for s in STRATEGIES])) + "\\\\")
    lines += ["\\bottomrule", "\\end{tabular}"]
    return "\n".join(lines) + "\n"


def table_tests(summary, kind):
    shown = [("History", "Semantic"), ("Dependency", "Semantic"), ("History", "Dependency"), ("Hybrid", "Dependency")]
    lines = ["\\begin{tabular}{l" + "rr" * len(shown) + "}", "\\toprule",
             "& " + " & ".join(f"\\multicolumn{{2}}{{c}}{{{SHORT[a]} vs {SHORT[b]}}}" for a, b in shown) + "\\\\",
             " ".join(f"\\cmidrule(lr){{{2 + 2 * i}-{3 + 2 * i}}}" for i in range(len(shown))),
             "Project & " + " & ".join("$\\Delta$ & $r$" for _ in shown) + "\\\\", "\\midrule"]
    for name, entry in project_rows(summary, kind):
        if entry is None:
            lines.append(missing_row(name, 2 * len(shown)))
            continue
        cells = []
        for a, b in shown:
            t = entry[kind]["tests"][f"{a}-{b}"]
            marker = "$^{*}$" if t.get("p_holm", 1) < 0.05 else ""
            cells += [signed(f"{t['delta_mrr']:+.3f}") + marker, signed(f"{t['rank_biserial']:+.2f}")]
        lines.append(latex_name(name) + " & " + " & ".join(cells) + "\\\\")
    pooled = summary["pooled"][kind]
    cells = []
    for a, b in shown:
        t = pooled["tests"][f"{a}-{b}"]
        marker = "$^{*}$" if t["p"] < 0.05 else ""
        cells += [signed(f"{t['delta_mrr']:+.3f}") + marker, signed(f"{t['rank_biserial']:+.2f}")]
    lines += ["\\midrule", "All & " + " & ".join(cells) + "\\\\", "\\bottomrule", "\\end{tabular}"]
    return "\n".join(lines) + "\n"


def table_latency(summary):
    lines = ["\\begin{tabular}{l" + "r" * len(STRATEGIES) + "}", "\\toprule",
             "Completion time (ms) & " + " & ".join(SHORT[s] for s in STRATEGIES) + "\\\\", "\\midrule"]
    for kind in KINDS:
        latency = summary["pooled"][kind]["latency"]
        lines.append(f"{kind.capitalize()}, median & " + " & ".join(fmt(latency[s]['median'], 0) for s in STRATEGIES) + "\\\\")
        lines.append(f"{kind.capitalize()}, 95th pct. & " + " & ".join(fmt(latency[s]['p95'], 0) for s in STRATEGIES) + "\\\\")
    lines += ["\\bottomrule", "\\end{tabular}"]
    return "\n".join(lines) + "\n"


def data_prefix(summary, kind):
    lines = ["prefix " + " ".join(STRATEGIES)]
    for prefix in PREFIXES:
        lines.append(f"{prefix} " + " ".join(fmt(summary["pooled"][kind]["prefix_mrr"][s][prefix], 4) for s in STRATEGIES))
    return "\n".join(lines) + "\n"


def data_depth(summary, kind):
    lines = ["bin label sites " + " ".join(STRATEGIES) + " HminusS"]
    for index, b in enumerate(summary["pooled"][kind]["depth"]):
        if not b["callsites"]:
            continue
        label = "0" if b["high"] == 0 else (f">{b['low'] - 1}" if b["high"] >= 10 ** 9 else f"{b['low']}-{b['high']}")
        mrr = b["mrr"]
        lines.append(f"{index} {label} {b['callsites']} " + " ".join(fmt(mrr[s], 4) for s in STRATEGIES)
                     + f" {fmt(mrr['History'] - mrr['Semantic'], 4)}")
    return "\n".join(lines) + "\n"


def data_scatter(summary, kind):
    lines = ["project hitgap HminusD rework hithistory HminusS"]
    for point in summary["correlations"][kind]["points"]:
        lines.append(f"{point['project']} {point['hit_gap']:.4f} {point['history_minus_dependency']:.4f} "
                     f"{point['rework']:.4f} {point['hit_history']:.4f} {point['history_minus_semantic']:.4f}")
    return "\n".join(lines) + "\n"


def macro_name(*parts):
    words = []
    for part in parts:
        for word in re.split(r"[^A-Za-z]+", str(part)):
            if word:
                words.append(word[0].upper() + word[1:])
    return "\\res" + "".join(words)


def macros(summary):
    definitions = []
    define = lambda name, value: definitions.append(f"\\newcommand{{{name}}}{{{value}}}")
    define(macro_name("Projects"), len(summary["projects"]))
    define(macro_name("Projects selected"), len(summary["projects"]) + len(summary.get("missing", [])))
    define(macro_name("Projects missing"), len(summary.get("missing", [])))
    define(macro_name("Commits"), f"{sum(e['statistics'].get('commitsAnalyzed', 0) for e in summary['projects'].values()):,}")
    for kind in KINDS:
        pooled = summary["pooled"][kind]
        define(macro_name(kind, "Sites"), f"{pooled['callsites']:,}")
        define(macro_name(kind, "Observations"), f"{pooled['observations']:,}")
        for strategy in STRATEGIES:
            define(macro_name(kind, "MRR", strategy), fmt(pooled["mrr"][strategy]))
            define(macro_name(kind, "Macro", strategy), fmt(pooled["macro"][strategy]))
            define(macro_name(kind, "Best", strategy), pooled["projects_where_best"][strategy])
            define(macro_name(kind, "Hit one", strategy), percent(pooled["hit"][strategy][1]))
            define(macro_name(kind, "Hit ten", strategy), percent(pooled["hit"][strategy][10]))
            define(macro_name(kind, "Latency", strategy), fmt(pooled["latency"][strategy]["median"], 0))
        for rate in ("in_history", "in_own_package", "in_dependency", "in_structure"):
            define(macro_name(kind, "Rate", rate), percent(pooled["hit_rates"][rate]))
        for comparison, test in pooled["tests"].items():
            define(macro_name(kind, "Delta", comparison), f"{test['delta_mrr']:+.3f}")
            define(macro_name(kind, "Effect", comparison), f"{test['rank_biserial']:+.2f}")
            define(macro_name(kind, "P", comparison), p_label(test["p"]))
            significant = sum(1 for e in summary["projects"].values()
                              if e[kind]["callsites"] and e[kind]["tests"][comparison].get("p_holm", 1) < 0.05
                              and e[kind]["tests"][comparison]["delta_mrr"] > 0)
            define(macro_name(kind, "Significant", comparison), significant)
            a, b = comparison.split("-")
            better = sum(1 for e in summary["projects"].values() if e[kind]["callsites"] and e[kind]["mrr"][a] > e[kind]["mrr"][b])
            define(macro_name(kind, "Better", comparison), better)
        for label, value in summary["correlations"][kind].items():
            if label == "points":
                continue
            define(macro_name(kind, "Rho", label), fmt(value["rho"], 2))
            define(macro_name(kind, "Rho p", label), p_label(value["p"]))
        for group in GROUPS:
            g = pooled["groups"][group]
            define(macro_name(kind, "Group sites", group), f"{g['callsites']:,}")
            for strategy in STRATEGIES:
                define(macro_name(kind, "Group", group, strategy), fmt(g["mrr"][strategy]))
    return "\n".join(definitions) + "\n"


# ---------------------------------------------------------------- project properties (bin/repo-features.py)

# (column of the properties file, label in the correlation table, header in the project table)
PROPERTIES = [("reedit", "Re-edit rate", "Re-edit"), ("authors", "Authors", "Auth."),
              ("top_author", "Top author share", "Top"), ("pr_merges", "Pull-request merges", "PR"),
              ("age_years", "Age (years)", "Age"), ("span_days", "Replayed span (days)", "Span"),
              ("test_share", "Test code share", "Test"), ("churn", "Methods per commit", "Churn"),
              ("deps", "Dependencies", "Deps"), ("software_tool", "Software tool", "Tool")]
SHARES = {"reedit", "top_author", "pr_merges", "test_share"}
DOMAIN_CODES = {"Application software": "App", "System software": "Sys", "Web libraries and frameworks": "Web",
                "Non-web libraries and frameworks": "Lib", "Software tools": "Tool", "Documentation": "Doc"}
# the gains of History whose association with the properties is measured: (kind, other strategy)
OUTCOMES = [("message", "Semantic"), ("message", "Dependency"), ("variable", "Semantic"), ("variable", "Dependency")]
SET_LABELS = {"paper": "Exploration set", "extra": "Confirmation set"}


def load_features(path):
    """{display name: {property: float or None, "set": ..., "domain": ...}} from bin/repo-features.py."""
    features = {}
    with open(path, newline="") as stream:
        for row in csv.DictReader(stream):
            entry = {"set": row["set"], "domain": row.get("domain", ""), "project": row["project"]}
            for key, _, _ in PROPERTIES:
                entry[key] = float(row[key]) if row.get(key, "") != "" else None
            features[row["name"]] = entry
    return features


def gain(entry, kind, other):
    if "History" not in STRATEGIES or other not in STRATEGIES or not entry[kind]["callsites"]:
        return None
    return entry[kind]["mrr"]["History"] - entry[kind]["mrr"][other]


def feature_correlations(summary, features):
    """For each set of projects (paper: exploration, extra: confirmation) and each gain of History:
    Spearman's rho of every property, its p-value and its Holm-adjusted p-value over the properties."""
    result = {}
    for setname in [s for s in SET_LABELS if any(f["set"] == s and n in summary["projects"] for n, f in features.items())]:
        names = [n for n, f in features.items() if f["set"] == setname and n in summary["projects"]]
        columns = {}
        for kind, other in OUTCOMES + [("message", "in_history"), ("variable", "in_history")]:
            cells = {}
            for key, _, _ in PROPERTIES:
                pairs = []
                for n in names:
                    entry = summary["projects"][n]
                    y = (entry[kind]["hit_rates"]["in_history"] if entry[kind]["callsites"] else None) \
                        if other == "in_history" else gain(entry, kind, other)
                    if features[n][key] is not None and y is not None:
                        pairs.append((features[n][key], y))
                rho, p = spearman([a for a, _ in pairs], [b for _, b in pairs]) if pairs else (float("nan"), float("nan"))
                cells[key] = {"rho": rho, "p": p, "n": len(pairs)}
            tested = [k for k in cells if not math.isnan(cells[k]["p"])]
            for k, adjusted in zip(tested, holm([cells[k]["p"] for k in tested])):
                cells[k]["p_holm"] = adjusted
            columns[f"{kind}-{other}"] = cells
        result[setname] = {"projects": len(names), "columns": columns}
    return result


def table_project_features(summary, features):
    n = len(PROPERTIES) - 1  # the software-tool flag is shown by the domain column
    lines = ["\\begin{tabular}{ll" + "r" * n + SEPARATOR + "rrr" + SEPARATOR + "rrr}", "\\toprule",
             f"& & \\multicolumn{{{n}}}{{c{SEPARATOR}}}{{Measured from git over the replayed commits}}"
             f" & \\multicolumn{{3}}{{c{SEPARATOR}}}{{Message completion}} & \\multicolumn{{3}}{{c}}{{Class-name completion}}\\\\",
             "Project & Dom. & " + " & ".join(h for k, _, h in PROPERTIES if k != "software_tool")
             + " & In hist. & H$-$S & H$-$D & In hist. & H$-$S & H$-$D\\\\", "\\midrule"]
    for setname in SET_LABELS:
        rows = [(n, f) for n, f in sorted(features.items(), key=lambda item: item[0].lower())
                if f["set"] == setname and n in summary["projects"]]
        if not rows:
            continue
        if any(f["set"] != setname for n, f in features.items() if n in summary["projects"]):
            lines.append(f"\\multicolumn{{{n + 8}}}{{l}}{{\\textit{{{SET_LABELS[setname]}}}}}\\\\")
        for name, f in rows:
            entry = summary["projects"][name]
            cells = [DOMAIN_CODES.get(f["domain"], "--")]
            for key, _, _ in PROPERTIES:
                if key == "software_tool":
                    continue
                value = f[key]
                cells.append("--" if value is None else percent(value) if key in SHARES
                             else f"{value:.1f}" if key == "age_years" else f"{value:,.0f}")
            for kind in ("message", "variable"):
                e = entry[kind]
                cells.append(percent(e["hit_rates"]["in_history"]) if e["callsites"] else "--")
                for other in ("Semantic", "Dependency"):
                    g = gain(entry, kind, other)
                    cells.append("--" if g is None else signed(f"{g:+.3f}"))
            lines.append(latex_name(name) + " & " + " & ".join(cells) + "\\\\")
    lines += ["\\bottomrule", "\\end{tabular}"]
    return "\n".join(lines) + "\n"


def table_feature_correlations(correlations_by_set):
    sets = list(correlations_by_set)
    width = len(OUTCOMES)
    spec = "l" + (SEPARATOR.join(["r" * width] * len(sets)))
    lines = ["\\begin{tabular}{" + spec + "}", "\\toprule",
             "& " + " & ".join(f"\\multicolumn{{{width}}}{{c{SEPARATOR if k < len(sets) - 1 else ''}}}"
                              f"{{{SET_LABELS[s]} ({correlations_by_set[s]['projects']})}}" for k, s in enumerate(sets)) + "\\\\",
             "& " + " & ".join(f"\\multicolumn{{2}}{{c}}{{Message}} & \\multicolumn{{2}}{{c{SEPARATOR if k < len(sets) - 1 else ''}}}{{Class name}}"
                              for k, _ in enumerate(sets)) + "\\\\",
             "Property & " + " & ".join(" & ".join(f"H$-${SHORT[o]}" for _, o in OUTCOMES) for _ in sets) + "\\\\",
             "\\midrule"]

    def cell(c):
        if math.isnan(c["rho"]):
            return "--"
        marker = "$^{\\dagger}$" if c.get("p_holm", 1) < 0.05 else "$^{*}$" if c["p"] < 0.05 else ""
        return signed(f"{c['rho']:+.2f}") + marker

    for key, label, _ in PROPERTIES:
        row = [cell(correlations_by_set[s]["columns"][f"{kind}-{other}"][key]) for s in sets for kind, other in OUTCOMES]
        lines.append(f"{label} & " + " & ".join(row) + "\\\\")
    # (a short title: a multicolumn cell wider than its columns would widen the last column)
    lines += ["\\midrule", "\\multicolumn{" + str(1 + width * len(sets)) + "}{l}{\\textit{Against the share of"
              " tokens in the history (measured)}}\\\\"]
    for key, label, _ in PROPERTIES:
        row = []
        for s in sets:
            for kind, _ in OUTCOMES:
                row.append(cell(correlations_by_set[s]["columns"][f"{kind}-in_history"][key]))
        # one value per kind: shown under H-S, blank under H-D
        shown = [c if k % 2 == 0 else "" for k, c in enumerate(row)]
        lines.append(f"\\quad {label} & " + " & ".join(shown) + "\\\\")
    lines += ["\\bottomrule", "\\end{tabular}"]
    return "\n".join(lines) + "\n"


def data_features(summary, features):
    header = ["project", "set"] + [k for k, _, _ in PROPERTIES] + ["inhistMsg", "HminusSMsg", "HminusDMsg",
                                                                   "inhistVar", "HminusSVar", "HminusDVar"]
    lines = [" ".join(header)]
    for name, f in sorted(features.items(), key=lambda item: item[0].lower()):
        if name not in summary["projects"]:
            continue
        entry = summary["projects"][name]
        values = [f["project"], f["set"]] + ["nan" if f[k] is None else f"{f[k]:.4f}" for k, _, _ in PROPERTIES]
        for kind in ("message", "variable"):
            values.append(f"{entry[kind]['hit_rates']['in_history']:.4f}" if entry[kind]["callsites"] else "nan")
            for other in ("Semantic", "Dependency"):
                g = gain(entry, kind, other)
                values.append("nan" if g is None else f"{g:.4f}")
        lines.append(" ".join(values))
    return "\n".join(lines) + "\n"


def feature_macros(correlations_by_set):
    """\\resProperty<Set><Property><Kind><Outcome>: Spearman's rho (e.g. \\resPropertyPaperReeditMessageHS)."""
    definitions = []
    for setname, data in correlations_by_set.items():
        definitions.append(f"\\newcommand{{{macro_name('Property', setname, 'Projects')}}}{{{data['projects']}}}")
        for column, cells in data["columns"].items():
            kind, other = column.split("-")
            code = "InHistory" if other == "in_history" else "H" + SHORT[other]
            for key, value in cells.items():
                name = macro_name("Property", setname, key.replace("_", " "), kind, code)
                definitions.append(f"\\newcommand{{{name}}}{{{fmt(value['rho'], 2)}}}")
                definitions.append(f"\\newcommand{{{name + 'P'}}}{{{p_label(value['p'])}}}")
    return "\n".join(definitions) + "\n"


def variants():
    """(file suffix, macro word, cutoff, scope) of every variant of the main analysis:
    mrr-top5.tex / \\resTopFive..., mrr-test.tex / \\resTest..., mrr-nontest.tex / \\resNonTest..."""
    # macro names cannot hold digits: the cutoff is spelled out
    numbers = {1: "one", 2: "two", 3: "three", 4: "four", 5: "five", 6: "six", 7: "seven", 8: "eight", 9: "nine"}
    result = [(f"top{k}", f"Top {numbers[k]}", k, "all") for k in CUTOFFS]
    result += [("test", "Test", TOP, "test"), ("nontest", "Non test", TOP, "nontest")]
    return result


def variant_macros(variant, word, everything):
    """The main numbers of a variant, as \\res<Word><Kind>...: call sites, MRR, mean of projects, best in,
    Hit@k (k up to the cutoff), median time (all candidates only) and the paired differences.
    `everything` is the main summary (all call sites), for the share of the call sites in the scope."""
    definitions = []
    define = lambda name, value: definitions.append(f"\\newcommand{{{name}}}{{{value}}}")
    cutoff = variant["cutoff"]
    for kind in KINDS:
        pooled = variant["pooled"][kind]
        define(macro_name(word, kind, "Sites"), f"{pooled['callsites']:,}")
        define(macro_name(word, kind, "Observations"), f"{pooled['observations']:,}")
        if variant["scope"] != "all":
            total = everything["pooled"][kind]["callsites"]
            define(macro_name(word, kind, "Share"), percent(pooled["callsites"] / total if total else float("nan")))
            define(macro_name(word, kind, "Projects"),
                   sum(1 for e in variant["projects"].values() if e[kind]["callsites"]))
        for strategy in STRATEGIES:
            define(macro_name(word, kind, "MRR", strategy), fmt(pooled["mrr"][strategy]))
            define(macro_name(word, kind, "Macro", strategy), fmt(pooled["macro"][strategy]))
            define(macro_name(word, kind, "Best", strategy), pooled["projects_where_best"][strategy])
            for k, name in ((1, "one"), (5, "five"), (10, "ten")):
                if k <= cutoff:
                    define(macro_name(word, kind, "Hit", name, strategy), percent(pooled["hit"][strategy][k]))
            if cutoff == TOP:
                define(macro_name(word, kind, "Latency", strategy), fmt(pooled["latency"][strategy]["median"], 0))
        for comparison, test in pooled["tests"].items():
            define(macro_name(word, kind, "Delta", comparison), fmt(test["delta_mrr"], 3) if math.isnan(test["delta_mrr"])
                   else f"{test['delta_mrr']:+.3f}")
            define(macro_name(word, kind, "P", comparison), p_label(test["p"]))
            a, b = comparison.split("-")
            better = sum(1 for e in variant["projects"].values() if e[kind]["callsites"] and e[kind]["mrr"][a] > e[kind]["mrr"][b])
            define(macro_name(word, kind, "Better", comparison), better)
    return "\n".join(definitions) + "\n"


def main():
    if len(sys.argv) not in (3, 4):
        sys.exit(__doc__)
    results, output = sys.argv[1], sys.argv[2]
    features = load_features(sys.argv[3]) if len(sys.argv) == 4 and os.path.isfile(sys.argv[3]) else None
    projects = {}
    missing = []
    for folder in sorted(os.listdir(results)):
        path = os.path.join(results, folder)
        if os.path.isdir(path):
            project = load_project(path)
            if project:
                projects[project["statistics"]["project"]] = project
                print(f"loaded {project['statistics']['project']}: {len(project['callsites'])} call sites")
            else:
                missing.append(DISPLAY_NAMES.get(folder, folder))
                print(f"no complete results for {folder}: listed with --")
    if not projects:
        sys.exit(f"No project results found in {results}")
    present = None
    for project in projects.values():
        names = {strategy for (_, strategy, _) in project["times"]}
        present = names if present is None else present & names
    STRATEGIES[:] = [s for s in ALL_STRATEGIES if s in present]
    COMPARISONS[:] = [(a, b) for (a, b) in ALL_COMPARISONS if a in STRATEGIES and b in STRATEGIES]
    print("configurations: " + ", ".join(STRATEGIES))

    summary = analyse(projects)
    summary["missing"] = sorted(missing, key=str.lower)
    write(os.path.join(output, "summary.json"), json.dumps(summary, indent=1, default=str))
    write(os.path.join(output, "tables", "subjects.tex"), table_subjects(summary))
    write(os.path.join(output, "tables", "hits.tex"), table_hits(summary))
    write(os.path.join(output, "tables", "mrr.tex"), table_mrr_both(summary))
    write(os.path.join(output, "tables", "origin-tests.tex"), table_origin_tests(summary))
    write(os.path.join(output, "tables", "breakdown.tex"), table_mrr_both(summary, "breakdown"))
    write(os.path.join(output, "tables", "groups.tex"), table_groups(summary))
    write(os.path.join(output, "tables", "receivers.tex"), table_receivers(summary))
    write(os.path.join(output, "tables", "latency.tex"), table_latency(summary))
    for kind in KINDS:
        write(os.path.join(output, "tables", f"mrr-{kind}.tex"), table_mrr(summary, kind))
        write(os.path.join(output, "tables", f"hitrates-{kind}.tex"), table_hit_rates(summary, kind))
        write(os.path.join(output, "tables", f"tests-{kind}.tex"), table_tests(summary, kind))
        write(os.path.join(output, "data", f"prefix-{kind}.dat"), data_prefix(summary, kind))
        write(os.path.join(output, "data", f"depth-{kind}.dat"), data_depth(summary, kind))
        write(os.path.join(output, "data", f"scatter-{kind}.dat"), data_scatter(summary, kind))
    # The same table (and the main numbers, as macros) with fewer candidates, and per scope of call sites.
    definitions = macros(summary)
    for file_suffix, word, cutoff, scope in variants():
        variant = analyse(projects, cutoff=cutoff, scope=scope)
        write(os.path.join(output, f"summary-{file_suffix}.json"), json.dumps(variant, indent=1, default=str))
        write(os.path.join(output, "tables", f"mrr-{file_suffix}.tex"), table_mrr_both(variant))
        definitions += variant_macros(variant, word, summary)
        print(f"{file_suffix}: " + ", ".join(f"{kind} {variant['pooled'][kind]['callsites']} call sites, MRR@{cutoff} "
                                             + " ".join(f"{SHORT[s]}={variant['pooled'][kind]['mrr'][s]:.3f}" for s in STRATEGIES)
                                             for kind in KINDS))
    if features:
        # The properties of the projects (bin/repo-features.py) against the gains of History.
        known = [n for n in summary["projects"] if n in features]
        print(f"properties: {len(known)} of {len(summary['projects'])} projects"
              + (f" (none for {', '.join(sorted(set(summary['projects']) - set(known)))})" if len(known) < len(summary["projects"]) else ""))
        if known:
            correlations_by_set = feature_correlations(summary, features)
            write(os.path.join(output, "summary-properties.json"), json.dumps(correlations_by_set, indent=1, default=str))
            write(os.path.join(output, "tables", "project-features.tex"), table_project_features(summary, features))
            write(os.path.join(output, "tables", "feature-correlations.tex"), table_feature_correlations(correlations_by_set))
            write(os.path.join(output, "data", "features.dat"), data_features(summary, features))
            definitions += feature_macros(correlations_by_set)
            for setname, data in correlations_by_set.items():
                cells = data["columns"]["message-Semantic"]
                print(f"  {setname} ({data['projects']} projects), rho with message H-S: "
                      + "  ".join(f"{k}={cells[k]['rho']:+.2f}" for k, _, _ in PROPERTIES if not math.isnan(cells[k]["rho"])))
    write(os.path.join(output, "results-macros.tex"), definitions)

    for kind in KINDS:
        pooled = summary["pooled"][kind]
        print(f"\n{kind}: {pooled['callsites']} call sites")
        print("  MRR       " + "  ".join(f"{SHORT[s]}={pooled['mrr'][s]:.3f}" for s in STRATEGIES))
        print("  best in   " + "  ".join(f"{SHORT[s]}={pooled['projects_where_best'][s]}" for s in STRATEGIES))
        print("  hit rates " + "  ".join(f"{k}={v:.2f}" for k, v in pooled["hit_rates"].items()))
        for label, value in summary["correlations"][kind].items():
            if label != "points":
                print(f"  spearman {label}: rho={value['rho']:.2f} p={value['p']:.3f} (n={value['n']})")
    print(f"\nWritten to {output}")


if __name__ == "__main__":
    main()
