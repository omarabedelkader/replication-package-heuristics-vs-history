#!/usr/bin/env python3
r"""Group the projects by how they were developed during the replay, and give Table 1 of the paper
(every configuration over all call sites) for every group of projects and every kind of commit.

    clusters.py STORE COMMIT_KINDS_CSV OUTPUT_FOLDER

COMMIT_KINDS_CSV is written by bin/commit-kinds.py: one row per replayed commit, labelled from git
alone as development (adds at least as many methods as it modifies), bug fix (modifies more than it
adds, and its message names a fix), other edit (modifies more than it adds, no fix named) or no code.

Profile of a project: the shares of development, bug-fix and other-edit commits among its replayed
commits that change code. The projects are clustered on these three shares, standardized (z-scores),
by k-means (k = 3, k-means++ seeded, the best of RESTARTS runs), and every cluster is named after the
kind of commit that is most over-represented in its centre: Development, Bug fixing, Maintenance
(other edits: refactoring, tuning). Nothing in the profile comes from the completion results.

It writes into OUTPUT_FOLDER:

  clusters.csv                       the profile and the cluster of every project
  clusters.json                      the summaries of every group (bin/analyze.py's summary format)
  tables/cluster-profiles.tex        the clusters: projects per set, commits, mean profile, tokens in history
  tables/cluster-members.tex         the projects of every cluster
  tables/clusters.tex                per cluster: call sites and message and class-name MRR@10 of every
                                     configuration, with the projects where History beats Semantic and
                                     Hybrid D->H beats Dependency
  clusters-macros.tex                \clu... macros for the text (sizes, profiles, MRR, wins, the
                                     Mann-Whitney test of the per-project gain of History between the
                                     Development and Bug-fixing clusters, per set of projects)
  tables/overall-cluster-<c>.tex     Table 1 (bin/implications.py overall_table) for each cluster
  tables/commit-kinds.tex            the same summary per kind of commit (call sites pooled over projects)
  tables/overall-commit-<k>.tex      Table 1 for the call sites of each kind of commit
  tables/implications-profiles.tex   Table 3 of the paper (bin/implications.py, from $STORE/paper-results-all
                                     and $STORE/repo-features.csv) with two more groups of rows: the
                                     clusters, and the kinds of commit that introduced the call sites
                                     (mean of the projects, as the other rows)
"""
import csv, json, math, os, random, sys
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import analyze as an  # noqa: E402
import implications as im  # noqa: E402

KINDS = ["development", "bug fix", "other edit"]          # commits that change code
CLUSTER_NAMES = {"development": "Development", "bug fix": "Bug fixing", "other edit": "Maintenance"}
SLUG = {"development": "development", "bug fix": "bugfix", "other edit": "maintenance"}
K, RESTARTS, SEED = 3, 200, 2027


# ---------------------------------------------------------------- profiles and k-means

def profiles(commit_rows):
    by_project = defaultdict(list)
    for row in commit_rows:
        by_project[row["project"]].append(row)
    result = {}
    for project, rows in by_project.items():
        code = [r for r in rows if r["kind"] in KINDS]
        if not code:
            continue
        result[project] = {"set": rows[0]["set"], "commits": len(rows), "code_commits": len(code),
                           **{k: sum(r["kind"] == k for r in code) / len(code) for k in KINDS}}
    return result


def distance(a, b):
    return sum((x - y) ** 2 for x, y in zip(a, b))


def kmeans(points, k, rng):
    centres = [rng.choice(points)]
    while len(centres) < k:  # k-means++
        weights = [min(distance(p, c) for c in centres) for p in points]
        centres.append(rng.choices(points, weights=weights)[0] if sum(weights) else rng.choice(points))
    assignment = None
    for _ in range(100):
        new = [min(range(k), key=lambda j: distance(p, centres[j])) for p in points]
        if new == assignment:
            break
        assignment = new
        for j in range(k):
            members = [p for p, a in zip(points, assignment) if a == j]
            if members:
                centres[j] = [sum(c) / len(members) for c in zip(*members)]
    inertia = sum(distance(p, centres[a]) for p, a in zip(points, assignment))
    return assignment, centres, inertia


