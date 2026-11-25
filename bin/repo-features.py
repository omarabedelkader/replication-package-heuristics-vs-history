#!/usr/bin/env python3
"""Measure, from git alone, the properties of every studied project over the commits it replayed.

    repo-features.py STORE OUTPUT_CSV [--clones DIR] [PROJECT ...]

The properties are those that the related work ties to how much recent changes, and so the history
of the IDE, can tell about the next change (see README, "Project properties"):

  reedit       changed-entity locality (Kim et al., ICSE 2007; Robbes and Lanza, ASE 2008): the share
               of the method changes of a replayed commit (from the second one) that change a method
               already changed earlier in the replay. The history of the benchmark starts empty at the
               first replayed commit and keeps every later change, so "earlier" means since then.
  authors      people who authored the replayed changes (merged branches included), identities merged
               by name or e-mail; top_author: the share of these commits by the most active one
               (ownership, Bird et al., FSE 2011).
  pr_merges    the share of replayed commits that merge a branch (a pull request): one replay step is
               then a whole reviewed change (Kalliamvakou et al., MSR 2014).
  age_years    from the first commit of the repository to the last replayed one; span_days: the time
               the replayed commits cover.
  test_share   the share of the method changes that are in test code (the rule of bin/analyze.py).
  churn        the median number of methods a replayed commit changes (Nagappan and Ball, ICSE 2005).
  deps         the other projects its Metacello baseline loads (baseline:/project: declarations),
               which the Dependency configuration can draw on.
  domain       the application domain of Borges, Hora and Valente (ICSME 2016), classified from the
               project's README (DOMAINS below); software_tool = 1 for the "software tools".

The replayed commits are those of the run in STORE: the window is rebuilt from the first-parent
history of the version the benchmark loaded, which is found among the tags and branches of the
repository (and the branches as they were when the run started) as the one that puts every commit
of the call sites at its replay index. A project whose window cannot be rebuilt exactly is left out.
Every repository is cloned (bare) in --clones (default STORE/repo-clones) and fetched again later.
"""
import csv, datetime, glob, json, os, re, statistics, subprocess, sys
from collections import Counter, defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from analyze import is_test_code  # noqa: E402  the same test rule as the tables

csv.field_size_limit(10 ** 9)

# Application domains of Borges, Hora and Valente (ICSME 2016), from each project's README.
APP, SYS, WEB, LIB, TOOL, DOC = ("Application software", "System software", "Web libraries and frameworks",
                                 "Non-web libraries and frameworks", "Software tools", "Documentation")
