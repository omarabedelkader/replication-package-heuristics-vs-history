#!/usr/bin/env python3
"""The two summary tables of the paper's body, and their numbers, from an analysis folder.

    bin/implications.py PAPER_RESULTS [REPO_FEATURES_CSV]

PAPER_RESULTS is a folder written by bin/analyze.py (summary.json, summary-top5.json,
summary-test.json, summary-nontest.json); REPO_FEATURES_CSV is $STORE/repo-features.csv
(bin/repo-features.py; default: PAPER_RESULTS/../repo-features.csv). It writes:

  tables/overall.tex        every configuration over all call sites: MRR@10, MRR@5, MRR@10 in test
                            and in non-test code, Hit@1/10 and completion time; message and
                            class-name completion side by side.
  tables/implications.tex   when does history pay off? Message completion per group of projects
                            (thirds of the share of tokens found in the history; thirds of the pace
                            of development) and per kind of code (test, non-test): mean of the
                            projects of Semantic, of History - Semantic, Dependency - Semantic and
                            Hybrid D->H - Dependency, and the number of projects where each is positive.
  tables/claims.tex         every claim of the paper on the exploration set, the
                            confirmation set and all projects.
  implications-macros.tex   \\imp... macros for the text (group bounds and values, Spearman's rho of
                            the share in the history against the gains, per set of projects).

It only reads the summaries: every number is a mean or a count over their per-project values.
"""
import csv
import json
import math
import os
import sys

S = ["Baseline", "Semantic", "History", "Dependency", "Hybrid", "HybridHD", "HybridDH"]
CODES = ["B", "S", "H", "D", "Y", "HD", "DH"]


def load(folder, name):
    path = os.path.join(folder, name + ".json")
    return json.load(open(path)) if os.path.exists(path) else None


def ranks(x):
    order = sorted(range(len(x)), key=lambda i: x[i])
    r = [0.0] * len(x)
    i = 0
    while i < len(order):
        j = i
        while j + 1 < len(order) and x[order[j + 1]] == x[order[i]]:
            j += 1
        for k in range(i, j + 1):
            r[order[k]] = (i + j) / 2 + 1
        i = j + 1
    return r


def spearman(a, b):
    """rho and its two-sided p-value (t approximation, as bin/analyze.py)."""
    n = len(a)
    if n < 3:
        return float("nan"), float("nan")
    ra, rb = ranks(a), ranks(b)
    ma, mb = sum(ra) / n, sum(rb) / n
    cov = sum((x - ma) * (y - mb) for x, y in zip(ra, rb))
    va, vb = sum((x - ma) ** 2 for x in ra), sum((y - mb) ** 2 for y in rb)
    rho = cov / math.sqrt(va * vb) if va and vb else 0.0
    if abs(rho) >= 1:
        return rho, 0.0
    t = rho * math.sqrt((n - 2) / (1 - rho * rho))
    # Student's t with n - 2 degrees of freedom, through the regularized incomplete beta function.
    df = n - 2
    x = df / (df + t * t)
    return rho, betainc(df / 2, 0.5, x)


def betainc(a, b, x):
    if x <= 0:
        return 0.0
    if x >= 1:
        return 1.0
    lbeta = math.lgamma(a + b) - math.lgamma(a) - math.lgamma(b) + a * math.log(x) + b * math.log(1 - x)
    if x < (a + 1) / (a + b + 2):
        return math.exp(lbeta) * contfrac(a, b, x) / a
    return 1 - math.exp(lbeta) * contfrac(b, a, 1 - x) / b


def contfrac(a, b, x):
    c, d = 1.0, 1 - (a + b) * x / (a + 1)
    d = 1 / (d if abs(d) > 1e-30 else 1e-30)
    h = d
    for m in range(1, 300):
        for num in (m * (b - m) * x / ((a + 2 * m - 1) * (a + 2 * m)),
                    -(a + m) * (a + b + m) * x / ((a + 2 * m) * (a + 2 * m + 1))):
            d = 1 + num * d
            d = 1 / (d if abs(d) > 1e-30 else 1e-30)
            c = 1 + num / c
            c = c if abs(c) > 1e-30 else 1e-30
            h *= d * c
        if abs(d * c - 1) < 1e-12:
            break
    return h


def mean(xs):
    xs = list(xs)
    return sum(xs) / len(xs) if xs else float("nan")


def signed(v, digits=3):
    s = f"{v:+.{digits}f}"
    return f"\\up{{{s}}}" if v > 0.0005 else f"\\down{{{s}}}" if v < -0.0005 else s