def silhouette(points, assignment):
    values = []
    for i, p in enumerate(points):
        own = [math.sqrt(distance(p, q)) for j, q in enumerate(points) if assignment[j] == assignment[i] and j != i]
        if not own:
            values.append(0.0)
            continue
        a = sum(own) / len(own)
        b = min(sum(math.sqrt(distance(p, q)) for j, q in enumerate(points) if assignment[j] == c)
                / sum(1 for j in range(len(points)) if assignment[j] == c)
                for c in set(assignment) if c != assignment[i])
        values.append((b - a) / max(a, b) if max(a, b) else 0.0)
    return sum(values) / len(values)


def cluster(profile):
    """k-means on the standardized shares (z-scores: the share of bug-fix commits varies less than the
    others and would otherwise hardly count). Each cluster is named after the kind of commit whose
    z-score is highest in its centre, every kind naming one cluster. Returns the labels, the mean
    silhouette (in z-space) and the mean raw shares of every cluster."""
    names = sorted(profile)
    raw = [[profile[n][k] for k in KINDS] for n in names]
    means = [sum(p[i] for p in raw) / len(raw) for i in range(len(KINDS))]
    sds = [math.sqrt(sum((p[i] - means[i]) ** 2 for p in raw) / len(raw)) or 1.0 for i in range(len(KINDS))]
    points = [[(p[i] - means[i]) / sds[i] for i in range(len(KINDS))] for p in raw]
    rng = random.Random(SEED)
    assignment, centres, _ = min((kmeans(points, K, rng) for _ in range(RESTARTS)), key=lambda r: r[2])
    order, used = {}, set()
    for _, j, i in sorted(((centres[j][i], j, i) for j in range(K) for i in range(len(KINDS))), reverse=True):
        if j not in order and i not in used:
            order[j] = KINDS[i]
            used.add(i)
    labels = {n: order[a] for n, a in zip(names, assignment)}
    shares = {order[j]: [sum(p[i] for p, a in zip(raw, assignment) if a == j) / assignment.count(j)
                         for i in range(len(KINDS))] for j in range(K)}
    return labels, silhouette(points, assignment), shares


# ---------------------------------------------------------------- analysis of a group

def summaries(projects):
    """The four summaries overall_table reads, for a dict of loaded projects."""
    sums = {"summary": an.analyse(projects)}
    for suffix, _, cutoff, scope in an.variants():
        sums[f"summary-{suffix}"] = an.analyse(projects, cutoff=cutoff, scope=scope)
    # as bin/implications.py reads them: through the JSON files bin/analyze.py writes (string keys)
    return json.loads(json.dumps(sums, default=str))


def load(folder, keep=None):
    """bin/analyze.py's load_project, with only the call sites for which keep(row) holds (all of them
    when keep is None, and then exactly load_project). The completion times are those of the rows of
    the kept call sites; without keep, also those of the rows whose call site is not described."""
    if keep is None:
        return an.load_project(folder)
    files = os.listdir(folder)
    names = [next((f for f in files if f.endswith(suffix)), None) for suffix in ("-callsites.csv", "-ranks.csv", "-results.ston")]
    if not all(names):
        return None
    callsites_file, ranks_file, ston_file = names
    callsites = {}
    with open(os.path.join(folder, callsites_file), newline="") as stream:
        for row in csv.DictReader(stream):
            if keep(row):
                callsites[(row["kind"], row["id"])] = row
    scope_of = {key: ("test" if an.is_test_code(row) else "nontest") for key, row in callsites.items()}
    observations, times = defaultdict(dict), defaultdict(list)
    with open(os.path.join(folder, ranks_file), newline="") as stream:
        for row in csv.DictReader(stream):
            key = (row["kind"], row["id"])
            if row["strategy"] not in an.ALL_STRATEGIES or key not in callsites:
                continue
            observations[key][(row["strategy"], int(row["prefix"]))] = int(row["rank"])
            times[(row["kind"], row["strategy"], scope_of[key])].append(int(row["ms"]))
    return {"statistics": an.read_statistics(os.path.join(folder, ston_file)), "callsites": callsites,
            "observations": observations, "times": times}


def folders(store):
    """{project: results folder} of every project of the run."""
    return {name: os.path.join(store, sub, name) for sub in ("results", "results-extra")
            for name in sorted(os.listdir(os.path.join(store, sub))) if os.path.isdir(os.path.join(store, sub, name))}


def wins(summary, kind, a, b):
    entries = [e for e in summary["projects"].values() if e[kind]["callsites"]]
    return sum(e[kind]["mrr"][a] > e[kind]["mrr"][b] for e in entries), len(entries)


