# Activity List — DOM Audit (Phase 0)

Status: **Phase 0 complete** — signed off against live preview.  
Preview URL: `https://meta.fomio.app/?preview_theme_id=33`  
Audit date: 2026-06-24  
Profile used: **self** `@soma` (full tab set); **other** `@system` (stream tabs only).

## Locked decisions

| Item | Decision |
|------|----------|
| Stream format | **Timeline only** — flat hairline rows, 32×32 left icon column. `ActivityCards` deferred. |
| Tab rollout | **Phased:** M1 stream (All/Replies/Likes) → M2 Bytes → M3 self-only (Read/Drafts/Pending/Bookmarks) |
| Out of scope | Native secondary nav pills. List rows inside `#user-content` only. |

---

## Global findings (LIVE)

### 1. Connector outlet blocker — CONFIRMED

Discourse core has a **named-block spelling mismatch** that prevents the `user-stream-item-header` connector slot from rendering:

| Layer | Block name |
|-------|------------|
| `post-list/index.gjs:127` | `belowPostItemMetaData` |
| `post-list/item/index.gjs:172` | `belowPostItemMetadata` |

`UserStream` mounts `PluginOutlet @name="user-stream-item-header"` inside the `belowPostItemMetaData` yielded block (`user-stream.gjs:209–217`). Because the child never yields to the matching name, **no connector markup is emitted**.

**LIVE evidence** (`preview_theme_id=33`, all stream tabs on `/u/soma/activity*`):

- `.fomio-activity-action-label` count: **0** on All, Replies, Likes, Drafts
- Avatars remain visible (no `:has(.fomio-activity-action-label)` trigger)

**M1 outlet decision:** Move timeline leading icon + type label to **`user-stream-item-above`** (verified: `user-stream.gjs:203–207` yields `abovePostItemHeader` correctly). Retire or repurpose `connectors/user-stream-item-header/fomio-activity-action-label.gjs` — do not depend on `user-stream-item-header` until core fixes the block name.

### 2. Title vs metadata order — CONFIRMED

Native `.post-list-item__details` child order is **title first, metadata second**:

```
.stream-topic-title  →  .post-list-item__metadata
```

Prototype `ActivityTimeline` order is **meta → title → excerpt**. M1 must reorder with flex `order` or split markup in the connector.

### 3. SCSS authority when both body classes present — CONFIRMED

On live preview, `body` carries **both** `fomio-sidebar-active` and `fomio-activity-screen`.

| Selector stack | Computed on `.user-stream-item` (LIVE) |
|----------------|----------------------------------------|
| Editorial cards (`~5622`, `fomio-sidebar-active.user-activity-page`) | Would apply 24px radius, card padding |
| Flat timeline (`~25190`, `.fomio-activity-stream-list`) | **Wins** for stream rows: `border-radius: 0`, `padding: 16px 0`, hairline `border-bottom` |

**M1 action:** Narrow editorial card block to exclude `.fomio-activity-stream-list .user-stream-item` so flat timeline is authoritative even if specificity shifts.

### 4. Path helper mis-scoping — CONFIRMED (M2/M3 prep)

[`fomio-activity-paths.js`](../../javascripts/discourse/lib/fomio-activity-paths.js) `isFomioActivityTopicsPath()` includes `read` and `bookmarks`, so `fomio-activity-topics-cards.gjs` incorrectly adds `.fomio-activity-topics-list` and `--fomio-activity-topics-card` on Read and Bookmarks tabs (LIVE). Fix in M2/M3 when those tabs are styled — not Phase 0 code.

### 5. Read progress — native gap — CONFIRMED

Read tab uses `user-topics-list` → `tr.topic-list-item`. **No** `.read-progress` element in DOM. `.topic-post-badges` present but empty on audited rows. Prototype `N/M read` + progress bar requires M3 connector/CSS on top of topic stats or a documented native gap.

---

## Per-tab audit

Legend: **SOURCE** = from Discourse/theme source read-only. **LIVE** = confirmed on `meta.fomio.app?preview_theme_id=33`.

