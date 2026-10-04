# Composer — implementation handoff (v3, superseded by v4)

Companion to `06 Composer.dc.html` (review sequence, IA map, state matrix), `06.1 Composer Prototype.dc.html` (one interactive prototype with simulation controls) and `FmComposer3.dc.html` (shared product frame). v2 is preserved for comparison: `06 Composer v2.dc.html`, `06.1 Composer Prototype v2.dc.html`, `06 Composer handoff v2.md`, `FmComposer.dc.html`.

Evidence base: `uploads/09-composer-research.md` (E-refs), `uploads/10-composer-ia-map.md`, `uploads/composer-design-context.md`, `uploads/composer-network-observations.csv`, `uploads/about.json`. Discourse 2026.8.0-latest, commit 7b4f0970.

## 0. Boundary

The design reorganises the native composer. It does not replace it. Discourse's composer service and model, d-editor (rich text + Markdown), drafts and draft sequences, Uppy uploads, Onebox, poll, validation, reply/edit semantics, `POST /posts`, `PUT /posts/:id` and conditional `PUT /t/:id` stay authoritative. No block editor, drag handles, block conversion, new stored format, creation wizard, core patch or dependency on `registerRichEditorExtension` (experimental). Tags and AI stay out (disabled). Uploads are images only.

## 1. Hierarchy changes (v2 → v3)

1. **Top row:** Save and close (×), Minimize, draft status, primary action. On phone, the primary action is at the top right, where the keyboard can't cover it.
2. **Context:** destination as category path + audience (Public / Members only), inherited from the entry point. Reply shows compact reply-to context; edit shows author + topic and an optional reason.
3. **Content:** wrapping title, then the body. The persistent rich/Markdown switch is removed from the surface.
4. **One tool strip:** Photo / Format / More. It swaps in place for selections (Bold, Italic, Link), links (Edit link, Remove link) and photos (Alt text, Remove).
5. **Panels:** Format sits above the strip while the keyboard stays open. More takes the keyboard's slot. Photo goes straight to the system picker.
6. **Feedback:** similar topics as one collapsible, dismissible row under the title. Field errors under the field. Connection, rate-limit and conflict problems under the top row, next to the action. Upload failure on the image itself.
7. **Desktop:** same order docked to the 840px column. Same three entry points; draft status and action at bottom right. Preview (Markdown only) and fullscreen are on request.

## 2. Primary review sequence

| Moment | Frames | Prototype |
|---|---|---|
| 1 Open a new post | M1, C02, C03 | `#M1` |
| 2 Write, keyboard open | M2 (390, 360, AMOLED) | `#M2` |
| 3 Select and format | M3, C07, C06s, desktop M3 | `#M3` |
| 4 Add a photo, progress, retry | C06p, M4, M4b | `#M4`, `#M4b` |
| 5 Leave and restore | M5, M5b, C12b | `#M5`, `#M5b` |
| 6 Resolve submission errors | M6, M6b, C13b, C17 | `#M6`, `#M6b` |

Keyboard and panel rules on phone:

| Surface | Keyboard | Focus / selection |
|---|---|---|
| Format panel | Stays open | Buttons act on `pointerdown` with `preventDefault`, so focus and selection stay in the editor. The range is also stored and restored before each command. |
| Contextual strip | Stays open | Same slot, same height. |
| Link panel | Stays open | Focus moves to the URL field. OK/Cancel restores the stored range. |
| More | Hidden; More takes its slot | Range stored; Done or insertion restores it and refocuses the editor. |
| Photo | Hidden; system picker | Image placed at stored range. |
| Category, dialogs | Hidden | Modal; Esc / Cancel / Keep editing return. |

## 3. Interaction inventory by feasibility

(a) = verified theme/API seam in the research. (b) = feasibility prototype needed before committing. (c) = plugin needed. No item was established as (c).

