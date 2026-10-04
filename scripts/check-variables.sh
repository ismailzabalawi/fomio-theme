#!/usr/bin/env bash
# Checks every CSS custom property the theme touches against the names Discourse
# actually defines.
#
# This closes the gap check-native.sh structurally can't see: a misspelled or
# invented custom property is not a literal, and CSS fails silently on unknown
# ones — so a dead rule looks exactly like a working one. It also enforces R3
# (no new variable namespace): a property the theme SETS that core doesn't
# define is either a typo or a new namespace, and both are violations.
#
# Point DISCOURSE_SRC at a Discourse checkout. Skipped (not failed) when absent,
# so the check never blocks someone who doesn't have one.
set -uo pipefail
cd "$(dirname "$0")/.."

SRC="${DISCOURSE_SRC:-/Users/ismailzabalawi/Projects/Fomio/discourse}"

if [ ! -d "$SRC/app/assets/stylesheets" ]; then
  printf '\033[33m⚠ skipped\033[0m — no Discourse checkout at %s\n' "$SRC"
  printf '  set DISCOURSE_SRC to enable the variable-name check\n'
  exit 0
fi

python3 - "$SRC" <<'PY'
import re, sys, pathlib

src = pathlib.Path(sys.argv[1])
theme = pathlib.Path(".")

DEF = re.compile(r'(--[a-z0-9_][a-z0-9_-]*)\s*:')
USE = re.compile(r'var\(\s*(--[a-z0-9_][a-z0-9_-]*)')

def scan(roots, pattern, exts=(".scss", ".css")):
    found = set()
    for root in roots:
        if not root.exists():
            continue
        for f in root.rglob("*"):
            if f.suffix in exts and f.is_file():
                found |= set(pattern.findall(f.read_text(encoding="utf-8", errors="replace")))
    return found

core = scan([src / "app/assets/stylesheets", src / "plugins"], DEF)
# Font variables are emitted from Ruby, generated from the base_font and
# heading_font site settings, so they never appear in a stylesheet.
core |= scan([src / "lib/stylesheet"], DEF, exts=(".rb",))

theme_files = [theme / "common", theme / "desktop", theme / "mobile"]
sets = scan(theme_files, DEF)
uses = scan(theme_files, USE)

bad_set = sorted(sets - core)
bad_use = sorted(uses - core - sets)

fail = False
if bad_set:
    fail = True
    print("\033[31m✗ the theme SETS custom properties Discourse doesn't define\033[0m")
    print("  Either a typo (the rule is dead and silent) or a new namespace (R3).")
    for n in bad_set:
        print(f"    {n}")
if bad_use:
    fail = True
    print("\033[31m✗ the theme READS custom properties nothing defines\033[0m")
    print("  These resolve to nothing at runtime, with no error.")
    for n in bad_use:
        print(f"    {n}")

if not fail:
    print(f"\033[32m✓ variable check passed\033[0m — {len(sets)} set, {len(uses)} read, "
          f"all known to core ({len(core)} defined)")
print(f"  checked against {src.name} — confirm it matches the server's version")
sys.exit(1 if fail else 0)
PY