def best_row(values, fmt, higher=True):
    """values: one number per configuration; the best one is marked."""
    target = max(values) if higher else min(values)
    return [f"\\best{{{fmt(v)}}}" if v == target else fmt(v) for v in values]


def change_cell(value, reference):
    """The superscript of every table: the change of a value relative to Semantic, in percent."""
    change = round((value - reference) / reference * 100) if reference else 0
    return (f"\\dif{{\\up{{+{change}\\%}}}}" if change > 0 else
            f"\\dif{{\\down{{{change}\\%}}}}" if change < 0 else "\\dif{0\\%}")


def overall_table(sums):
    """Measures in rows; message completion, then class-name completion, side by side."""
    full, top5, test, nontest = sums["summary"], sums["summary-top5"], sums["summary-test"], sums["summary-nontest"]
    f3 = lambda v: f"{v:.3f}"
    reference = S.index("Semantic")

    def quality(values):
        """The values of one row, the best one marked, each with its change relative to Semantic (in %)."""
        cells = best_row(values, f3)
        ref = values[reference]
        for i, v in enumerate(values):
            if i != reference and ref:
                cells[i] += change_cell(v, ref)
        return cells

    blocks = {}
    for kind in ("message", "variable"):
        rows = [("MRR@10, all call sites", quality([full["pooled"][kind]["mrr"][s] for s in S]))]
        if top5:
            rows.append(("MRR@5 (five candidates)", quality([top5["pooled"][kind]["mrr"][s] for s in S])))
        if test:
            rows.append(("MRR@10, test code", quality([test["pooled"][kind]["mrr"][s] for s in S])))
        if nontest:
            rows.append(("MRR@10, non-test code", quality([nontest["pooled"][kind]["mrr"][s] for s in S])))
        rows.append(("Hit@1", quality([full["pooled"][kind]["hit"][s]["1"] for s in S])))
        rows.append(("Hit@10", quality([full["pooled"][kind]["hit"][s]["10"] for s in S])))
        lat = full["pooled"][kind]["latency"]
        rows.append(("Time, median (ms)", [f"{lat[s]['median']:.0f}" for s in S]))
        blocks[kind] = rows
    n = len(S)
    header = [f"\\underline{{{c}}}" if i == reference else c for i, c in enumerate(CODES)]  # the reference
    sep = "!{\\color{black!40}\\vrule width 0.6pt}"
    lines = ["\\begin{tabular}{l" + "r" * n + sep + "r" * n + "}", "\\toprule",
             "\\rowcolor{tabhead}& \\multicolumn{%d}{c%s}{Message completion} & \\multicolumn{%d}{c}{Class-name completion}\\\\" % (n, sep, n),
             "\\rowcolor{tabhead}Measure & " + " & ".join(header) + " & " + " & ".join(header) + "\\\\", "\\midrule"]
    for (label, message), (_, variable) in zip(blocks["message"], blocks["variable"]):
        if label.startswith("Hit@1") or label.startswith("Time, median"):
            lines.append("\\midrule")
        lines.append(f"{label} & " + " & ".join(message) + " & " + " & ".join(variable) + "\\\\")
    lines += ["\\bottomrule", "\\end{tabular}"]
    return "\n".join(lines) + "\n"


def project_rows(full, features):
    rows = []
    for name, p in full["projects"].items():
        m = p.get("message", {}).get("mrr")
        f = features.get(name)
        if not m or not f:
            continue
        try:
            span, replayed = float(f["span_days"]), float(f["replayed"])
        except (KeyError, ValueError):
            continue
        row = {"name": name, "set": f.get("set", ""),
               "inh": p["message"]["hit_rates"]["in_history"],
               "pace": span / max(replayed, 1)}  # days per replayed commit
        row.update(gains(m))
        row["best"] = max(S, key=lambda c: m.get(c, -1))
        row["v"] = gains(p.get("variable", {}).get("mrr"))
        rows.append(row)
    return rows


def gains(m):
    """Semantic and the gains of the table, from one {configuration: MRR}; None without call sites."""
    if not m:
        return None
    return {"S": m["Semantic"], "HS": m["History"] - m["Semantic"],
            "DS": m["Dependency"] - m["Semantic"], "DHD": m["HybridDH"] - m["Dependency"],
            "mrr": {c: m[c] for c in S}}