| Changed interaction | Native source | Class | Notes |
|---|---|---|---|
| Layout, spacing, type, surfaces; destination and title on separate rows | `#reply-control`, composer classes, category chooser, `ComposerTitle` | (a) CSS | Keep DOM order; no CSS `order`. Wrapping title needs checking against core `<input>` (b if core stays an input). |
| Audience line (Public / Members only) | category `read_restricted` / permissions on chooser data | (b) | Chooser shows a lock for restricted categories; the line under the destination is new UI via `after-composer-category-input` outlet. Strings need keys. |
| Primary action at top right on phone | `ComposerSaveButton`, mobile `.submit-panel` | (b) | Moving the save button is CSS-positioning of native markup; confirm it stays in tab order and clears the keyboard on iOS/Android. |
| Draft status beside the action | composer save status | (a) CSS; outlet `composer-after-save-or-cancel` if relocation needs it | Offline and conflict must never read as saved. |
| Photo / Format / More strip replacing the icon row | d-editor toolbar; `api.onToolbarCreate`; `addComposerToolbarPopupMenuOption`; Options menu | (b) | Toolbar groups and popup options are supported seams (E19). A "Format" button that opens a secondary panel of existing buttons is custom UI on top of them; prove in both modes, with shortcuts intact. Do not claim arbitrary reordering is supported until tested. |
| Format panel coexisting with keyboard | d-editor commands | (b) | Depends on `pointerdown` preventDefault keeping the virtual keyboard up on iOS Safari and Android Chrome. Unverified on devices. |
| Contextual strip (selection / link / image) | editor selection state; rich editor link/image handling | (b) | Requires listening to selection in both the ProseMirror rich editor and the textarea without experimental node APIs. Image alt text: confirm what the native rich editor exposes before shipping Alt text. |
| More grouping: Build Poll, table, details, date, spoiler, preformatted | Options popup menu, plugins | (a) | Show only enabled plugins. Poll conditional on `poll_enabled`. |
| Markdown / Rich text under More › Editor | d-editor toggle; `composition_mode`; transformer `composer-force-editor-mode` | (b) | Relocating the native toggle into a menu is custom placement; persistence stays native (`PUT /u/:username.json`). Rich text as new-user default is a mockup choice, not a settings change. |
| Photo in one tap | Uppy upload button / file input | (a) | Same pipeline; images only. |
| Progress, Cancel, Retry on the image | Uppy events, `addComposerUploadPreProcessor` | (b) | Core shows upload errors as dialogs; inline retry next to the placeholder is new UI. |
| Similar topics row | `ComposerMessages`, transformer `composer-message-components` | (b) | Confirm contract; must not overlay preview. |
| Inline submission banners (offline, rate limit, conflict) | `addComposerSaveErrorCallback`, core dialogs | (b) | Keep core messages; placement is the proposal. |
| Close while offline keeps composer open | composer close + draft save | (b) | Needs proof that native close would otherwise lose unsaved text; if native already handles it, drop the custom block. |
| Minimize strip, Drafts › Resume, Discard confirm | composer `draft` state, user-menu Drafts, discard modal | (a) Native + CSS | — |
| Pending approval dialog + notice | `NewPostResultSerializer` enqueued | (a) Native | Never shown as published. |
| Desktop shortcuts Ctrl/⌘+B, I, K, Enter; Esc | d-editor keymap, composer service | (a) Native | Esc order in mockup: sheet → panel → minimize. |

Outlet allowlist: currently only `below-footer` and `category-heading`. Any composer outlet above must be added to `docs/03-implementation.md` and `scripts/check-duplication.sh` at implementation time.

## 4. Copy: observed, fixtures, proposed

**Observed 2026-09-28:** New Byte, Create topic, Type title, or paste a link here, Create Topic, Byte (reply action menu), Reply, Why are you editing?, Save Edit, Cancel edit, Save and close (aria), Minimize the composer panel (aria), Discard, Do you want to discard your post?, Markdown placeholder, Options.

**Core defaults shown, not observed (fixtures):** Markdown, Saving draft…, Draft saved, Edit conflict, Your topic is similar to…, Search categories, No matches found, Category, Uploading…, Cancel, Retry, Insert Hyperlink, Link text (optional), OK, Build Poll, Insert Poll, Insert table, Hide details, Insert date, Blur spoiler, Preformatted text, Overwrite Edits, Keep editing, Save draft for later, Post Needs Approval + body, You have 1 post pending., Log In, Sign Up, Unable to connect., Try Again, rate-limit message, Title is required, Title must be at least 15 characters, Post must be at least 20 characters, Poll must have at least 2 options., This topic is closed…, Drafts, Resume, Paragraph / Heading (rich editor block labels).