def summary_table(groups, first_label):
    """One row per group: projects, call sites, MRR@10 of every configuration (message | class name),
    and the projects where H > S and DH > D."""
    S, codes = im.S, im.CODES
    sep = an.SEPARATOR
    n = len(S)
    lines = ["\\begin{tabular}{lrr" + "r" * n + "rr" + sep + "r" + "r" * n + "rr}", "\\toprule",
             f"\\rowcolor{{tabhead}}& & & \\multicolumn{{{n + 2}}}{{c{sep}}}{{Message completion (MRR@10)}} "
             f"& & \\multicolumn{{{n + 2}}}{{c}}{{Class-name completion (MRR@10)}}\\\\",
             f"\\rowcolor{{tabhead}}{first_label} & Proj. & Sites & " + " & ".join(
                 f"\\underline{{{c}}}" if s == "Semantic" else c for s, c in zip(S, codes))
             + " & H$>$S & DH$>$D & Sites & " + " & ".join(
                 f"\\underline{{{c}}}" if s == "Semantic" else c for s, c in zip(S, codes))
             + " & H$>$S & DH$>$D\\\\", "\\midrule"]
    for label, summary in groups:
        cells = [label, str(len(summary["projects"]))]
        for kind in an.KINDS:
            pooled = summary["pooled"][kind]
            values = [pooled["mrr"][s] for s in S]
            ref = values[S.index("Semantic")]
            texts = im.best_row(values, lambda v: f"{v:.3f}")
            for i, s in enumerate(S):
                if s != "Semantic" and ref:
                    change = round((values[i] - ref) / ref * 100)
                    texts[i] += (f"\\dif{{\\up{{+{change}\\%}}}}" if change > 0 else
                                 f"\\dif{{\\down{{{change}\\%}}}}" if change < 0 else "\\dif{0\\%}")
            hs, total = wins(summary, kind, "History", "Semantic")
            dhd, _ = wins(summary, kind, "HybridDH", "Dependency")
            cells += [f"{pooled['callsites']:,}".replace(",", "\\,")] + texts + [f"{hs}/{total}", f"{dhd}/{total}"]
        lines.append(" & ".join(cells) + "\\\\")
    lines += ["\\bottomrule", "\\end{tabular}"]
    return "\n".join(lines) + "\n"


def profile_table(labels, profile, groups, silhouette_value):
    lines = ["\\begin{tabular}{lrrrrrrr}", "\\toprule",
             "\\rowcolor{tabhead}Cluster & Projects & \\shortstack{Exploration/\\\\confirmation} & Commits"
             " & Development & Bug fix & Other edit & \\shortstack{Tokens in\\\\history}\\\\", "\\midrule"]
    for kind in KINDS:
        members = [p for p, l in labels.items() if l == kind]
        summary = groups[kind]
        mean = lambda key: sum(profile[p][key] for p in members) / len(members)
        lines.append(f"{CLUSTER_NAMES[kind]} & {len(members)} & "
                     f"{sum(profile[p]['set'] == 'paper' for p in members)}/{sum(profile[p]['set'] == 'extra' for p in members)} & "
                     f"{sum(profile[p]['code_commits'] for p in members)} & "
                     + " & ".join(f"{100 * mean(k):.0f}\\%" for k in KINDS)
                     + f" & {100 * summary['pooled']['message']['hit_rates']['in_history']:.0f}\\%\\\\")
    lines += ["\\midrule", f"\\multicolumn{{8}}{{l}}{{\\textit{{k-means on the three standardized shares, k = {K}; "
                           f"mean silhouette {silhouette_value:.2f}}}}}\\\\", "\\bottomrule", "\\end{tabular}"]
    return "\n".join(lines) + "\n"


def mann_whitney(xs, ys):
    """Two-sided Mann-Whitney U test, normal approximation with tie correction: (U of xs, p)."""
    n1, n2 = len(xs), len(ys)
    if not n1 or not n2:
        return float("nan"), float("nan")
    ranks = an.ranks_with_ties(list(xs) + list(ys))
    u = sum(ranks[:n1]) - n1 * (n1 + 1) / 2
    n = n1 + n2
    ties = defaultdict(int)
    for v in list(xs) + list(ys):
        ties[v] += 1
    variance = n1 * n2 / 12 * ((n + 1) - sum(t ** 3 - t for t in ties.values()) / (n * (n - 1)))
    if variance <= 0:
        return u, 1.0
    return u, an.normal_two_sided_p((u - n1 * n2 / 2) / math.sqrt(variance))