def thirds(rows, key):
    ordered = sorted(rows, key=lambda r: r[key])
    n = len(ordered)
    cut = [0, n // 3, n - n // 3, n]
    return [ordered[cut[i]:cut[i + 1]] for i in range(3)]


def kind_cells(group):
    """Mean MRR@10 of every configuration over the projects of a group, as in Table 1: every value with
    its change relative to Semantic in superscript (in percent), the best one marked."""
    if not group:
        return ["--"] * len(S)
    values = [mean(r["mrr"][c] for r in group) for c in S]
    cells = best_row(values, lambda v: f"{v:.3f}")
    reference = values[S.index("Semantic")]
    for i, c in enumerate(S):
        if c != "Semantic":
            cells[i] += change_cell(values[i], reference)
    return cells


def group_cells(group):
    """Projects, then message completion (the row itself), then class-name completion (row["v"])."""
    return [str(len(group))] + kind_cells(group) + kind_cells([r["v"] for r in group if r.get("v")])


def pct(v):
    return f"{100 * v:.0f}\\%"


def implications(sums, rows):
    macros = {}
    sep = "!{\\color{black!40}\\vrule width 0.6pt}"
    n = len(S)
    columns = " & ".join(f"\\underline{{{c}}}" if s == "Semantic" else c for s, c in zip(S, CODES))
    lines = ["\\begin{tabular}{lr" + sep + "r" * n + sep + "r" * n + "}", "\\toprule",
             f"\\rowcolor{{tabhead}}& & \\multicolumn{{{n}}}{{c{sep}}}{{Message completion}} & \\multicolumn{{{n}}}{{c}}{{Class-name completion}}\\\\",
             "\\rowcolor{tabhead}Group & Proj. & " + columns + " & " + columns + "\\\\", "\\midrule",
             "All projects & " + " & ".join(group_cells(rows)) + "\\\\", "\\midrule",
             "\\multicolumn{16}{l}{\\textit{Share of the expected message tokens found in the history}}\\\\"]
    names = ("Low", "Middle", "High")
    for label, group in zip(names, thirds(rows, "inh")):
        lo, hi = min(r["inh"] for r in group), max(r["inh"] for r in group)
        lines.append(f"\\quad {label} third ({pct(lo)}--{pct(hi)}) & " + " & ".join(group_cells(group)) + "\\\\")
        macros[f"impHist{label}Range"] = f"{pct(lo)}--{pct(hi)}"
        macros[f"impHist{label}HS"] = f"{mean(r['HS'] for r in group):+.3f}"
        macros[f"impHist{label}HSWins"] = str(sum(r["HS"] > 0 for r in group))
        macros[f"impHist{label}DHD"] = f"{mean(r['DHD'] for r in group):+.3f}"
        macros[f"impHist{label}DHDWins"] = str(sum(r["DHD"] > 0 for r in group))
        macros[f"impHist{label}N"] = str(len(group))
    lines += ["\\midrule", "\\multicolumn{16}{l}{\\textit{Pace of development (days per replayed commit)}}\\\\"]
    for label, group in zip(("Fast", "Medium", "Slow"), thirds(rows, "pace")):
        lo, hi = min(r["pace"] for r in group), max(r["pace"] for r in group)
        lines.append(f"\\quad {label} third ({lo:.1f}--{hi:.1f}) & " + " & ".join(group_cells(group)) + "\\\\")
        macros[f"impPace{label}HS"] = f"{mean(r['HS'] for r in group):+.3f}"
        macros[f"impPace{label}HSWins"] = str(sum(r["HS"] > 0 for r in group))
        macros[f"impPace{label}Range"] = f"{lo:.1f}--{hi:.1f}"
    lines += ["\\midrule", "\\multicolumn{16}{l}{\\textit{Kind of code of the call site}}\\\\"]
    for scope, label in (("summary-test", "Test code"), ("summary-nontest", "Non-test code")):
        part = sums.get(scope)
        if not part:
            continue
        sub = []
        for name, p in part["projects"].items():
            m = p.get("message", {}).get("mrr")
            if m and p["message"].get("callsites"):
                row = gains(m)
                v = p.get("variable", {})
                row["v"] = gains(v.get("mrr")) if v.get("callsites") else None
                sub.append(row)
        lines.append(f"\\quad {label} & " + " & ".join(group_cells(sub)) + "\\\\")
        key = "Test" if scope == "summary-test" else "NonTest"
        macros[f"imp{key}N"] = str(len(sub))
        macros[f"imp{key}HS"] = f"{mean(r['HS'] for r in sub):+.3f}"
        macros[f"imp{key}HSWins"] = str(sum(r["HS"] > 0 for r in sub))
        macros[f"imp{key}DHD"] = f"{mean(r['DHD'] for r in sub):+.3f}"
        macros[f"imp{key}DHDWins"] = str(sum(r["DHD"] > 0 for r in sub))
        pooled = part["pooled"]["message"]["mrr"]
        for s in ("Semantic", "History", "Dependency", "HybridDH"):
            macros[f"imp{key}MRR{s}"] = f"{pooled[s]:.3f}"
    lines += ["\\bottomrule", "\\end{tabular}"]

    macros["impProjects"] = str(len(rows))
    macros["impHistMin"] = pct(min(r["inh"] for r in rows))
    macros["impHistMax"] = pct(max(r["inh"] for r in rows))
    macros["impHSWins"] = str(sum(r["HS"] > 0 for r in rows))
    macros["impDHDWins"] = str(sum(r["DHD"] > 0 for r in rows))
    # Spearman's rho of the share in the history against the gains, per set of projects.
    for setname, label in (("", "All"), ("paper", "Paper"), ("extra", "Extra")):
        sub = [r for r in rows if not setname or r["set"] == setname]
        macros[f"impN{label}"] = str(len(sub))
        for y in ("HS", "DHD"):
            rho, p = spearman([r["inh"] for r in sub], [r[y] for r in sub])
            macros[f"impRho{y}{label}"] = f"{rho:.2f}"
            macros[f"impP{y}{label}"] = "$<$0.001" if p < 0.001 else f"{p:.3f}"
        rho, p = spearman([r["pace"] for r in sub], [r["HS"] for r in sub])
        macros[f"impRhoPaceHS{label}"] = f"{rho:.2f}"
        macros[f"impPPaceHS{label}"] = "$<$0.001" if p < 0.001 else f"{p:.3f}"
    return "\n".join(lines) + "\n", macros


def population(features, names):
    """\\pop... macros: what the studied projects are like (bin/repo-features.py, its domains)."""
    rows = [features[n] for n in names if n in features]
    macros = {"popProjects": str(len(rows))}
    if not rows:
        return macros

    def values(key):
        out = []
        for r in rows:
            try:
                out.append(float(r[key]))
            except (KeyError, ValueError):
                pass
        return sorted(out)

    def median(xs):
        n = len(xs)
        return (xs[n // 2] if n % 2 else (xs[n // 2 - 1] + xs[n // 2]) / 2) if xs else float("nan")

    for key, label, fmt in (("replayed", "Replayed", "{:.0f}"), ("authors", "Authors", "{:.0f}"),
                            ("span_days", "SpanDays", "{:,.0f}"), ("age_years", "Age", "{:.1f}"),
                            ("churn", "Churn", "{:.0f}"), ("deps", "Deps", "{:.0f}")):
        xs = values(key)
        if xs:
            macros[f"pop{label}Min"], macros[f"pop{label}Median"], macros[f"pop{label}Max"] = (
                fmt.format(xs[0]), fmt.format(median(xs)), fmt.format(xs[-1]))
    for key, label in (("test_share", "TestShare"), ("pr_merges", "PRMerges"), ("top_author", "TopAuthor")):
        xs = values(key)
        if xs:
            macros[f"pop{label}Median"] = pct(median(xs))
    macros["popSingleMaintainer"] = str(sum(float(r.get("top_author") or 0) >= 0.95 for r in rows))
    macros["popPRHeavy"] = str(sum(float(r.get("pr_merges") or 0) >= 0.75 for r in rows))
    macros["popPRLight"] = str(sum(float(r.get("pr_merges") or 0) <= 0.15 for r in rows))
    domains = {}
    for r in rows:
        domains[r.get("domain", "")] = domains.get(r.get("domain", ""), 0) + 1
    for domain, label in (("Non-web libraries and frameworks", "Lib"), ("Software tools", "Tool"),
                          ("Web libraries and frameworks", "Web"), ("Application software", "App"),
                          ("System software", "Sys"), ("Documentation", "Doc")):
        macros[f"popDomain{label}"] = str(domains.get(domain, 0))
    return macros


def prefix_macros(full):
    """\\impPrefix... macros: MRR@10 per prefix length (the data of bin/analyze.py's prefix plots)."""
    macros = {}
    words = {2: "Two", 3: "Three", 4: "Four", 5: "Five", 6: "Six", 7: "Seven", 8: "Eight"}
    for kind, k in (("message", "Message"), ("variable", "Variable")):
        prefix = full["pooled"][kind].get("prefix_mrr")
        if not prefix:
            continue
        lengths = sorted({int(n) for s in S for n in prefix.get(s, {})})
        best = [max(S, key=lambda s: prefix[s].get(str(n), -1)) for n in lengths]
        macros[f"impPrefix{k}Lengths"] = str(len(lengths))
        macros[f"impPrefix{k}BestDH"] = str(sum(b == "HybridDH" for b in best))
        gaps = {n: prefix["HybridDH"][str(n)] - prefix["Semantic"][str(n)] for n in lengths}
        widest = max(gaps, key=gaps.get)
        macros[f"impPrefix{k}WidestGapLength"] = str(widest)
        macros[f"impPrefix{k}WidestGap"] = f"{gaps[widest]:+.3f}"
        for n in lengths:
            for s in ("Semantic", "History", "Dependency", "HybridDH"):
                macros[f"impPrefix{k}{words[n]}{s}"] = f"{prefix[s][str(n)]:.3f}"
    return macros


def depth_macros(full):
    """\\impDepth... macros: gain of History over Semantic in message completion by number of
    selectors in the history snapshot (the bins of bin/analyze.py, data/depth-message.dat)."""
    macros = {}
    bins = full["pooled"]["message"].get("depth") or []
    names = ["Empty", "One", "Two", "Three", "Four", "Five", "Six", "Seven"]
    for i, b in enumerate(bins[:len(names)]):
        m = b["mrr"]
        label = names[i]
        macros[f"impDepth{label}Range"] = (f"{b['low']}" if b["high"] == b["low"] else
                                          f"more than {b['low'] - 1:,}" if b.get("high") is None or b["high"] >= 10 ** 8 else
                                          f"{b['low']:,}--{b['high']:,}")
        macros[f"impDepth{label}Gain"] = f"{m['History'] - m['Semantic']:+.3f}"
        macros[f"impDepth{label}GainDH"] = f"{m['HybridDH'] - m['Dependency']:+.3f}"
        macros[f"impDepth{label}Sites"] = f"{b['callsites']:,}"
    return macros


def claims_table(sums, rows, features):
    """Every claim of the paper, on the exploration set, the confirmation set
    and all projects. Counts are projects; rho is Spearman's over the projects of the set."""
    sets = (("paper", "Exploration"), ("extra", "Confirmation"), ("", "All"))

    def scoped(scope):
        """{set: [gains of the projects with call sites in this kind of code]}."""
        out = {key: [] for key, _ in sets}
        for name, p in (sums.get(scope) or {}).get("projects", {}).items():
            m = p.get("message", {}).get("mrr")
            if not m or not p["message"].get("callsites"):
                continue
            for key, _ in sets:
                if not key or features.get(name, {}).get("set") == key:
                    out[key].append(gains(m))
        return out

    test, nontest = scoped("summary-test"), scoped("summary-nontest")

    def count(group, test_fn):
        return f"{sum(1 for r in group if test_fn(r))}/{len(group)}"

    def rho(group, x, y):
        if len(group) < 3:
            return "--"
        r, p = spearman([g[x] for g in group], [g[y] for g in group])
        mark = "$^{\\dagger}$" if p < 0.001 else "$^{*}$" if p < 0.05 else ""
        return f"{r:+.2f}{mark}"

    claims = [
        ("C1", "History alone beats Semantic", lambda g, k: count(g, lambda r: r["HS"] > 0)),
        ("C2", "Dependency beats Semantic", lambda g, k: count(g, lambda r: r["DS"] > 0)),
        ("C3", "Hybrid D$\\to$H beats Dependency", lambda g, k: count(g, lambda r: r["DHD"] > 0)),
        ("", "\\quad and is the best configuration", lambda g, k: count(g, lambda r: r["best"] == "HybridDH")),
        ("", "\\quad and loses more than 0.005 to it", lambda g, k: count(g, lambda r: r["DHD"] < -0.005)),
        ("C4", "$\\rho$(share in history, H$-$S)", lambda g, k: rho(g, "inh", "HS")),
        ("", "$\\rho$(share in history, DH$-$D)", lambda g, k: rho(g, "inh", "DHD")),
        ("C5", "$\\rho$(pace of development, H$-$S)", lambda g, k: rho(g, "pace", "HS")),
        ("C6", "History beats Semantic in test code", lambda g, k: count(test[k], lambda r: r["HS"] > 0)),
        ("", "\\quad and outside test code", lambda g, k: count(nontest[k], lambda r: r["HS"] > 0)),
    ]
    lines = ["\\begin{tabular}{llrrr}", "\\toprule",
             "\\rowcolor{tabhead}& Claim (message completion) & " + " & ".join(
                 f"\\shortstack{{{label}\\\\({len([r for r in rows if not key or r['set'] == key])})}}" for key, label in sets) + "\\\\",
             "\\midrule"]
    macros = {}
    for i, (code, text, fn) in enumerate(claims):
        cells = []
        for key, label in sets:
            group = [r for r in rows if not key or r["set"] == key]
            cells.append(fn(group, key))
            words = ("Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine")
            macros[f"claim{words[i]}{label}"] = cells[-1].replace("$^{\\dagger}$", "").replace("$^{*}$", "")
        if code and i:
            lines.append("\\midrule")
        lines.append(f"{code} & {text} & " + " & ".join(cells) + "\\\\")
    lines += ["\\bottomrule", "\\end{tabular}"]
    return "\n".join(lines) + "\n", macros


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    folder = sys.argv[1]
    features_path = sys.argv[2] if len(sys.argv) > 2 else os.path.join(folder, "..", "repo-features.csv")
    sums = {n: load(folder, n) for n in ("summary", "summary-top5", "summary-test", "summary-nontest")}
    if not sums["summary"]:
        sys.exit(f"{folder}/summary.json is missing")
    os.makedirs(os.path.join(folder, "tables"), exist_ok=True)
    with open(os.path.join(folder, "tables", "overall.tex"), "w") as out:
        out.write(overall_table(sums))
    macros = prefix_macros(sums["summary"])
    macros.update(depth_macros(sums["summary"]))
    # MRR@10 of message completion by kind of receiver (Table 2 of the paper), for the text and Figure 3.
    for kind, receiver in (sums["summary"]["pooled"]["message"].get("receivers") or {}).items():
        for c, code in (("Semantic", "S"), ("History", "H"), ("Dependency", "D"), ("Hybrid", "Y"), ("HybridDH", "DH")):
            if c in receiver.get("mrr", {}):
                macros[f"impRecv{kind.capitalize()}{code}"] = f"{receiver['mrr'][c]:.3f}"
    if os.path.exists(features_path):
        features = {}
        for row in csv.DictReader(open(features_path, newline="")):
            features[row["name"]] = row
        rows = project_rows(sums["summary"], features)
        table, more = implications(sums, rows)
        macros.update(more)
        macros.update(population(features, list(sums["summary"]["projects"])))
        with open(os.path.join(folder, "tables", "implications.tex"), "w") as out:
            out.write(table)
        claims, more = claims_table(sums, rows, features)
        macros.update(more)
        with open(os.path.join(folder, "tables", "claims.tex"), "w") as out:
            out.write(claims)
    else:
        print(f"  {features_path} is missing: no implications and claims tables", file=sys.stderr)
    properties = load(folder, "summary-properties")
    if properties:
        # bin/analyze.py: Spearman's rho of each property against the share of the expected tokens
        # found in the history, per set of projects (paper: exploration, extra: confirmation).
        for setname, label in (("paper", "Paper"), ("extra", "Extra")):
            columns = properties.get(setname, {}).get("columns", {})
            for kind, k in (("message", "Message"), ("variable", "Variable")):
                cell = columns.get(f"{kind}-in_history", {}).get("churn")
                if cell:
                    macros[f"impChurnInHist{k}{label}"] = f"{cell['rho']:+.2f}"
                    macros[f"impChurnInHist{k}{label}P"] = "$<$0.001" if cell["p"] < 0.001 else f"{cell['p']:.3f}"
                    macros[f"impChurnInHist{k}{label}PHolm"] = "$<$0.001" if cell.get("p_holm", 1) < 0.001 else f"{cell.get('p_holm', 1):.3f}"
    with open(os.path.join(folder, "implications-macros.tex"), "w") as out:
        out.write("% Written by bin/implications.py from the summaries of this folder.\n")
        for k, v in sorted(macros.items()):
            out.write(f"\\newcommand{{\\{k}}}{{{v}}}\n")
    print(f"Written to {folder}: tables/overall.tex, implications.tex, claims.tex, implications-macros.tex "
          f"({len(macros)} macros)")


if __name__ == "__main__":
    main()