---

### Tab 1 — All (`/u/:user/activity`)

| Field | SOURCE | LIVE |
|-------|--------|------|
| Ember route | `userActivity.index` | ✓ |
| API | `GET /user_actions.json?filter=4,5` | ✓ |
| List root | `.post-list.user-stream` | `post-list user-stream fomio-activity-stream-list` |
| Filter class | `.filter-4-5` (when filtered) | (mixed stream — no filter class on All) |
| Body variant | `fomio-activity-screen--all` | ✓ |
| Item selector | `.post-list-item.user-stream-item` | ✓ DIV |
| Details child order | title → metadata | `stream-topic-title` → `post-list-item__metadata` |
| Leading element | `.avatar-link` | ✓ visible (48×48) |
| Action label connector | `user-stream-item-header` | **Absent** (0 nodes) |
| Excerpt | `.excerpt > .cooked` | ✓ |
| Secondary lines | `PostActionDescription`, `.user-stream-item-actions` | Not on first audited row |
| Expand control | `ExpandPost` in header | Present (collapsed) |
| Load more | inside `#user-content` via `LoadMore` | ✓ (not visible until scroll end) |
| Empty state | `.empty-state` | N/A (has rows) |

**Outlets (verified in `discourse/`):**

| Outlet | Renders LIVE | Notes |
|--------|--------------|-------|
| `user-stream-item-above` | Empty (`<!---->`) | **M1 target** for leading icon |
| `user-stream-item-header` | Never (block mismatch) | Current connector file unused |

---

### Tab 2 — Replies (`/activity/replies`)

| Field | SOURCE | LIVE |
|-------|--------|------|
| Route | `userActivity.replies` | ✓ |
| API filter | `5` | ✓ |
| List root | `.post-list.user-stream.filter-5` | `post-list user-stream filter-5 fomio-activity-stream-list` |
| Body variant | `fomio-activity-screen--replies` | ✓ |
| Details order | title → metadata | ✓ same as All |
| Action labels | — | 0 |
| Row pattern | Same as All | ✓ |

---

### Tab 3 — Likes given (`/activity/likes-given`)

| Field | SOURCE | LIVE |
|-------|--------|------|
| Route | `userActivity.likesGiven` | ✓ |
| API filter | `1` | ✓ |
| List root | `.filter-1` | `post-list user-stream filter-1 fomio-activity-stream-list` |
| Body variant | `fomio-activity-screen--likes-given` | ✓ |
| Details order | title → metadata | ✓ |
| Action labels | — | 0 |
| Acting user / children | `.user-stream-item-actions` above excerpt | Verify per-row on M1 |

---

### Tab 4 — Bytes (`/activity/topics`) — M2

| Field | SOURCE | LIVE |
|-------|--------|------|
| Route | `userActivity.topics` | ✓ |
| Template | `user-topics-list` → `BasicTopicList` | ✓ |
| List root | `table.topic-list` | `topic-list fomio-activity-topics-list` |
| Item | `tr.topic-list-item` | `topic-list-item … --fomio-activity-topics-card` |
| Body variant | `fomio-activity-screen--topics` | ✓ |
| Title | `.link-top-line a.title` | ✓ |
| Teret | `.link-bottom-line .badge-category` | ✓ |
| Excerpt | `.topic-excerpt` | Not on first row |
| Stats cells | `td.posts`, `td.activity` | ✓ |
| Leading icon | none native | M2: inject via outlet |

**Verified outlets** (`topic-list/item.gjs`): `above-topic-list-item`, `topic-list-before-link`, `topic-list-main-link-bottom`, `topic-list-after-main-link`.

---

### Tab 5 — Read (`/activity/read`) — M3, self-only

| Field | SOURCE | LIVE |
|-------|--------|------|
| Route | `userActivity.read` | ✓ |
| Template | `user-topics-list`, filter `read` | ✓ |
| List root | `table.topic-list` | `topic-list fomio-activity-topics-list` ⚠ mis-tagged |
| Item | `tr.topic-list-item` | ✓ |
| Body variant | `fomio-activity-screen--read` | ✓ |
| Read progress markup | unknown | **No** `.read-progress` — **native gap** |
| Topic badges | `.topic-post-badges` | Present, empty on sample row |