def site_rows(summary):
    """The rows bin/implications.py averages (one per project: S and the gains, message completion, and
    class-name completion in row["v"]), from the per-project entries of a summary."""
    rows = []
    for entry in summary["projects"].values():
        if entry["message"]["callsites"]:
            row = im.gains(entry["message"]["mrr"])
            row["v"] = im.gains(entry["variable"]["mrr"]) if entry["variable"]["callsites"] else None
            rows.append(row)
    return rows


def implications_with_profiles(store, cluster_groups, commit_groups):
    """Table 3 of the paper, as bin/implications.py writes it for all the projects, followed by the
    clusters and the kinds of commit; None when the summaries of all the projects are missing."""
    folder = os.path.join(store, "paper-results-all")
    features_path = os.path.join(store, "repo-features.csv")
    sums = {n: im.load(folder, n) for n in ("summary", "summary-top5", "summary-test", "summary-nontest")}
    if not sums["summary"] or not os.path.exists(features_path):
        return None
    features = {row["name"]: row for row in csv.DictReader(open(features_path, newline=""))}
    table, _ = im.implications(sums, im.project_rows(sums["summary"], features))
    rows = ["\\midrule", "\\multicolumn{14}{l}{\\textit{Development profile of the project (cluster)}}\\\\"]
    rows += [f"\\quad {CLUSTER_NAMES[k]} & " + " & ".join(im.group_cells(site_rows(cluster_groups[k]))) + "\\\\"
             for k in KINDS]
    rows += ["\\midrule", "\\multicolumn{14}{l}{\\textit{Kind of commit that introduced the call site}}\\\\"]
    rows += [f"\\quad {k.capitalize()} & " + " & ".join(im.group_cells(site_rows(commit_groups[k]))) + "\\\\"
             for k in KINDS]
    return table.replace("\\bottomrule", "\n".join(rows) + "\n\\bottomrule")


def members_table(labels, display):
    lines = ["\\begin{tabular}{lrp{0.8\\textwidth}}", "\\toprule",
             "\\rowcolor{tabhead}Cluster & Projects & Members (exploration projects in italics)\\\\", "\\midrule"]
    for kind in KINDS:
        names = sorted((display[n] for n, l in labels.items() if l == kind), key=str.lower)
        paper = {display[n] for n, l in labels.items() if l == kind and n in PAPER}
        lines.append(f"{CLUSTER_NAMES[kind]} & {len(names)} & "
                     + ", ".join(f"\\textit{{{an.latex_name(x)}}}" if x in paper else an.latex_name(x) for x in names) + "\\\\")
    lines += ["\\bottomrule", "\\end{tabular}"]
    return "\n".join(lines) + "\n"


PAPER = set()  # the projects of the exploration set (filled by main)
WORD = {"development": "Dev", "bug fix": "Fix", "other edit": "Maint"}


