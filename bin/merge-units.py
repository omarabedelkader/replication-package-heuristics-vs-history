#!/usr/bin/env python3
"""Join the units of one project into its results directory.

    merge-units.py OUTPUT_DIR UNIT_DIR...

Every unit replayed the same commits with the same history and completed only the call sites of
its strategy and slice (see HvhReplication class>>#benches:id:), so:
  - <project>-ranks.csv      is the concatenation of the units' rows (one row per call site,
                             strategy and prefix: each row comes from exactly one unit);
  - <project>-callsites.csv  is the union of the units' rows, by (kind, id): a call site is
                             described by every unit that completed it, with the same values;
  - <project>-results.ston   project statistics, the same in every unit (the counters are taken
                             before a call site is left to another unit): the first unit's.
The units' own figures and LaTeX tables only cover their strategy, so they are not copied.
"""
import csv, os, shutil, sys

csv.field_size_limit(10 ** 9)
out, units = sys.argv[1], sys.argv[2:]

def single(folder, suffix):
    found = [f for f in os.listdir(folder) if f.endswith(suffix)]
    if len(found) != 1:
        sys.exit(f"{folder}: expected one *{suffix}, found {found}")
    return found[0]

names = {suffix: single(units[0], suffix) for suffix in ("-ranks.csv", "-callsites.csv", "-results.ston")}
for unit in units[1:]:
    for suffix, name in names.items():
        if single(unit, suffix) != name:
            sys.exit(f"{unit}: {suffix} file is not named {name}")

tmp = out + ".tmp"
shutil.rmtree(tmp, ignore_errors=True)
os.makedirs(tmp)

rows = 0
with open(os.path.join(tmp, names["-ranks.csv"]), "w", newline="") as target:
    writer = None
    for unit in units:
        with open(os.path.join(unit, names["-ranks.csv"]), newline="") as source:
            reader = csv.reader(source)
            header = next(reader)
            if writer is None:
                writer = csv.writer(target, lineterminator="\n"); writer.writerow(header)
            for row in reader:
                writer.writerow(row); rows += 1

seen, described, conflicts = {}, 0, 0
with open(os.path.join(tmp, names["-callsites.csv"]), "w", newline="") as target:
    writer = None
    for unit in units:
        with open(os.path.join(unit, names["-callsites.csv"]), newline="") as source:
            reader = csv.reader(source)
            header = next(reader)
            if writer is None:
                writer = csv.writer(target, lineterminator="\n"); writer.writerow(header)
            for row in reader:
                key = (row[0], row[1])
                if key in seen:
                    conflicts += seen[key] != row
                    continue
                seen[key] = row; writer.writerow(row); described += 1

shutil.copy(os.path.join(units[0], names["-results.ston"]), tmp)
shutil.rmtree(out, ignore_errors=True)
os.rename(tmp, out)
print(f"{out}: {len(units)} unit(s), {rows} rank rows, {described} call sites"
      + (f", {conflicts} call site(s) described differently by two units" if conflicts else ""))
