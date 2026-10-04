#!/usr/bin/env bash
# Guards the rule that the previous Fomio web theme broke: no hardcoded values.
# Colours come from the colour scheme, strings from text customization, and
# structure from the category tree — never from literals in theme code.
set -uo pipefail
cd "$(dirname "$0")/.."

fail=0
report() { printf '\n\033[31m✗ %s\033[0m\n' "$1"; shift; printf '%s\n' "$@"; fail=1; }

# 1. Hex colours in SCSS. Colours belong in about.json colour schemes, and are
#    consumed as var(--primary) etc. so admins can retheme without a code change.
hits=$(grep -rnE '#[0-9a-fA-F]{3,8}\b' --include='*.scss' common desktop mobile 2>/dev/null \
  | grep -v '^\s*//' | grep -viE '//.*#' || true)
if [ -n "$hits" ]; then
  report "Hex colour in SCSS — use the colour scheme (var(--primary), var(--tertiary), ...)" "$hits"
fi

# 2. rgb()/rgba() literals, same reason. rgba(var(--primary-rgb), .5) is fine.
hits=$(grep -rnE 'rgba?\([0-9]' --include='*.scss' common desktop mobile 2>/dev/null || true)
if [ -n "$hits" ]; then
  report "Literal rgb()/rgba() in SCSS — use rgba(var(--primary-rgb), …)" "$hits"
fi

# 3. The dropped Hub/Teret/Byte naming. Fomio uses Discourse's own words
#    (category, subcategory, topic) and renames nothing — keep it out of code.
hits=$(grep -rnwE 'Hub|Hubs|Teret|Terets|Byte|Bytes' \
  --include='*.scss' --include='*.js' --include='*.gjs' --include='*.hbs' --include='*.html' \
  common desktop mobile javascripts 2>/dev/null || true)
if [ -n "$hits" ]; then
  report "Hub/Teret/Byte in theme code — use Discourse's own wording" "$hits"
fi

if [ "$fail" -eq 0 ]; then
  printf '\033[32m✓ native check passed\033[0m — no hardcoded colours, or vocabulary\n'
fi
exit "$fail"
