# Fomio Web Theme — Claude Guide

Discourse theme for `apps/web` (stable) and `apps/web-beta` (beta). Same product as the mobile app — same product language, same quality standards, different surface.

## Product Constitution (Highest Authority)

`apps/mobile/docs/00-product/product-ui-rules.md` governs all UI and copy decisions.
Terminology is non-negotiable across all surfaces:

| Use | Never use |
|-----|-----------|
| Hub | Category, Section, Group |
| Teret | Subcategory, Channel, Thread |
| Byte | Post, Article, Topic, Entry |

## Skills

| Skill | Triggers |
|-------|---------|
| `discourse-theme-developer` | `/outlet`, `/transformer`, `/connector`, `/scss`, `/theme` |
| `discourse-archeologist` | `/trace`, `/schema`, `/serialize` — when you need to understand what the Discourse API returns |

## Stack

- **Components:** GJS (`.gjs`) only — no legacy widgets, no `.hbs`
- **Entry points:** `apiInitializer` from `discourse/lib/api`
- **Settings:** `settings.yml` → `import { settings } from "virtual:theme"`
- **i18n:** `locales/en.yml` → `i18n(themePrefix("key"))` — never inline strings
- **Styling:** SCSS with `fomio-` class prefix, `--d-*` Discourse variables for color
- **Source of truth for Discourse internals:** `discourse/` at repo root — read-only

## Two-Theme Workflow

- `apps/web-beta/` — all new work lands here first
- `apps/web/` — promoted from beta after critique + quality audit pass
- Keep both structurally in sync

## Rules

- **Always verify outlets** before using: `rg '<PluginOutlet @name="name"' discourse/app`
- **Always verify transformers** before using: `rg 'applyValueTransformer.*"key"' discourse/app`
- **Transformers before workarounds:** transformer → connector → `onPageChange` → DOM (last resort)
- **All CSS scoped** under `fomio-` prefix — no bare Discourse class overrides
- **No fetch calls** in theme JS — themes are UI-only
- **No hardcoded deep links** — always use `fomio_app_url` setting
- **No forbidden terminology** in `locales/en.yml` or any component copy

## Studio Protocols

All four protocols apply — see "Web Theme Adaptations" in `.cursor/rules/studio.mdc`:

- **Critique** (3 passes, web-adapted) before any connector or component ships
- **Exploration Mode** (3 directions) when no existing pattern fits
- **Quality Audit** (6 passes) pre-release and when something feels off
- **DS Evolution** (DSP required) before any new reusable component

## File Structure

```
apps/web/
├── about.json              # Metadata + "Ink & Paper" color scheme
├── settings.yml            # Settings — all keys fomio_*
├── locales/en.yml          # Strings — all via themePrefix()
├── common/common.scss      # --fomio-* design tokens + shared styles
├── desktop/desktop.scss    # Desktop-only
├── mobile/mobile.scss      # Mobile browser only
└── javascripts/discourse/
    ├── api-initializers/   # apiInitializer entry points
    ├── components/         # Glimmer GJS components (FomioMyComponent)
    └── connectors/
        └── <outlet>/<fomio-name>.gjs
```

## Design Token Sync

`--fomio-*` tokens in `common/common.scss` must stay aligned with mobile's visual language. When typography or brand colors change in `apps/mobile/src/theme/tokens.ts`, evaluate whether the web theme tokens need updating too.

Run the sync check: `node scripts/check-token-sync.js`

## Docs

`apps/web/docs/README.md` — theme-specific documentation home.