DOMAINS = {
    "album": LIB, "alexandrie": LIB, "bloc": LIB, "chanel": TOOL, "chatPharo": TOOL, "dataFrame": LIB,
    "druid": SYS, "fame": LIB, "famix": LIB, "fastJava": LIB, "fastPython": LIB, "fastTypescript": LIB,
    "gitProjectHealth": TOOL, "glorp": LIB, "microdown": LIB, "moose": TOOL, "mooseCI": TOOL,
    "mooseIDE": TOOL, "openPonk": APP, "osSubprocess": LIB, "pharoLauncher": TOOL, "pillar": TOOL,
    "polyMath": LIB, "roassal": LIB, "seaside": WEB, "teapot": WEB, "tinyLogger": LIB, "toplo": LIB,
    "treeSitter": LIB, "voyage": LIB,
    "aiGraphAlgorithms": LIB, "coypu": APP, "fast": LIB, "grease": LIB, "materialDesignLite": WEB,
    "moTion": LIB, "molecule": LIB, "mongoTalk": LIB, "muTalk": TOOL, "neoCSV": LIB, "neoJSON": LIB,
    "openAPI": WEB, "p3": LIB, "parasol": WEB, "petitParser2": LIB, "pharoLanguageServer": TOOL,
    "pyramid": TOOL, "reStore": LIB, "soil": SYS, "taskIt": LIB, "telescope": LIB, "xmlParser": LIB,
    "cormas": APP, "kendrick": APP,
    "artefact": LIB, "ffiCallLogger": TOOL, "packageFormulas": TOOL, "micromaid": LIB, "mustache": LIB,
    "smacc": TOOL, "viennaTalk": TOOL, "bioSmalltalk": APP, "phausto": APP, "pakbot": TOOL,
    "historia": LIB, "reMobidyc": APP, "mcp": WEB, "openTelemetry": LIB,
    "jsonSchema": LIB, "soup": WEB, "asn1": LIB, "citezen": APP, "pharoCIG": TOOL,
    "novaStelo": APP, "openSmock": LIB, "geoView": LIB, "rediStick": LIB, "agenticBrowser": TOOL,
    "seasideBootstrap5": WEB, "sqlite3": LIB, "seamless": LIB, "specToplo": LIB, "rita":
    TOOL, "stateSpecs": LIB, "microKanren": LIB, "mocketry": LIB, "chipDesigner": APP,
    "rewriteToolsSet": TOOL, "pots": LIB, "awsSDK": WEB,
    "blocTutorials": DOC, "jrpc": WEB, "snapDump": WEB, "pTerm": APP, "punQLite": LIB,
    "aiDataInspector": TOOL, "methodProxies": LIB, "pharoFunctional": LIB, "zTimestamp": LIB, "hiedra":
    LIB, "gitMiner": TOOL, "xmlParserHTML": LIB, "webside": WEB,
}
FIELDS = ["project", "name", "set", "domain", "software_tool", "reedit", "authors", "top_author", "pr_merges",
          "age_years", "span_days", "test_share", "churn", "deps",
          "replayed", "method_changes", "bench_changes", "sites_confirmed", "head", "head_ref", "pairs_checked",
          "repository"]


class Git:
    def __init__(self, directory):
        self.dir = directory
        self.batch = None

    def run(self, *args, check=True):
        result = subprocess.run(["git", "-C", self.dir, *args], capture_output=True, text=True,
                                encoding="utf-8", errors="replace")
        if check and result.returncode:
            raise RuntimeError(f"git {' '.join(args)}: {result.stderr.strip()}")
        return result.stdout

    def blob(self, commit, path):
        """The content of path at commit, or None (one cat-file process for every read)."""
        if self.batch is None:
            self.batch = subprocess.Popen(["git", "-C", self.dir, "cat-file", "--batch"],
                                          stdin=subprocess.PIPE, stdout=subprocess.PIPE)
        self.batch.stdin.write(f"{commit}:{path}\n".encode())
        self.batch.stdin.flush()
        header = self.batch.stdout.readline().decode().split()
        if len(header) < 3 or header[1] == "missing":
            return None
        data = self.batch.stdout.read(int(header[2]))
        self.batch.stdout.read(1)
        return data.decode("utf-8", errors="replace")

    def close(self):
        if self.batch:
            self.batch.stdin.close()
            self.batch.wait()


def clone(url, clones):
    name = re.sub(r"\.git$", "", url.rstrip("/").split("/")[-1])
    owner = url.rstrip("/").split("/")[-2]
    directory = os.path.join(clones, f"{owner}__{name}.git")
    if os.path.isdir(directory):
        subprocess.run(["git", "-C", directory, "fetch", "--quiet", "--prune", "--tags", "origin",
                        "+refs/heads/*:refs/heads/*"], check=False)
    else:
        subprocess.run(["git", "clone", "--quiet", "--bare", url, directory], check=True)
    return Git(directory)


# ------------------------------------------------------------------ the run: what was replayed

