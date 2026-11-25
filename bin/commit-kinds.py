#!/usr/bin/env python3
"""Label every replayed commit of every project by what it does to the code, from git alone.

    commit-kinds.py STORE OUTPUT_CSV [--clones DIR] [PROJECT ...]

The commits are exactly those the benchmark replayed (the window of bin/repo-features.py), and the
methods they change are found as bin/repo-features.py finds them (MethodState: a method changes when
its source or category differs from what it was before the commit). For every commit it counts

  added       methods that did not exist before the commit (new code);
  modified    existing methods whose source or category the commit changes;
  removed     methods the commit deletes;
  new_classes classes that had no method before the commit and have one after it;
  fix_message 1 when the subject or body of the commit (a merge: the pull request's title and branch)
              names a fix: fix, bug, error, crash, broken, repair, regression, typo, wrong, revert...

and labels it with one kind (KINDS):

  development  it adds at least as many methods as it modifies: mostly new code;
  bug fix      it modifies more methods than it adds, and its message names a fix;
  other edit   it modifies more methods than it adds, without naming a fix (refactoring, tuning);
  no code      it changes no method of the replayed packages (no call site can come from it).

Nothing here reads the completion results: the labels are known before any replay.
"""
import csv, importlib.util, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
spec = importlib.util.spec_from_file_location("repo_features", os.path.join(HERE, "repo-features.py"))
rf = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rf)

FIX = re.compile(r"\b(fix|fixe[sd]|fixing|bug|bugs|bugfix|hotfix|error|errors|crash|crashes|broken|repair|"
                 r"repaired|regression|typo|typos|wrong|failing|failure|revert|reverted|workaround)\b", re.I)
KINDS = ["development", "bug fix", "other edit", "no code"]
FIELDS = ["project", "set", "index", "commit", "added", "modified", "removed", "new_classes", "fix_message", "kind"]


def words(text):
    """camelCase and the separators of branch names become spaces (Merge ... from x/42-Fix-the-parser)."""
    text = re.sub(r"([a-z])([A-Z])", r"\1 \2", text)
    return re.sub(r"[-_/:#()\[\].,'\"`]", " ", text)


def kind_of(added, modified, fix):
    if added + modified == 0:
        return "no code"
    if added >= modified:
        return "development"
    return "bug fix" if fix else "other edit"


def classes_of(state):
    """The classes that have a method (instance or class side: one class)."""
    return {c[:-len(" class")] if c.endswith(" class") else c for (_, c, _) in state.methods.values()}


def commit_kinds(info, clones):
    git = rf.clone(info["repository"], clones)
    try:
        found = rf.replay_window(git, info)
        if not found:
            print(f"  {info['project']}: no tag or branch matches the replayed commits: left out", file=sys.stderr)
            return None
        window, ref, head = found
        state = rf.MethodState(git, info["packages"])
        state.load(window[0])
        rows = []
        for i in range(1, info["replayed"] + 1):
            commit = window[i]
            before = set(state.methods)
            classes_before = classes_of(state)
            changes = state.apply(window[i - 1], commit)
            keys = {key for (_, _, key) in changes}
            added = len(keys - before)
            modified = len(keys & before)
            removed = len(before - set(state.methods))
            new_classes = len(classes_of(state) - classes_before)
            message = git.run("log", "-1", "--format=%s%n%b", commit)
            fix = int(bool(FIX.search(words(message))))
            rows.append({"project": info["project"], "set": info["set"], "index": i, "commit": commit,
                         "added": added, "modified": modified, "removed": removed, "new_classes": new_classes,
                         "fix_message": fix, "kind": kind_of(added, modified, fix)})
        return rows
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
                       for d in __import__("glob").glob(os.path.join(store, folder, "*/"))})
    rows = []
    for project in projects:
        if wanted and project not in wanted:
            continue
        info = rf.run_info(store, project)
        if not info:
            print(f"  {project}: no complete results or no replay log: left out", file=sys.stderr)
            continue
        try:
            found = commit_kinds(info, clones)
        except (RuntimeError, OSError) as error:
            print(f"  {project}: {error}: left out", file=sys.stderr)
            found = None
        if found:
            rows += found
            counts = {k: sum(r["kind"] == k for r in found) for k in KINDS}
            print(f"{project}: {len(found)} commits, " + ", ".join(f"{k} {v}" for k, v in counts.items()))
    with open(output, "w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=FIELDS, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    print(f"{len(rows)} commit(s) of {len({r['project'] for r in rows})} project(s) written to {output}")


if __name__ == "__main__":
    main()
