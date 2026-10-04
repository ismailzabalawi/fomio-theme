# 26 — What commit a060586 did

Commit `a060586` (2026-10-04) is the recent `apps/web` update. Its message
is the description:

> Replace apps/web with native-first Discourse theme rebuild.
>
> Archive the previous Sidebar-OS theme as apps/web-legacy and make monorepo
> apps/web the source of truth, imported from the fomio-web rebuild.

That commit imported this theme together with its docs. `00`–`25`,
`docs/README.md`, `CLAUDE.md`, and `README.md` are that record. This page
does not revise them. Where a session note and an earlier checklist differ,
the commit left both in place.

## Already written in that commit

| Place | What it says |
|---|---|
| `apps/web/README.md` | This directory is the live theme, imported from the rebuild. `apps/web-legacy/` is quarry only. The standalone `fomio-web` repo is not a write target |
| `apps/web/CLAUDE.md` | Read `docs/00-roadmap.md` first. Native-first rules. Do not extend `../web-legacy/` |
| [01 — Context](01-context-and-decisions.md) | History item 4: monorepo import on 2026-10-04. Monorepo `apps/web/` is the source of truth |
| `apps/web-legacy/ARCHIVE.md` | Previous theme is frozen. Do not extend it. Git pointer: branch `archive/apps-web-legacy` |
| `.cursor/rules/themerule.mdc`, `studio.mdc`, `fomio-context.mdc`, `designerrule.mdc` | Live theme is native-first `apps/web/`. `apps/web-beta` is gone. `apps/web-legacy/` is quarry only |
| `.cursor/skills/discourse-theme-developer/` | Same scope change |
| Root `CLAUDE.md` and `AGENTS.md` | Same scope change |

## What moved

Previous `apps/web` files were renamed into `apps/web-legacy/` (git saw them
as renames). The native-first tree was added in their place. New files that
are not renames include `apps/web-legacy/ARCHIVE.md`,
`apps/web-legacy/CLAUDE.md`, `apps/web-legacy/about.json`,
`apps/web-legacy/common/common.scss`, and `apps/web-legacy/locales/en.yml`.

## Scripts

`scripts/check-theme-sync.js` and `scripts/generate-web-colors.js` now read
`apps/web-legacy/`. Both files say the live theme has no `--fomio-*` token
pipeline. `npm run tokens:check` and `npm run tokens:fix` follow those
scripts, so they check the archived theme, not `apps/web/`.

## File that still contradicts the commit

`apps/web-legacy/CLAUDE.md` was carried over from the old guide. Its opening
still says all web theme work happens in `apps/web/` and describes the
Sidebar-OS shell, Hub/Teret/Byte copy, and `--fomio-*` tokens. Commit
`a060586` and `ARCHIVE.md` say that tree is frozen. A banner at the top of
that file points here. The body underneath is unchanged quarry notes. Paths
in it such as `apps/web/docs/responsive-design.md` now live under
`apps/web-legacy/docs/`.