**Proposed UX copy, needs keys or site-text overrides before shipping:**

| Proposed | Where | Mapping needed |
|---|---|---|
| Photo | strip | new theme key, or override of the upload button label |
| Format | strip | new theme key |
| More | strip | override of `composer.options` ("Options") or new key; decide one |
| Bold, Italic, Bullets, Numbers, Quote, Link | Format panel visible labels | visible labels are new; aria stays core (`composer.bold_title` etc.) |
| Subheading | Format panel | new key, or use core heading level names |
| Public / Members only | destination audience line | new keys |
| Add edit reason | edit | new key; field placeholder stays "Why are you editing?" |
| Hide keyboard | strip (aria) | new key |
| Edit link / Remove link / Alt text / Remove / Describe the photo | contextual strip | new keys; confirm against rich editor strings |
| Writing in rich text / Writing in Markdown source / Finish or remove uploads first | More › Editor sub-lines | new keys, or drop |
| Upload failed / … was not added. | on the image | map to core upload error text if possible |
| Offline. Draft not saved; Not posted. Your writing is still here…; Draft not saved + close-offline body; conflict body; Not posted yet.; Wait for the photo to finish uploading. | status and banners | map to core strings where they exist; otherwise new keys |
| Do you want to discard your changes? | edit discard | unverified; confirm core wording |

## 5. Verified in the rendered prototype (browser simulation only)

Checked by scripted interaction with `06.1 Composer Prototype.dc.html` on 2026-09-29 (Chrome, 390 / 360 / 1280 frames):

- Selection "one more thing every morning" survived: closing Format, reopening Format, Bold (result `<b>…</b>`, Bold `aria-pressed=true`), Quote (`<blockquote>`). Simulated keyboard stayed shown throughout.
- Photo → picker → pick: upload figure placed after the paragraph, progress to completion, text kept. With "Fail once": failure shown in place with Retry; Retry succeeded; text kept.
- Rich → Markdown → Rich with mixed content: bold, image, list, quote and link present in Markdown source and restored as elements.
- Minimize → strip → resume, and Save and close → Drafts → Resume: title and body restored.
- Submit with short title/body: both errors shown beside their fields; focus moved to the title.
- Offline submit: "Unable to connect." banner, text kept, draft status Offline. Back online → Try Again → published topic page.
- Reply: primary label Reply, no title or category field. Approval result → Post Needs Approval dialog → OK → pending notice.
- Narrow 360: strip fits (Photo / Format / More + hide keyboard). In the text-selection strip, Format and More become icon-only with labels kept as aria-labels.
- AMOLED, desktop Markdown with preview column, RTL (phone and desktop) render with mirrored layout.

## 6. Simulated or unverified

- The keyboard is drawn. Real iOS/Android keyboard height, `visualViewport` resizing, safe areas, whether `pointerdown` preventDefault keeps the keyboard up, and native selection handles are **unverified**.
- The prototype uses a `contenteditable` stand-in and a small Markdown converter, not ProseMirror or d-editor. Round-trip results here say nothing about the production serializer.
- No network requests. Drafts, uploads, publishing, approval, conflict and rate limits are timers driven by the Simulate controls.
- Screen-reader output was not tested with VoiceOver/TalkBack. Live-region announcements and roles exist in markup only.
- Translated string lengths and real category names beyond the fixtures are untested.
- Browser-mockup testing does not prove Discourse integration.

## 7. Open decisions

1. Confirm the Format panel keeps the keyboard up on devices; if it does not, fall back to Format replacing the keyboard (same slot as More) with stored-range restore.
2. Decide whether "More" overrides the observed "Options" or gets a new key.
3. Validate the wrapping title against core markup.
4. Confirm rich-editor image actions before promising Alt text.
5. Emoji toolbar button: hide via toolbar config or keep under More (no-emoji UI rule).
6. Alternative B (Text/Image/Link/Poll aids) is retired by this brief; C18 guided form remains an optional follow-up (v2 6t).
