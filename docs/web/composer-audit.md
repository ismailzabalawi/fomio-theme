# Fomio Composer — Production Audit

Audited against the design prototype in `fomio-design-system/project/Fomio Composer.html`.

## Feature Classification

| Feature | Status | Notes |
|---|---|---|
| Block rendering | **real** | Tracked array of `{id, type, content}` objects; rendered as styled textareas per block type |
| Slash menu | **real** | `/` in empty block opens menu; Heading / Quote / Divider insert real blocks; Poll / Collapsible / Image disabled with visual indicator |
| Floating toolbar | **real** | Appears on textarea selection; Bold / Italic / Link wrap selection in markdown syntax; wraps directly in the block's content |
| Drag handles | **disabled** | No drag-and-drop implementation; handles removed from production build |
| Insert buttons (+ in gutter) | **real** | `+` handle adds a new paragraph block below the current block |
| Source / rendered toggle | **real** | `sourceMode` shows the raw serialized markdown in a `<pre>` below the editor; blocks always contain markdown-compatible text |
| Word count | **real** | Computed from all block content lengths; updates on every change |
| Reading time | **real** | Derived from word count at 200 wpm |
| Outline rail | **real** | Extracts h2/h3 blocks from block array; clickable scroll-to (by block ID) |
| Publish checklist | **real** | Title set, Teret chosen checks are live state; image alt-text check is disabled (no image upload) |
| Status bar | **real** | Draft saved timestamp from Discourse model, word+char counts from block state, L col from active block index |
| Image block | **disabled** | Slot exists in slash menu but is visually disabled with "Coming soon" label; no fake upload |
| Onebox block | **partial** | Real block type; serializes as bare URL (Discourse renders it inline); no live fetch preview in editor |
| Edit diff | **disabled** | +/− counts in the edit-mode rail are removed; edit banner shows revision number only |
| Reply compact mode | **real** | Reply mode renders the parent Byte context card above the composer, then a focused reply card |

## Discourse-backed features (preserved as-is)

- **Publish / Save / Reply** — calls `this.composerService.save()`; no custom API call
- **Draft auto-save** — Discourse saves whenever `model.reply` changes; our sync handles this
- **Uploads** — not intercepted; Discourse upload UI is available via toolbar
- **Validation** — title length, body length, category required — all enforced by Discourse on `save()`
- **Permissions** — `can_edit`, `can_create_topic` checked by Discourse; theme checks `currentUser` for early gating only
- **Reply target** — `composer.model.post` preserved from the `composer.open` call
- **Edit target** — `composer.model.post` preserved from the `composer.open` call

## Markdown-backed (serialized and written to `model.reply`)

| Block type | Serialization |
|---|---|
| paragraph | plain text |
| h2 | `## text` |
| h3 | `### text` |
| quote | `> text` |
| divider | `---` |
| image | `![alt](url)` + optional caption line |
| onebox | bare URL on its own line |

## Unsafe for production (removed)

- Drag handles on blocks (no implementation; removed entirely)
- Fake "source" output (replaced with real serialized markdown)
- Fake word count (replaced with real computed count)
- Fake publish button (replaced with `composer.save()` call)
- Fake slash commands for Poll, Collapsible, Image (disabled with visual state)
- Edit diff visualization in the rail (+/− counts)
- Fake image upload preview
- Fake onebox live fetch