def cluster_macros(labels, profile, display, silhouette_value, cluster_groups, commit_groups):
    """\\clu... macros for the text: cluster sizes and profiles, pooled MRR@10 of message and class-name
    completion, projects where H > S and DH > D, mean per-project gains per set, and the Mann-Whitney
    test of the per-project gain of History between the Development and Bug-fixing clusters."""
    m = {"cluSilhouette": f"{silhouette_value:.2f}"}
    pct = lambda v: f"{100 * v:.0f}\\%"
    minus = lambda text: "$-$" + text[1:] if text.startswith("-") else text  # a typographic minus sign
    change = lambda a, b: minus(f"{round((a - b) / b * 100):+d}\\%" if round((a - b) / b * 100) else "0\\%")
    codes = {"Semantic": "S", "History": "H", "Dependency": "D", "HybridDH": "DH"}
    gains = {}  # kind of cluster -> set -> [per-project H-S of message completion]
    for kind in KINDS:
        w = WORD[kind]
        members = [n for n, l in labels.items() if l == kind]
        m[f"clu{w}N"] = len(members)
        m[f"clu{w}NPaper"] = sum(profile[n]["set"] == "paper" for n in members)
        m[f"clu{w}NExtra"] = sum(profile[n]["set"] == "extra" for n in members)
        for k in KINDS:
            m[f"clu{w}Share{WORD[k]}"] = pct(sum(profile[n][k] for n in members) / len(members))
        for groups, prefix in ((cluster_groups, "clu"), (commit_groups, "cluCommit")):
            summary = groups[kind]
            for kind_of_site, kw in (("message", ""), ("variable", "Class")):
                pooled = summary["pooled"][kind_of_site]
                for s, c in codes.items():
                    m[f"{prefix}{w}{kw}{c}"] = f"{pooled['mrr'][s]:.3f}"
                m[f"{prefix}{w}{kw}HSChange"] = change(pooled["mrr"]["History"], pooled["mrr"]["Semantic"])
                m[f"{prefix}{w}{kw}DHDDelta"] = minus(f"{pooled['mrr']['HybridDH'] - pooled['mrr']['Dependency']:+.3f}")
                hs, total = wins(summary, kind_of_site, "History", "Semantic")
                dhd, _ = wins(summary, kind_of_site, "HybridDH", "Dependency")
                m[f"{prefix}{w}{kw}HSWins"], m[f"{prefix}{w}{kw}DHDWins"], m[f"{prefix}{w}{kw}Projects"] = hs, dhd, total
            m[f"{prefix}{w}Sites"] = f"{summary['pooled']['message']['callsites']:,}"
            rows = site_rows(summary)  # mean of the projects, as in Table 3
            m[f"{prefix}{w}MeanS"] = f"{im.mean(r['S'] for r in rows):.3f}"
            m[f"{prefix}{w}MeanHS"] = minus(f"{im.mean(r['HS'] for r in rows):+.3f}")
            m[f"{prefix}{w}MeanDHD"] = minus(f"{im.mean(r['DHD'] for r in rows):+.3f}")
            m[f"{prefix}{w}ClassMeanHS"] = minus(f"{im.mean(r['v']['HS'] for r in rows if r['v']):+.3f}")
        projects = cluster_groups[kind]["projects"]
        gains[kind] = {s: [e["message"]["mrr"]["History"] - e["message"]["mrr"]["Semantic"]
                           for name, e in projects.items() if e["message"]["callsites"]
                           and (s == "all" or profile[display_inverse(display, name)]["set"] == s)]
                       for s in ("all", "paper", "extra")}
        for s, label in (("all", "All"), ("paper", "Paper"), ("extra", "Extra")):
            values = gains[kind][s]
            m[f"clu{w}MeanHS{label}"] = minus(f"{sum(values) / len(values):+.3f}") if values else "--"
    for s, label in (("all", "All"), ("paper", "Paper"), ("extra", "Extra")):
        _, p = mann_whitney(gains["development"][s], gains["bug fix"][s])
        m[f"cluDevFixP{label}"] = "$<$0.001" if p < 0.001 else f"{p:.2f}"
    # the call sites of commits that change no method of the replayed packages (no commit kind)
    total = sum(cluster_groups[k]["pooled"]["message"]["callsites"] for k in KINDS)
    labelled = sum(commit_groups[k]["pooled"]["message"]["callsites"] for k in KINDS)
    m["cluNoCodeSites"] = pct((total - labelled) / total) if total else "--"
    for k in KINDS:  # test code of the commits of each kind (summary-test)
        test = commit_groups[k].get("test")
        if test:
            m[f"cluCommit{WORD[k]}TestHSChange"] = change(test["message"]["mrr"]["History"], test["message"]["mrr"]["Semantic"])
    return m


