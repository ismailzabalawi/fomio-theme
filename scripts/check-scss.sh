#!/usr/bin/env bash
# Compiles the theme's SCSS against stubs for the values Discourse injects:
# core's lib/viewport module (and, once settings.yml returns, the theme
# settings as SCSS variables).
set -uo pipefail
cd "$(dirname "$0")/.."

command -v sass >/dev/null || { echo "sass not found — gem install sass"; exit 2; }

work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
mkdir -p "$work/lib"
cat > "$work/lib/_viewport.scss" <<'STUB'
@use "sass:map";
$breakpoints: (sm: 40rem, md: 48rem, lg: 64rem, xl: 80rem);
@mixin from($name) { @media (min-width: map.get($breakpoints, $name)) { @content; } }
@mixin until($name) { @media (width < #{map.get($breakpoints, $name)}) { @content; } }
STUB

fail=0
# The theme has no settings.yml yet. When one returns, write its values as
# SCSS variables above the stylesheet here, one compile per enum combination.
cp common/common.scss "$work/t.scss"
if out=$(cd "$work" && sass --no-source-map --load-path=. t.scss o.css 2>&1) && [ -z "$out" ]; then
  :
else
  echo "$out" | head -8; fail=1
fi

[ "$fail" -eq 0 ] && printf '\033[32m✓ scss compiles\033[0m\n'
exit "$fail"