def run_info(store, project):
    """Set, name, packages, replay length, run start, repository and (index -> commit) of a project."""
    info = {"project": project}
    for setname, folder in (("paper", "results"), ("extra", "results-extra")):
        d = os.path.join(store, folder, project)
        if os.path.isdir(d):
            info["set"], info["dir"] = setname, d
    if "dir" not in info:
        return None
    ston = glob.glob(os.path.join(info["dir"], "*-results.ston"))
    if not ston:
        return None
    info["name"] = re.search(r"#project:'([^']*)'", open(ston[0]).read()).group(1)
    pairs, sites = {}, defaultdict(set)
    for f in glob.glob(os.path.join(info["dir"], "*-callsites.csv")):
        for row in csv.DictReader(open(f, newline="")):
            if row.get("commit_index") and row.get("commit"):
                pairs[int(row["commit_index"])] = row["commit"]
                sites[int(row["commit_index"])].add(f"{row['class']}>>{row['method']}")
    info["pairs"], info["sites"] = pairs, sites
    statistics_text = open(ston[0]).read()
    scanned = re.search(r"#scannedMethods:(\d+)", statistics_text)
    info["bench_changes"] = int(scanned.group(1)) if scanned else None
    for log in sorted(glob.glob(os.path.join(store, "logs", f"{project}.*.log"))):
        text = open(log, errors="replace").read()
        replaying = re.findall(r"Replaying (\d+) commits on packages #\(([^)]*)\)", text)
        done = re.findall(r"Commit \d+/(\d+) done", text)
        repository = (re.findall(r"Running \w+ on (\S+),", text) or [None])[0]
        if replaying:
            info["packages"] = set(re.findall(r"'([^']+)'", replaying[-1][1]))
        elif done and repository:
            # Some logs lack the "Replaying" line (it goes through the Transcript): the project
            # packages are then the ones Metacello loaded from the project's repository, without
            # the BaselineOf, as CooHistoryExperimentRunner computes them.
            info["packages"] = {name for name in re.findall(
                r"Loaded -> (\S+) --- " + re.escape(repository), text) if not name.startswith("BaselineOf")}
            if not info["packages"]:
                del info["packages"]
                continue
        else:
            continue
        info["replayed"] = int(done[-1]) if done else int(replaying[-1][0]) - 1
        info["repository"] = repository
        start = re.findall(r"^======== (\S+ \S+) start", text, re.M)
        info["run_start"] = start[0] if start else None
        break
    return info if "packages" in info and info.get("repository") else None


def replay_window(git, info):
    """[commit of index 0 (initial state), index 1, ..., index replayed] or None."""
    n = info["replayed"]
    pairs = info["pairs"]
    candidates = []
    refs = git.run("for-each-ref", "--format=%(refname)", "refs/tags", "refs/heads").split()
    for line in sorted(refs, key=lambda r: not r.startswith("refs/tags/")):
        candidates.append((line, line + "^{commit}"))
        if line.startswith("refs/heads/") and info.get("run_start"):
            sha = git.run("rev-list", "-1", "--first-parent", f"--before={info['run_start']}", line, check=False).strip()
            if sha:
                candidates.append((f"{line}@{info['run_start']}", sha))
    seen = set()
    for ref, rev in candidates:
        head = git.run("rev-parse", "--verify", "--quiet", rev, check=False).strip()
        if not head or head in seen:
            continue
        seen.add(head)
        first_parent = git.run("rev-list", "--first-parent", f"--max-count={n + 1}", head).split()
        if len(first_parent) < n + 1:  # the n replayed commits and the initial state
            continue
        # replayed index i is the commit n - i steps before the head; index 0 is the initial state
        window = [first_parent[n - i] if n - i < len(first_parent) else None for i in range(n + 1)]
        if pairs and all(window[i] and window[i].startswith(sha) for i, sha in pairs.items() if i <= n):
            if all(i <= n for i in pairs):
                return window, ref, head
    # The loaded version may be a commit that no tag or branch points to any more. It is then the
    # commit n - i first-parent steps after the newest call-site commit (index i): looked for among
    # its descendants made before the run, and used only when exactly one commit fits.
    if not pairs or max(pairs) > n:
        return None
    newest = max(pairs)
    anchor = git.run("rev-parse", "--verify", "--quiet", pairs[newest] + "^{commit}", check=False).strip()
    if not anchor:
        return None
    steps = n - newest
    if steps == 0:
        heads = {anchor}
    else:
        before = [f"--before={info['run_start']}"] if info.get("run_start") else []
        descendants = git.run("rev-list", "--all", *before, "--ancestry-path", f"{anchor}..").split()
        heads = {d for d in descendants
                 if git.run("rev-parse", "--verify", "--quiet", f"{d}~{steps}", check=False).strip() == anchor}
    for head in heads:
        first_parent = git.run("rev-list", "--first-parent", f"--max-count={n + 1}", head).split()
        if len(first_parent) < n + 1:
            return None
        window = [first_parent[n - i] for i in range(n + 1)]
        if not all(window[i].startswith(sha) for i, sha in pairs.items()):
            return None
    if len(heads) != 1:
        return None
    head = heads.pop()
    return [git.run("rev-list", "--first-parent", f"--max-count={n + 1}", head).split()[n - i] for i in range(n + 1)], \
        f"commit {head[:7]}", head