def display_inverse(display, name):
    return next(folder for folder, shown in display.items() if shown == name)


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    store, kinds_csv, output = sys.argv[1:]
    commit_rows = list(csv.DictReader(open(kinds_csv, newline="")))
    profile = profiles(commit_rows)
    labels, silhouette_value, centres = cluster(profile)
    kind_of = {(r["project"], int(r["index"])): r["kind"] for r in commit_rows}
    where = {name: path for name, path in folders(store).items() if name in profile}
    missing = sorted(set(folders(store)) - set(profile))
    if missing:
        print("no commit kinds (left out): " + ", ".join(missing))
    # The seven configurations are in every project's results (bin/analyze.py checks it on the full run).
    an.STRATEGIES[:] = list(an.ALL_STRATEGIES)
    an.COMPARISONS[:] = list(an.ALL_COMPARISONS)

    def group(keep_project, keep_site=None):
        """The projects of a group, keyed by display name as analyse() expects, loaded one at a time."""
        result = {}
        for name, path in where.items():
            if keep_project(name):
                project = load(path, None if keep_site is None else (lambda row, name=name: keep_site(name, row)))
                if project and project["callsites"]:
                    result[project["statistics"]["project"]] = project
        return result

    display = {}
    for name, path in where.items():
        ston = next(f for f in os.listdir(path) if f.endswith("-results.ston"))
        display[name] = an.read_statistics(os.path.join(path, ston))["project"]
    PAPER.update(n for n in profile if profile[n]["set"] == "paper")

    os.makedirs(os.path.join(output, "tables"), exist_ok=True)
    with open(os.path.join(output, "tables", "cluster-members.tex"), "w") as out:
        out.write(members_table(labels, display))
    with open(os.path.join(output, "clusters.csv"), "w", newline="") as stream:
        writer = csv.writer(stream, lineterminator="\n")
        writer.writerow(["project", "set", "cluster", "code_commits"] + [k.replace(" ", "_") for k in KINDS])
        for name in sorted(profile):
            writer.writerow([name, profile[name]["set"], CLUSTER_NAMES[labels[name]], profile[name]["code_commits"]]
                            + [f"{profile[name][k]:.4f}" for k in KINDS])

    everything = {"clusters": {}, "commit_kinds": {}, "silhouette": silhouette_value,
                  "centres": {CLUSTER_NAMES[k]: dict(zip(KINDS, c)) for k, c in centres.items()}}
    cluster_groups, commit_groups = {}, {}
    for kind in KINDS:
        subset = group(lambda name: labels[name] == kind)
        sums = summaries(subset)
        del subset
        cluster_groups[kind] = sums["summary"]
        everything["clusters"][CLUSTER_NAMES[kind]] = {"projects": sorted(sums["summary"]["projects"]),
                                                       "pooled": sums["summary"]["pooled"]}
        with open(os.path.join(output, "tables", f"overall-cluster-{SLUG[kind]}.tex"), "w") as out:
            out.write(im.overall_table(sums))
        print(f"cluster {CLUSTER_NAMES[kind]}: {len(sums['summary']['projects'])} projects")

    for kind in KINDS:
        # the call sites introduced by the commits of this kind, in every project
        subset = group(lambda name: True, lambda name, row: kind_of.get((name, int(row["commit_index"]))) == kind)
        sums = summaries(subset)
        del subset
        commit_groups[kind] = dict(sums["summary"], test=sums["summary-test"]["pooled"])
        everything["commit_kinds"][kind] = sums["summary"]["pooled"]
        with open(os.path.join(output, "tables", f"overall-commit-{SLUG[kind]}.tex"), "w") as out:
            out.write(im.overall_table(sums))
        print(f"commits {kind}: {sums['summary']['pooled']['message']['callsites']} message call sites")

    with open(os.path.join(output, "tables", "clusters.tex"), "w") as out:
        out.write(summary_table([(CLUSTER_NAMES[k], cluster_groups[k]) for k in KINDS], "Cluster"))
    with open(os.path.join(output, "tables", "cluster-profiles.tex"), "w") as out:
        out.write(profile_table(labels, profile, cluster_groups, silhouette_value))
    with open(os.path.join(output, "tables", "commit-kinds.tex"), "w") as out:
        out.write(summary_table([(k.capitalize() + " commits", commit_groups[k]) for k in KINDS], "Commits"))
    table = implications_with_profiles(store, cluster_groups, commit_groups)
    if table:
        with open(os.path.join(output, "tables", "implications-profiles.tex"), "w") as out:
            out.write(table)
    else:
        print("no summaries in $STORE/paper-results-all or no repo-features.csv: no implications-profiles.tex")
    everything["rows"] = {"clusters": {CLUSTER_NAMES[k]: site_rows(cluster_groups[k]) for k in KINDS},
                          "commit_kinds": {k: site_rows(commit_groups[k]) for k in KINDS}}
    with open(os.path.join(output, "clusters-macros.tex"), "w") as out:
        out.write("% Written by bin/clusters.py: development profiles of the projects (clusters) and kinds of commits.\n")
        for key, value in sorted(cluster_macros(labels, profile, display, silhouette_value, cluster_groups, commit_groups).items()):
            out.write(f"\\newcommand{{\\{key}}}{{{value}}}\n")
    with open(os.path.join(output, "clusters.json"), "w") as out:
        json.dump(everything, out, indent=1, default=str)
    print(f"silhouette {silhouette_value:.2f}; written to {output}")


if __name__ == "__main__":
    main()