---

### Tab 6 — Drafts (`/activity/drafts`) — M3, self-only

| Field | SOURCE | LIVE |
|-------|--------|------|
| Route | `userActivity.drafts` | ✓ |
| Template | `user/stream` → `UserStream` | ✓ |
| List root | `.user-stream` + bulk select | `post-list post-list--bulk-select user-stream fomio-activity-stream-list` |
| Body variant | `fomio-activity-screen--drafts` | ✓ |
| Leading (SOURCE) | `.draft-icon` when `isDraft` | **Avatar shown** on sample row (draft detection uses constructor name) |
| Draft actions | `.user-stream-item-draft-actions` | ✓ |
| Action labels | — | 0 |
| Outlets | Same as stream | `user-stream-item-above` empty |

---

### Tab 7 — Pending (`/activity/pending`) — M3, self-only

| Field | SOURCE | LIVE |
|-------|--------|------|
| Route | `userActivity.pending` | ✓ |
| Template | [`pending.gjs`](../../../discourse/frontend/discourse/app/templates/user-activity/pending.gjs) — `PostList` **without** `UserStream` | ✓ |
| List root | `ul.user-stream` > `PostList` | `ul.user-stream` > `.user-stream.fomio-activity-stream-list` |
| Body variant | `fomio-activity-screen--pending` | ✓ |
| Stream outlets | **None** — no `UserStream` wrapper | ✓ confirmed |
| Sample data | — | Empty: "There are no posts" |
| M3 plan | Leading icon via SCSS or new connector on `abovePostItemHeader` only if `UserStream` added | Pending |

---

### Tab 8 — Bookmarks (`/activity/bookmarks`) — M3, self-only

| Field | SOURCE | LIVE |
|-------|--------|------|
| Route | `userActivity.bookmarks` | ✓ |
| Template | `user/bookmarks` → `BookmarkList` | ✓ |
| Extra body class | `user-activity-bookmarks-page` | ✓ |
| List root | `table.topic-list.bookmark-list` | `topic-list bookmark-list fomio-bookmark-table fomio-activity-topics-list` ⚠ |
| Item | `tr.bookmark-list-item` | `topic-list-item bookmark-list-item excerpt-expanded --fomio-activity-topics-card` |
| Body variant | `fomio-activity-screen--bookmarks` | ✓ |
| Search | `#bookmark-search` | ✓ |
| Row title | `.bookmark-status-with-link a.title` | ✓ |
| Teret | `.link-bottom-line` | ✓ |
| Excerpt | `.post-excerpt` | ✓ |
| Reminder chip | `.bookmark-reminder` | Not on sample row |
| Outlets | `above-user-bookmarks`, `bookmark-list-before-link` | Verify on M3 |

---

### Other-user spot check (`/u/system/activity?preview_theme_id=33`)

| Check | LIVE |
|-------|------|
| Visible pills | All, Bytes, Replies, Likes, Bookmarks (+ plugin: Solved, Votes) |
| Hidden self-only | Read, Drafts, Pending — **not** in pill list ✓ |
| Stream rows | Same DOM pattern as self |
| Action labels | 0 |

---

## M1 timeline row spec (finalized from audit)

Target: match prototype `ActivityTimeline` on **All / Replies / Likes** only.

### Row grid (`.post-list-item.user-stream-item` under `.fomio-activity-stream-list`)

```scss
/* Conceptual — implement in M1 */
grid-template-columns: 32px minmax(0, 1fr) auto;
grid-template-rows: auto auto auto;
column-gap: 14px;
row-gap: 0;
padding: 16px 0;
border-bottom: 1px solid var(--fomio-activity-hairline);
```