# ------------------------------------------------------------------ methods changed by a commit

# "Class >> selector [" or "Class class >> selector [" (anything may follow the bracket)
TONEL_METHOD = re.compile(r"^([A-Za-z_]\w*(?: class)?) >> (.+?)\s\[")


def selector_of(header):
    keywords = re.findall(r"([A-Za-z_]\w*:)", header)
    return "".join(keywords) if keywords else header.split()[0]


def normalized(category, body_lines):
    """What a method is, independently of the file format: its category and its source lines (Tonel
    and FileTree keep the lines of a method as they are; only trailing spaces are dropped). A change
    of layout is a change, as for Pharo, whose history records it."""
    lines = [line.rstrip() for line in body_lines]
    while lines and not lines[-1]:
        lines.pop()
    return category.strip() + "\n" + "\n".join(lines)


def tonel_methods(text):
    """{Class>>selector: normalized method} of a Tonel class or extension file."""
    methods = {}
    if not text:
        return methods
    lines = text.replace("\r\n", "\n").split("\n")
    i = 0
    while i < len(lines):
        m = TONEL_METHOD.match(lines[i])
        if m:
            j = i + 1
            while j < len(lines) and lines[j].rstrip() != "]":
                j += 1
            # the category counts: moving a method to another protocol is a modification for
            # Pharo, and the history of the benchmark records it (its value, not its syntax)
            metadata = lines[i - 1] if i > 0 and lines[i - 1].lstrip().startswith("{") else ""
            category = re.search(r"#category\s*:\s*#?'?([^'},]*)", metadata)
            methods[f"{m.group(1)}>>{selector_of(m.group(2))}"] = normalized(
                category.group(1) if category else "", lines[i + 1:j])
            i = j
        i += 1
    return methods


def package_of(path, packages):
    """(package, format) of a source file of one of the packages, or None. The project's baselines
    (BaselineOf...) count too: the benchmark completes the call sites of the methods they change."""
    parts = path.split("/")
    ours = lambda name: name in packages or name.startswith("BaselineOf")
    if not parts[-1].endswith(".st"):
        return None
    for part in parts[:-1]:
        if part.endswith(".package") and ours(part[:-8]):
            return part[:-8], "filetree"
        if ours(part):
            return part, "tonel"
    return None


# FileTree file names: keywords end with "." instead of ":", binary selectors are spelled out
FILETREE_SYMBOLS = {"plus": "+", "minus": "-", "star": "*", "slash": "/", "backslash": "\\", "tilde": "~",
                    "less": "<", "more": ">", "equals": "=", "at": "@", "percent": "%", "pipe": "|",
                    "and": "&", "wat": "?", "comma": ","}


def filetree_selector(stem):
    if stem.startswith("^"):
        return "".join(FILETREE_SYMBOLS.get(word, word) for word in stem[1:].split("."))
    return stem.replace(".", ":")


