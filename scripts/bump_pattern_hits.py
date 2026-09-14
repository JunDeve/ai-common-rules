#!/usr/bin/env python3
"""Increments a PATTERNS.md entry's Hits count and LastSeen date, by ID.

Identifying which anti-pattern a piece of negative feedback matches (or
whether it's a NEW one) needs judgment, so that stays Claude's job. The
arithmetic doesn't: this script does the read-increment-write instead of
Claude hand-editing the number, so a Hits column can't drift from silent
off-by-one mistakes.

Usage: python scripts/bump_pattern_hits.py <ID>
"""

import datetime
import re
import sys
from pathlib import Path

# Same cp949-default-console fix as scripts/validate.py -- PATTERNS.md rows
# are full of Korean text that a plain Windows console can't otherwise print.
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

ID_CELL_RE = re.compile(r"^\|\s*\*\*(\S+)\*\*\s*\|")


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: bump_pattern_hits.py <ID>", file=sys.stderr)
        return 1

    target = sys.argv[1].upper()
    path = Path(__file__).resolve().parent.parent / "PATTERNS.md"
    lines = path.read_text(encoding="utf-8").splitlines()

    for i, line in enumerate(lines):
        m = ID_CELL_RE.match(line)
        if not m or m.group(1) != target:
            continue

        cells = line.split("|")
        if len(cells) < 8:
            print(f"row for {target!r} does not have the expected columns: {line!r}", file=sys.stderr)
            return 1

        hits_idx, lastseen_idx = 6, 7
        try:
            hits = int(cells[hits_idx].strip())
        except ValueError:
            print(f"Hits column for {target!r} is not a number: {cells[hits_idx]!r}", file=sys.stderr)
            return 1

        new_hits = hits + 1
        cells[hits_idx] = f" {new_hits} "
        cells[lastseen_idx] = f" {datetime.date.today().isoformat()} "
        lines[i] = "|".join(cells)
        path.write_text("\n".join(lines) + "\n", encoding="utf-8")

        print(f"{target}: Hits {hits} -> {new_hits}")
        if new_hits >= 3:
            print(f"{target} reached Hits >= 3 -- review for promotion to CLAUDE.md's always-on C/H table.")
        return 0

    print(
        f"no PATTERNS.md row for ID {target!r} -- add the row first "
        "(see PATTERNS.md '기록 형식'), then bump it",
        file=sys.stderr,
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
