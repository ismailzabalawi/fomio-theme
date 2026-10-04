#!/usr/bin/env bash
# Guards the other way the previous Fomio web theme broke: inserting a design
# instead of restyling Discourse. A design's own header, nav or phone frame,
# injected through a theme HTML field or a plugin outlet, renders on top of
# Discourse's real one — two of everything, and nothing lines up.
#
# Discourse renders the header, lists, posts, composer and preferences. New
# markup is allowed only where core has nothing, and each place is named in
# advance in the allowlist below. Adding one is a decision: record it in
# docs/03 when you add it here.
set -uo pipefail
cd "$(dirname "$0")/.."

fail=0
report() { printf '\n\033[31m✗ %s\033[0m\n' "$1"; shift; printf '%s\n' "$@"; fail=1; }

# Every outlet, panel and connector the theme may render into.
# Phase 2 names the outlets the main-screen framework needs here, one at a
# time, each recorded in docs/03.
#   below-footer — mobile bottom bar (2A); fixed-position, so its place in
#                  the DOM only matters for stacking
#   category-heading — visible category/subcategory identity where core's
#                      native logo-led header has no visible name (2B)
#   topic-list-bottom — core's empty-list state for visitors, after core's
#                       own content (__after); core renders none (4.5)
#   before-composer-fields — native draft text on phones and the approved
#                            offline-close warning (docs/20); no new actions
#   after-composer-category-input — read-only native category audience (docs/21)
ALLOWED_OUTLETS="
below-footer
category-heading
topic-list-bottom
before-composer-fields
after-composer-category-input
"
ALLOWED_PANELS="
"

# 1. Theme HTML fields (header.html, after_header.html, head_tag.html, …).
#    The theme has none; any layout markup there sits beside core's.
hits=$(find common desktop mobile -name '*.html' 2>/dev/null || true)
if [ -n "$hits" ]; then
  report "Theme HTML field — restyle core's markup instead of adding a copy" "$hits"
fi

# 2. Connector files. Outlets are rendered from initializers, where step 3
#    can see them; a connectors/ folder bypasses the allowlist.
hits=$(find javascripts -type d -name connectors 2>/dev/null || true)
if [ -n "$hits" ]; then
  report "Connector folder — render outlets with api.renderInOutlet so they're allowlisted" "$hits"
fi

# 3. Outlets, including wrapper outlets, against the allowlist.
while IFS= read -r line; do
  [ -z "$line" ] && continue
  name=$(printf '%s' "$line" | sed -nE 's/.*render(InOutlet|BeforeWrapperOutlet|AfterWrapperOutlet)\(\s*"([^"]+)".*/\2/p')
  if [ -z "$name" ]; then
    report "Outlet with a computed name — write it literally so this check can read it" "$line"
  elif ! printf '%s\n' "$ALLOWED_OUTLETS" | grep -qxF "$name"; then
    report "Outlet \"$name\" is not on the allowlist in scripts/check-duplication.sh" "$line"
  fi
done < <(grep -rnE 'render(InOutlet|BeforeWrapperOutlet|AfterWrapperOutlet)\(' javascripts 2>/dev/null || true)

# 4. Sidebar panels. A panel replaces core's sidebar sections, so each is a
#    named decision too. The key is read from the file's `key = "…"` or
#    PANEL_KEY constant.
while IFS= read -r file; do
  keys=$(grep -hoE '(PANEL_KEY = |key = )"[^"]+"' "$file" | sed -E 's/.*"([^"]+)"/\1/' | sort -u)
  if [ -z "$keys" ]; then
    report "Sidebar panel without a literal key" "$file"
  fi
  for key in $keys; do
    if ! printf '%s\n' "$ALLOWED_PANELS" | grep -qxF "$key"; then
      report "Sidebar panel \"$key\" is not on the allowlist in scripts/check-duplication.sh" "$file"
    fi
  done
done < <(grep -rlE 'addSidebarPanel\(' javascripts 2>/dev/null || true)

# 5. Replacing core components wholesale. A theme that swaps core's header or
#    list for its own is the duplicate by another route.
hits=$(grep -rnE 'modifyClass\(|reopen\(|registerValueTransformer\("(home-logo|header-)' javascripts 2>/dev/null \
  | grep -E 'component:(site-header|d-header|topic-list|sidebar)|home-logo|header-' || true)
if [ -n "$hits" ]; then
  report "Replacing a core layout component — restyle it instead" "$hits"
fi

if [ "$fail" -eq 0 ]; then
  printf '\033[32m✓ duplication check passed\033[0m — no HTML fields; every outlet and panel is allowlisted\n'
fi
exit "$fail"
