#!/usr/bin/env python3
"""UserPromptSubmit hook: detect negative feedback, nudge PATTERNS.md upkeep.

Fires on every prompt, so it must fail silently and never block. Any error
here -- unreadable stdin, missing "prompt" key, whatever -- exits 0 with no
output, which is the same as "no match found." A broken or missing Python on
the user's machine has the same effect: the hook fails to run at all, Claude
Code proceeds without the extra context, and the session is unaffected. This
is deliberate -- see CLAUDE.md GC TRIGGERS and PATTERNS.md.
"""

import json
import re
import sys

PATTERNS = [
    r"틀렸",
    r"그렇게\s*하지\s*마",
    r"잘못(됐|된|됐다)",
    r"\bthat'?s\s+wrong\b",
    r"\bthat\s+is\s+wrong\b",
    r"\bdon'?t\s+do\s+that\b",
    r"\bnot\s+correct\b",
    r"\bincorrect\b",
]

CONTEXT = (
    "Negative feedback detected in this prompt (see CLAUDE.md GC TRIGGERS). "
    "Before continuing: read PATTERNS.md, identify the anti-pattern entry this "
    "feedback matches (or note it needs a NEW row per PATTERNS.md's '기록 형식'), "
    "then run `python scripts/bump_pattern_hits.py <ID>` to increment its Hits "
    "count -- don't hand-edit the number."
)


def main() -> int:
    try:
        # sys.stdin decodes with the system locale encoding (cp949 on Korean
        # Windows), which mangles or drops the UTF-8 JSON Claude Code sends.
        # Read raw bytes and decode explicitly instead.
        raw = sys.stdin.buffer.read()
        data = json.loads(raw.decode("utf-8"))
        prompt = data.get("prompt", "")
        if not isinstance(prompt, str) or not prompt:
            return 0
    except Exception:
        return 0

    if not any(re.search(p, prompt, re.IGNORECASE) for p in PATTERNS):
        return 0

    try:
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "UserPromptSubmit",
                "additionalContext": CONTEXT,
            }
        }))
    except Exception:
        return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