def file_methods(git, commit, path, fmt):
    """{key: (class, normalized method)} defined by one source file at commit."""
    if fmt == "tonel":
        if path.endswith("package.st"):
            return {}
        return {key: (key.split(">>")[0], source) for key, source in tonel_methods(git.blob(commit, path)).items()}
    parts = path.split("/")
    # <pkg>.package/<Class>.class|extension/instance|class/<selector>.st: category, header, body
    if len(parts) >= 3 and parts[-2] in ("instance", "class") and re.search(r"\.(class|extension)$", parts[-3]):
        class_name = parts[-3].rsplit(".", 1)[0] + (" class" if parts[-2] == "class" else "")
        lines = (git.blob(commit, path) or "").replace("\r\n", "\n").replace("\r", "\n").split("\n")
        key = f"{class_name}>>{filetree_selector(parts[-1][:-3])}"
        return {key: (class_name, normalized(lines[0] if lines else "", lines[2:]))}
    return {}


class MethodState:
    """Every method of the packages, followed commit by commit. A method changes when its source or
    category differs from what it was before the commit, wherever it was defined: a method moved to
    another file, folder or format (Glorp went from FileTree to Tonel) is not a change."""

    def __init__(self, git, packages):
        self.git, self.packages = git, packages
        self.methods = {}     # key -> (package, class, normalized)
        self.files = {}       # path -> keys it defines

    def load(self, commit):
        for path in self.git.run("ls-tree", "-r", "--name-only", commit).splitlines():
            found = package_of(path, self.packages)
            if found:
                defined = file_methods(self.git, commit, path, found[1])
                self.files[path] = set(defined)
                self.methods.update({k: (found[0], c, s) for k, (c, s) in defined.items()})

    def apply(self, parent, commit):
        """[(package, class, key)] of the methods the commit adds or modifies."""
        gone, new = set(), {}
        out = self.git.run("diff-tree", "-r", "--no-commit-id", "--name-status", "--no-renames", parent, commit)
        for line in out.splitlines():
            status, _, path = line.partition("\t")
            found = package_of(path, self.packages)
            if not found:
                continue
            gone |= self.files.pop(path, set())
            if not status.startswith("D"):
                defined = file_methods(self.git, commit, path, found[1])
                self.files[path] = set(defined)
                new.update({k: (found[0], c, s) for k, (c, s) in defined.items()})
        changed = [(p, c, k) for k, (p, c, s) in new.items()
                   if k not in self.methods or self.methods[k][2] != s]
        for key in gone - set(new):
            self.methods.pop(key, None)
        self.methods.update(new)
        return changed


# ------------------------------------------------------------------ the properties

def identities(rows):
    """Merge the authors that share a name or an e-mail address: {(name, email): identity}."""
    parent = {}

    def find(x):
        while parent.setdefault(x, x) != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for name, email in rows:
        keys = [k for k in (("n", name.strip().lower()), ("e", normalized_email(email))) if k[1]]
        for k in keys[1:]:
            parent[find(keys[0])] = find(k)
        if keys:
            find(keys[0])
    return {(name, email): find(("n", name.strip().lower())) if name.strip() else find(("e", normalized_email(email)))
            for name, email in rows}


def normalized_email(email):
    email = email.strip().lower()
    m = re.match(r"^(?:\d+\+)?([^@]+)@users\.noreply\.github\.com$", email)
    return f"github:{m.group(1)}" if m else email


def baseline_dependencies(git, head):
    files = [p for p in git.run("ls-tree", "-r", "--name-only", head).splitlines()
             if re.search(r"(^|/)BaselineOf\w+(\.package)?/", p) and p.endswith(".st")]
    own = {re.search(r"BaselineOf(\w+)", p).group(1) for p in files}
    names = set()
    for p in files:
        text = git.blob(head, p) or ""
        names.update(re.findall(r"\b(?:baseline|project):\s*['#]([A-Za-z]\w*)", text))
    return len(names - own)


