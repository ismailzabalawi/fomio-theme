# Fomio Composer — Production Audit (Current)

This audit reflects the active implementation in `apps/web`.

The composer is the native Discourse composer, restyled as a Fomio editorial surface and extended through supported theme APIs.

## Implementation Snapshot

| Area | Status | Notes |
|---|---|---|
| Publish pipeline | **native** | Uses core composer save flow; no custom posting API path |
| Draft behavior | **native** | Core draft autosave and restore remain intact |
| Uploads | **native** | Core upload behavior remains available |
| Validation and permissions | **native** | Title/body/category and permission checks remain core Discourse behavior |
| Editor mode | **customized** | Composer is forced to rich-editor mode |
| Placeholder | **customized** | Theme-level placeholder copy override |
| Formatting UX | **customized** | Floating selection toolbar (bold, italic, link) as lightweight DOM widget |
| Create/Edit shell | **customized** | Full-page open-canvas layout (continuous writing surface) with lightweight topbar, rail, and status bar |
| Reply shell | **customized** | Compact reply context card above native reply surface |
| Metrics | **customized** | Live words/chars/outline from ProseMirror extension -> tracked store |
| Outline navigation | **customized** | Rail headings are clickable and jump caret/focus to section |
| Active section | **customized** | Rail auto-highlights the heading nearest the current caret position |

## Active Components and Extensions

- `javascripts/discourse/api-initializers/fomio-rich-editor-toolbar.gjs`
  - Forces rich-editor mode
  - Overrides rich placeholder
  - Registers selection-toolbar extension
  - Registers metrics extension
  - Installs open-canvas focus behavior
- `javascripts/discourse/lib/fomio-selection-toolbar-extension.js`
  - Floating selection actions: bold, italic, link
- `javascripts/discourse/lib/fomio-composer-metrics-extension.js`
  - Extracts plain text + headings (+ heading positions) from editor transactions
  - Tracks live cursor position for active-outline highlighting
- `javascripts/discourse/lib/fomio-composer-metrics-store.js`
  - Reactive singleton consumed by connectors
  - Exposes outline jump navigation callback
- `javascripts/discourse/lib/fomio-composer-metrics.js`
  - Pure metric derivations (word/char/count/checks/progress)

## Connector Surface Coverage

- `before-composer-controls/fomio-composer-topbar.gjs`
  - Full-page Create/Edit topbar (back, mode, close)
- `before-composer-fields/fomio-fullscreen-composer-fields.gjs`
  - Re-adds title/category/tags in fullscreen
- `before-composer-fields/fomio-composer-edit-banner.gjs`
  - Edit-mode context banner
- `composer-after-composer-editor/fomio-composer-rail.gjs`
  - Draft metrics, clickable outline jump, active section highlight, checks
- `composer-fields-below/fomio-composer-statusbar.gjs`
  - Live words/chars + submit shortcut
- `composer-fields-below/fomio-composer-hints.gjs`
  - Keyboard-hint legend
- `composer-open/fomio-composer-reply-context.gjs`
  - Reply target context card

## Styling Coverage

- `common/common.scss`
  - Section 7: composer shell (native container restyle)
  - Section 7b: editorial connector styles
  - Open-canvas visual pass for Create/Edit (de-boxed writing flow)
  - Hides stock fixed rich toolbar in favor of floating toolbar
- `mobile/mobile.scss`
  - Touch/full-page spacing refinements
  - Submit-row and topbar touch layout adjustments

## Tests Present

- `tests/fomio-composer-metrics.test.js`
  - Pure metrics and checks behavior
- `tests/fomio-composer-canvas.test.js`
  - Canvas focus decision logic for full-page Create/Edit

## Explicitly Not In Scope (Current)

- Parallel custom block-editor engine
- Custom slash-menu block model and serializer
- Custom publish API pipeline
- Custom upload pipeline
- Markdown-mode parity work (current path is rich-editor only)
