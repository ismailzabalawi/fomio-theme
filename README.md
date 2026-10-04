# Fomio — web theme

The Discourse theme for Fomio's web surface. A Reddit alternative: many small
communities with one feed across them.

Lives in the Fomio monorepo at `apps/web/` (imported from the `fomio-web`
rebuild). The previous theme is archived at `apps/web-legacy/` — quarry only.

Backend is the existing `https://meta.fomio.app` (Discourse 2026.8.0).
This is a theme — not a fork, not a headless client.

## The one rule

**Discourse owns data, vocabulary and configuration. The theme owns layout and
behaviour.**

The previous web theme was rebuilt from scratch because mobile-app assumptions
got frozen into code as literals. Before writing any value here, find where
Discourse already holds it:

| Need | Lives in | Not in |
|---|---|---|
| Colours | `about.json` colour schemes → `var(--primary)` | hex in SCSS |
| Product words | Discourse translations and the existing site-text overrides | copied or hardcoded wording in theme code |
| Communities | the category tree | a list in code |
| Which feed tabs show | `top_menu` site setting | hardcoded nav |
| Feed ranking | `/hot` — core's gravity score | our own algorithm |
| Voting, karma, reactions, chat | core plugins, enabled by site setting | our own plugin |

Four scripts enforce the mechanical parts. Run them before pushing:

```bash
./scripts/check-native.sh     # no colour literals, no Hub/Teret/Byte in code
./scripts/check-variables.sh  # every custom property exists in core (R3)
./scripts/check-scss.sh       # compiles
./scripts/check-duplication.sh # no inserted headers/nav; outlets only from its allowlist
```

`check-variables.sh` reads a Discourse checkout (`DISCOURSE_SRC`, skipped if
absent). CSS fails silently on an unknown custom property, so a misspelled
variable looks exactly like a working one — this is the only check that sees it.
Keep the checkout on the same version as the server.

## Brand

The Fomio and Fomio AMOLED colour schemes ship in `about.json` as the theme's
defaults. They are defaults, not constants — an admin can edit them in
Admin → Customize → Colors, and every rule in this theme picks the change up
because nothing references a colour directly.

## Development

Iterate locally against an isolated (non-default) theme on the server:

```bash
cd apps/web
discourse_theme watch .
```

**Source of truth:** this monorepo path (`apps/web/`). Point Discourse at the
Fomio GitHub repo / theme path that serves this directory. The standalone
`fomio-web` repo is historical — do not keep it as an active write target.

Install / preview as a non-default theme via Admin → Customize → Themes until
ready. Previewing a non-default theme does not affect anyone else.

## Layout

```
about.json          colour schemes, theme metadata
common/             styles and templates for every surface
desktop/ mobile/    surface-specific overrides
javascripts/        api-initializers and components
locales/            theme-owned strings only
scripts/            the native-values guard
```

## State

Restarted 2026-09-26 — see `docs/00-roadmap.md`. Imported into the monorepo
as the live `apps/web` theme. The first rebuild pass remains on the external
repo's `archive/v0` branch; the monorepo's previous theme is `apps/web-legacy/`
(git branch `archive/apps-web-legacy`).