def features(info, clones):
    git = clone(info["repository"], clones)
    try:
        found = replay_window(git, info)
        if not found:
            print(f"  {info['project']}: no tag or branch matches the replayed commits: left out", file=sys.stderr)
            return None
        window, ref, head = found
        n = info["replayed"]
        per_commit, earlier, reedits, later_changes, test_changes = [], set(), 0, 0, 0
        sites_total = sites_found = 0
        merges = 0
        state = MethodState(git, info["packages"])
        state.load(window[0])
        for i in range(1, n + 1):
            commit = window[i]
            parents = git.run("rev-list", "--parents", "-n", "1", commit).split()[1:]
            merges += len(parents) > 1
            changes = state.apply(window[i - 1], commit)
            keys = {key for (_, _, key) in changes}
            sites_total += len(info["sites"].get(i, ()))
            sites_found += len(info["sites"].get(i, set()) & keys)
            if i >= 2:
                later_changes += len(keys)
                reedits += len(keys & earlier)
            earlier |= keys
            seen = set()
            for package, class_name, key in changes:
                if key not in seen:
                    seen.add(key)
                    test_changes += is_test_code({"package": package, "class": class_name})
            if keys:
                per_commit.append(len(keys))
        method_changes = sum(per_commit)
        log = git.run("log", "--no-merges", "--format=%an%x09%ae", f"{window[0]}..{window[n]}")
        rows = [tuple(line.split("\t", 1)) for line in log.splitlines() if "\t" in line]
        ids = identities(rows)
        counts = Counter(ids[row] for row in rows)
        date = lambda sha: int(git.run("log", "-1", "--format=%ct", sha).strip())
        roots = [int(t) for t in git.run("log", "--max-parents=0", "--format=%at", head).split()]
        last = date(window[n])
        project = info["project"]
        return {
            "project": project, "name": info["name"], "set": info["set"],
            "domain": DOMAINS.get(project, ""), "software_tool": int(DOMAINS.get(project) == TOOL),
            "reedit": round(reedits / later_changes, 4) if later_changes else "",
            "authors": len(counts),
            "top_author": round(max(counts.values()) / sum(counts.values()), 4) if counts else "",
            "pr_merges": round(merges / n, 4),
            "age_years": round((last - min(roots)) / (365.25 * 86400), 2) if roots else "",
            "span_days": round((last - date(window[0])) / 86400, 1),
            "test_share": round(test_changes / method_changes, 4) if method_changes else "",
            "churn": statistics.median(per_commit) if per_commit else 0,
            "deps": baseline_dependencies(git, head),
            "replayed": n, "method_changes": method_changes, "head": head, "head_ref": ref,
            "pairs_checked": len(info["pairs"]), "repository": info["repository"],
            "bench_changes": info["bench_changes"],
            "sites_confirmed": round(sites_found / sites_total, 4) if sites_total else "",
        }
    finally:
        git.close()


def main():
    args = sys.argv[1:]
    if len(args) < 2:
        sys.exit(__doc__)
    store, output = args[0], args[1]
    clones = os.path.join(store, "repo-clones")
    if "--clones" in args:
        k = args.index("--clones")
        clones = args[k + 1]
        del args[k:k + 2]
    wanted = args[2:]
    os.makedirs(clones, exist_ok=True)
    projects = sorted({os.path.basename(d.rstrip("/")) for folder in ("results", "results-extra")
                       for d in glob.glob(os.path.join(store, folder, "*/"))})
    rows = []
    for project in projects:
        if wanted and project not in wanted:
            continue
        info = run_info(store, project)
        if not info:
            print(f"  {project}: no complete results or no replay log: left out", file=sys.stderr)
            continue
        try:
            row = features(info, clones)
        except (RuntimeError, subprocess.CalledProcessError) as error:
            print(f"  {project}: {error}: left out", file=sys.stderr)
            row = None
        if row:
            rows.append(row)
            print(f"{project}: {row['head_ref']} ({row['pairs_checked']} call-site commits at their index), "
                  f"{row['replayed']} commits, {row['method_changes']} method changes (benchmark: {row['bench_changes']}, "
                  f"call-site methods confirmed: {row['sites_confirmed']}), re-edit {row['reedit']}, {row['authors']} authors")
    with open(output, "w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=FIELDS, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    print(f"{len(rows)} project(s) written to {output}")


if __name__ == "__main__":
    main()
