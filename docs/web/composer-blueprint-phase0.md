# Fomio Composer Blueprint — Phase 0 Freeze

This document freezes the visual target and mapping contract before implementation work.

Scope: `apps/web` composer Create/Edit/Reply surfaces using native Discourse composer behavior.

## 1) Frozen Reference States

Use these as canonical comparison states for all subsequent phases:

1. **Create (desktop)**  
   Source: `Fomio Composer.html` + `composer.css` (`cm-topbar`, `cm-create-page`, title + teret row, body canvas, submit row)
2. **Create (mobile/touch)**
   Source: `Fomio Composer.html` + `composer.css` (`viewport-mobile` behavior and bottom action treatment)
3. **Edit (desktop)**
   Source: `Fomio Composer.html` + `composer.css` (`cm-edit-banner` + create shell reuse)
4. **Reply (desktop)**
   Source: `Fomio Composer.html` + `composer.css` (`cm-byte-context` + `cm-reply-card`)

Reference archive: `/Users/ismailzabalawi/Downloads/Fomio Design System.zip`

## 2) Architecture Guardrails (Non-Negotiable)

- Keep native Discourse composer pipeline (`save`, drafts, uploads, validation, permissions).
- No parallel custom editor runtime (`cm-*` DOM) inside theme.
- Implement visual parity via:
  - `apps/web/common/common.scss`
  - `apps/web/mobile/mobile.scss`
  - existing composer connectors and rich-editor extensions
- Reply remains compact/contextual; no forced full-page redesign.

## 3) Token Mapping (Zip -> Current Theme Tokens)

Use existing theme tokens only; do not import zip variable names into production styles.

| Zip intent | Zip var | Theme var to use |
|---|---|---|
| Page/background | `--fomio-bg` | `--fomio-bg` |
| Primary text | `--fomio-fg` | `--fomio-text` |
| Secondary text | `--fomio-fg-secondary` | `--fomio-secondary` |
| Muted text | `--fomio-fg-muted` | `--fomio-muted` |
| Accent | `--fomio-primary` | `--fomio-primary` |
| Accent soft bg | `--fomio-primary-soft` | `--fomio-primary-soft` |
| Surface/card | `--fomio-surface`, `--fomio-card` | `--fomio-surface`, `--fomio-card` |
| Border | `--fomio-border`, `--fomio-border-soft` | `--fomio-border`, `--fomio-border-soft` |
| Serif body/title | `--fomio-serif` | `--fomio-font-serif` |
| UI label sans | `--fomio-sans` | `--fomio-font-ui` |
| Mono utility | `--fomio-mono` | `--fomio-font-mono` |

## 4) Selector Mapping (Zip -> Discourse Theme)

| Blueprint selector | Purpose | Production selector/owner |
|---|---|---|
| `.cm-topbar` | sticky mode bar | `#reply-control .reply-to` + `.fomio-composer-topbar` connector |
| `.cm-create-page` | create shell width/padding | `#reply-control.composer-action-* .d-editor` + `.submit-panel` |
| `.cm-title-input` | editorial title | `#reply-title`, `.title-input input` |
| `.cm-teret-trigger` | teret picker control | `.category-input .select-kit-header` |
| `.cm-tags-row` | tags row/chips | `.tags-input .select-kit-header` (native chooser) |
| `.cm-body-content` | body typography | `.d-editor-input` rich-editor typography rules |
| `.cm-rail` | draft/outline/checks | `.fomio-composer-rail` connector |
| `.cm-status-bar` | utility status row | `.fomio-composer-statusbar` connector |
| `.cm-edit-banner` | edit context | `.fomio-composer-edit-banner` connector |
| `.cm-byte-context`, `.cm-reply-card` | reply context card/shell | `.fomio-composer-byte-context` + native reply surface |

## 5) Pixel/Parity Acceptance Tolerances

Use these to decide if a phase is “done”:

- **Layout spacing:** +/- 4px from frozen reference
- **Typography size:** +/- 1px from frozen reference
- **Title/editor measure:** +/- 16px max width drift allowed
- **Corner radius parity:** same token family (no arbitrary new radii)
- **Contrast hierarchy:** body > title metadata > utility chrome
- **Mode isolation:** Create/Edit changes must not alter Reply structure

## 6) Phase 0 Exit Checklist

- [x] Canonical reference states frozen
- [x] Non-negotiable architecture constraints documented
- [x] Token mapping fixed (no parallel vars policy)
- [x] Zip-to-production selector mapping completed
- [x] Visual parity tolerances agreed and measurable

## 7) Implementation Starting Point

Start Phase 1 in:

- `apps/web/common/common.scss` (primary)
- `apps/web/mobile/mobile.scss` (touch parity pass)

Keep connector JS unchanged unless a layout hook is impossible in CSS alone.