| Grid area | Content | Source |
|-----------|---------|--------|
| Col 1, rows 1–3 | `.fomio-activity-timeline-leading` (32×32 icon pill) | **New connector** at `user-stream-item-above` |
| Col 2, row 1 | Meta row: type label · teret · time | Connector label + native `.post-list-item__metadata` (reordered) |
| Col 2, row 2 | Title (Lora 16/700) | `.stream-topic-title .title a` |
| Col 2, row 3 | Excerpt (2-line clamp) | `.excerpt .cooked` |
| Col 3 | Expand affordance | Native `ExpandPost` |

### Meta / title reorder

Inside `.post-list-item__details`:

```scss
.post-list-item__metadata { order: 1; }      /* meta row */
.fomio-activity-timeline-type-label { order: 1; } /* inline with meta via flex */
.stream-topic-title { order: 2; }           /* title */
```

Meta row layout: `display: flex; align-items: center; gap: 8px;` — time gets `margin-left: auto`.

### Leading icon connector (`user-stream-item-above`)

Refactor [`fomio-activity-action-label.gjs`](../../javascripts/discourse/connectors/user-stream-item-header/fomio-activity-action-label.gjs) → new file under `connectors/user-stream-item-above/`:

```html
<div class="fomio-activity-timeline-leading" data-fomio-activity-action="created_byte|replied|liked">
  <span class="fomio-activity-timeline-leading__icon">…Phosphor…</span>
</div>
<span class="fomio-activity-timeline-type-label">Created a Byte</span>
```

- Type label duplicated for meta row (visible text for a11y) or positioned into metadata row via CSS grid on parent.
- Icon map: `action_type` 4 → note-pencil + primary-soft; 5,6,7,9 → arrow-bend-up-left + surface; 1,2 → heart + surface.
- Locale keys: `activity_screen.actions.*` (existing).

### Avatar hide rule

```scss
.fomio-activity-stream-list .user-stream-item:has(.fomio-activity-timeline-leading) .avatar-link {
  display: none;
}
```

Replace current `:has(.fomio-activity-action-label)` selector.

### Tokens (on `body.fomio-activity-screen`)

| Token | Value |
|-------|-------|
| `--fomio-activity-row-pad-y` | `16px` |
| `--fomio-activity-row-gap` | `14px` |
| `--fomio-activity-icon-size` | `32px` |
| `--fomio-activity-icon-radius` | `8px` |
| `--fomio-activity-hairline` | existing |

### Excerpt

- Font: Lora 14px / 1.55, muted
- Clamp: **2 lines** (`-webkit-line-clamp: 2`) — replace current `max-height: 4.75em`

### Secondary lines (M1 scope)

| Type | Native source | M1 |
|------|---------------|-----|
| Reply-to | `PostActionDescription` / `action_code` | Style existing; do not duplicate |
| Like “by actor” | `.user-stream-item-actions` / `acting_username` | Style on Likes tab rows |
| Byte stats | Not in stream serializer on All | **Out of M1** unless native exposes counts |

### Expand affordance

Keep native `ExpandPost` chevron in column 3. Style as quiet control; row body remains primary tap target to byte.

### SCSS unification (M1)

1. Add exclusion to editorial card block (~5622):  
   `.fomio-activity-stream-list .user-stream-item { /* reset card chrome */ }`
2. Keep flat rules under `body.fomio-activity-screen` (~25006) as canonical for stream rows.

---

## Phase 0 exit checklist

| Criterion | Status |
|-----------|--------|
| Audit doc exists | ✓ this file |
| All 8 tabs documented | ✓ |
| LIVE sign-off (`preview_theme_id=33`) | ✓ 2026-06-24 |
| Connector outlet path confirmed | ✓ use `user-stream-item-above` |
| SCSS conflict documented | ✓ flat wins; M1 narrows editorial |
| M1 spec finalized | ✓ above |
| Native gaps flagged | ✓ read progress; pending outlets; path helper mis-scope |

**Phase 0 gate: PASS — M1 may begin.**

---

## M0 — Meta-row merge spike (2026-06-24)

