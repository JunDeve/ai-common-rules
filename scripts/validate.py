#!/usr/bin/env python3
"""Structural checks for the ai-common-rules plugin.

This repository ships markdown and JSON, so nothing here compiles and there is
no test suite to catch a mistake. What does break is structural: a skill whose
frontmatter stops parsing, a marketplace entry pointing at a path that moved, a
doc linking to a file that was never written, a Korean README that silently
falls behind the English one.

Every check below exists because that class of mistake reached master at least
once. Run with no arguments from the repository root.
"""

import json
import re
import sys
from pathlib import Path

# The Windows console defaults to cp949 here, which cannot encode the em dashes
# these files are full of.
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parent.parent
failures: list[str] = []
checks_run = 0


def check(label: str, ok: bool, detail: str = "") -> None:
    global checks_run
    checks_run += 1
    if ok:
        print(f"  ok    {label}")
    else:
        print(f"  FAIL  {label}" + (f" -- {detail}" if detail else ""))
        failures.append(label)


def load_json(rel: str):
    path = ROOT / rel
    if not path.exists():
        check(f"{rel} exists", False)
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        check(f"{rel} parses", False, str(exc))
        return None
    check(f"{rel} parses", True)
    return data


print("manifests")
plugin = load_json(".claude-plugin/plugin.json")
market = load_json(".claude-plugin/marketplace.json")

hooks_path = ROOT / "hooks" / "hooks.json"
if hooks_path.exists():
    hooks = load_json("hooks/hooks.json")
    if hooks is not None:
        check("hooks/hooks.json has a top-level 'hooks' object", isinstance(hooks.get("hooks"), dict))
        for event, groups in hooks.get("hooks", {}).items():
            for i, group in enumerate(groups):
                for j, h in enumerate(group.get("hooks", [])):
                    check(
                        f"hooks.json {event}[{i}].hooks[{j}] declares command",
                        bool(h.get("command")),
                        str(h),
                    )
                    # A script referenced via ${CLAUDE_PLUGIN_ROOT}/... in args
                    # has to actually exist, or the hook silently no-ops.
                    for arg in h.get("args", []):
                        if arg.startswith("${CLAUDE_PLUGIN_ROOT}/"):
                            rel = arg[len("${CLAUDE_PLUGIN_ROOT}/"):]
                            check(f"hooks.json {event}[{i}].hooks[{j}] script exists: {rel}", (ROOT / rel).exists())

if plugin and market:
    entries = {p["name"]: p for p in market.get("plugins", [])}
    check(
        "marketplace lists this plugin",
        plugin["name"] in entries,
        f"{plugin['name']} not in {sorted(entries)}",
    )

    # A marketplace entry may carry its own version. When it does and it
    # disagrees with plugin.json, Claude Code resolves updates against one of
    # them and reports the other, so the two must agree.
    self_entry = entries.get(plugin["name"], {})
    if "version" in self_entry:
        check(
            "marketplace entry version matches plugin.json",
            self_entry["version"] == plugin["version"],
            f"{self_entry['version']} vs {plugin['version']}",
        )

    # Every dependency has to resolve inside this marketplace. A bare-name
    # dependency pointing at nothing fails at install time on the user's
    # machine, not here, unless this check catches it.
    for dep in plugin.get("dependencies", []):
        name = dep if isinstance(dep, str) else dep["name"]
        if isinstance(dep, dict) and dep.get("marketplace"):
            continue  # cross-marketplace, resolved elsewhere by design
        check(f"dependency {name!r} resolves in this marketplace", name in entries)

    for name, entry in entries.items():
        src = entry.get("source")
        if isinstance(src, str):
            check(f"source path exists for {name!r}", (ROOT / src).exists(), src)

print("\npython scripts")
import py_compile
import tempfile

for py in sorted(ROOT.rglob("*.py")):
    if ".git" in py.parts:
        continue
    with tempfile.TemporaryDirectory() as tmp:
        try:
            py_compile.compile(str(py), cfile=str(Path(tmp) / "out.pyc"), doraise=True)
            check(f"{py.relative_to(ROOT).as_posix()} compiles", True)
        except py_compile.PyCompileError as exc:
            check(f"{py.relative_to(ROOT).as_posix()} compiles", False, str(exc))

print("\nskills")
skill_dirs = sorted(p for p in (ROOT / "skills").iterdir() if p.is_dir()) if (ROOT / "skills").is_dir() else []
check("skills/ has at least one skill", bool(skill_dirs))

for d in skill_dirs:
    md = d / "SKILL.md"
    if not md.exists():
        check(f"{d.name}/SKILL.md exists", False)
        continue
    text = md.read_text(encoding="utf-8")
    m = re.match(r"^---\r?\n(.*?)\r?\n---\r?\n", text, re.S)
    if not m:
        check(f"{d.name} frontmatter parses", False, "no --- delimited block at top of file")
        continue
    fm = m.group(1)
    name = re.search(r"^name:\s*(\S+)\s*$", fm, re.M)
    desc = re.search(r"^description:\s*(\S.*)$", fm, re.M)
    check(f"{d.name} declares name", bool(name))
    check(f"{d.name} declares description", bool(desc))
    if name:
        # The skill is invoked as /<name>, so a name that disagrees with the
        # directory makes the docs wrong in a way nothing else surfaces.
        check(
            f"{d.name} name matches directory",
            name.group(1) == d.name,
            f"frontmatter says {name.group(1)!r}",
        )

print("\ndocument links")
md_files = [p for p in ROOT.rglob("*.md") if ".git" not in p.parts]
link_re = re.compile(r"\[[^\]]*\]\((?!https?://|#)([^)]+?\.md)(?:#[^)]*)?\)")
for p in md_files:
    for target in link_re.findall(p.read_text(encoding="utf-8")):
        rel = p.parent / target
        check(
            f"{p.relative_to(ROOT).as_posix()} -> {target}",
            rel.exists(),
            "target missing",
        )

print("\ntranslation parity")
en, ko = ROOT / "README.md", ROOT / "README.ko.md"
if en.exists() and ko.exists():
    heading = re.compile(r"^#{2,3} ", re.M)
    n_en = len(heading.findall(en.read_text(encoding="utf-8")))
    n_ko = len(heading.findall(ko.read_text(encoding="utf-8")))
    # Not a translation quality check — it catches a section added to one
    # README and forgotten in the other, which is how they drifted before.
    check(
        "README.md and README.ko.md have the same section count",
        n_en == n_ko,
        f"English {n_en}, Korean {n_ko}",
    )
else:
    check("both READMEs exist", False)

print(f"\n{checks_run - len(failures)}/{checks_run} passed")
if failures:
    print("\nfailed:")
    for f in failures:
        print(f"  - {f}")
    sys.exit(1)