**Method:** Evaluated three candidates from the M1 plan against live DOM structure on `/u/soma/activity` (preview_theme_id=33) and prototype `ActivityTimeline` markup.

| ID | Technique | Verdict |
|----|-----------|---------|
| A | `didInsert` prepends `.fomio-activity-timeline-type-label` into `.post-list-item__metadata` | **Selected** |
| B | `display: contents` on header/details + CSS grid only | Rejected — expand control and bulk-select edge cases on shared stream markup |
| C | `data-fomio-activity-label` + `::before` on metadata | Rejected — pseudo-content is weaker for screen readers and harder to localize |

**Approach A rationale:** Native teret (`.badge-category`) and time (`.time`) already live in metadata; prepending the type label yields a single flex row (`label · teret · time`) with `margin-left: auto` on time. Idempotent guard via `data-fomio-timeline-meta-bound` on the row prevents duplicate bindings on infinite scroll. Leading icon stays in `user-stream-item-above` connector; prefix wrapper uses `display: contents` so the icon participates in the row grid without extra columns.

**Spike exit criteria:** Met in implementation — meta row order, title below meta (flex `order`), icon column full height, avatar hidden via `:has(.fomio-activity-timeline-leading)`, expand in col 3.

---

## M1 — Implementation sign-off (2026-06-24)

**Scope delivered:** All / Replies / Likes Given stream tabs only (`isFomioActivityM1TimelineRoute`). Secondary nav pills unchanged. Drafts / Bytes / Read / Bookmarks / plugin tabs unchanged.

### Files changed

| File | Change |
|------|--------|
| `connectors/user-stream-item-above/fomio-activity-timeline-row.gjs` | **Created** — leading icon + type label; route-gated |
| `connectors/user-stream-item-header/fomio-activity-action-label.gjs` | **Removed** — broken outlet (core block-name mismatch) |
| `lib/fomio-activity-timeline.js` | **Created** — action maps + `bindTimelineTypeLabelToMetadata()` |
| `lib/fomio-activity-paths.js` | **Added** `isFomioActivityM1TimelineRoute()` |
| `common/common.scss` | Timeline row grid, meta/title reorder, 2-line excerpt clamp, teret pill, editorial card exclusion |
| `mobile/mobile.scss` | Touch icon 28px via CSS vars; timeline class selectors |
| `tests/fomio-activity-timeline.test.js` | **Created** |
| `tests/fomio-mobile-nav-paths.test.js` | M1 route gating tests |

### Automated checks (local)

| Check | Result |
|-------|--------|
| `node --test apps/web/tests/fomio-activity-timeline.test.js` | PASS (4 tests) |
| `node --test apps/web/tests/fomio-mobile-nav-paths.test.js` | PASS (M1 route gating included) |
| `npm run tokens:check` | PASS |
| `npm run check:terminology --workspace=apps/mobile` | Pre-existing repo violations (63); no new M1 user-facing strings |

### Post-deploy QA matrix (`preview_theme_id=33`)

Run after theme sync to meta.fomio.app:

| Check | All | Replies | Likes | @system |
|-------|-----|---------|-------|---------|
| `.fomio-activity-timeline-leading` count > 0 | ☐ | ☐ | ☐ | ☐ |
| Avatars hidden | ☐ | ☐ | ☐ | ☐ |
| Meta: label · teret · time | ☐ | ☐ | ☐ | ☐ |
| Title below meta | ☐ | ☐ | ☐ | ☐ |
| Icon tone by action_type | ☐ | reply only | like only | ☐ |
| Excerpt 2-line clamp | ☐ | ☐ | ☐ | — |
| LoadMore at scroll end | ☐ | ☐ | ☐ | — |
| Tab bar unchanged | ☐ | ☐ | ☐ | ☐ |
| Drafts tab — no timeline connector | ☐ | — | — | — |

**Surfaces:** expanded (1280+), rail (768–1023), touch (<768), light + AMOLED dark.

**M1 code gate: PASS — pending live preview sign-off after theme deploy.**

