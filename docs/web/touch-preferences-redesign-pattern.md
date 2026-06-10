# Touch Preferences Redesign Pattern

**Status:** Implemented for `/u/:username/preferences/*` on touch surface (June 2026). Page-level flattening extended to all Me leaf screens — Activity, Notifications, Messages, Invites, Badges (June 2026). Extended to expanded / compact-desktop / rail surfaces (June 2026) — the flat treatment is now mode-independent.  
**Pattern:** One flat surface, no nested card chrome.  
**Future scope:** Extensible to other form/settings screens.

> **Scope note:** The pattern has two levels. **Page-level** flattening (plain
> canvas, flat stack header, no wrapper card, unboxed pill track) now applies
> to **every** Me leaf screen on **every surface mode**. **Group-level**
> flattening (no per-control-group boxes; hairline separators instead)
> applies only to form screens like preferences — list screens keep their
> item-level cards (stream items, notification rows, invite rows, badge
> cards) for row separation.
>
> The flat treatment is a property of the **detail surface**, not of the
> touch mode. What differs per surface mode is navigation chrome and
> density, never the page chrome: expanded / compact-desktop keep the
> persistent master pane beside the detail, rail collapses the master pane
> into an overlay (`fomio-master-pane-rail-open`), touch uses the Me stack
> header + bottom nav. This keeps surface transitions continuous per
> `surface-adaptation-model.md` — resizing across breakpoints only swaps
> navigation chrome around a visually stable page.

---

## Problem Statement

The touch account preferences page used triple-nested card chrome:

1. **Page canvas gradient** — decorative radial + linear gradient background
2. **`.new-user-content-wrapper` card** — bordered, rounded, gradient-filled container with drop shadow
3. **`#user-content` card** — duplicate bordered card inside the wrapper
4. **Per-control-group boxes** — each `.pref-group` / `.control-group` wrapped in its own bordered, rounded, tinted box with 10px gaps

This created a visually **noisy, compartmentalized surface** that conflicted with the "calm, reading-first, editorial spacing" principle in `CLAUDE.md`. The boxes ate horizontal space on 390px phones, and their presence forced consumers to scan nested visual hierarchies instead of focusing on form content.

## Solution: One Flat Surface

Remove all decorative card chrome and group via **spacing + hairline separators**, consistent with iOS Settings and modern form UX patterns.

### Before (4 nested levels)
```
┌─────────────────────────────────┐ Page gradient
│ ┌─────────────────────────────┐ │ .new-user-content-wrapper card
│ │ ┌───────────────────────────┐ │ │ #user-content card
│ │ │ ┌─────────────────────┐   │ │ │ .pref-group box
│ │ │ │ Username input      │   │ │ │
│ │ │ └─────────────────────┘   │ │ │
│ │ │                           │ │ │
│ │ │ ┌─────────────────────┐   │ │ │ .pref-group box
│ │ │ │ Email input         │   │ │ │
│ │ │ └─────────────────────┘   │ │ │
│ │ └───────────────────────────┘ │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

### After (1 flat surface)
```
┌─────────────────────────────────┐ Plain --fomio-bg
│                                 │
│  Username input                 │
│ ─────────────────────────────── │ Hairline separator
│                                 │
│  Email input                    │
│ ─────────────────────────────── │ Hairline separator
│                                 │
└─────────────────────────────────┘
```

---

## Implementation

### CSS Changes (Both Files Required)

The redesign lives in **two places** because the theme's stylesheet split is viewport-based, but Fomio's shell ownership is surface-based:

#### 1. `apps/web/common/common.scss`

In the `&.user-preferences-page` block (Phase 3C-N3), remove decorative styles from:

- `#main-outlet .user-main` — change from gradient background to plain `--fomio-bg`
- `#main-outlet .user-main .new-user-content-wrapper` — remove all border, radius, gradient, and shadow; padding becomes gutters only
- `#main-outlet .user-main #user-content.user-preferences` — no border, radius, gradient, shadow
- `#main-outlet .user-main #user-content.user-preferences .control-group` / `.pref-group` — no individual boxes

Replace with:

- `.control-group + .control-group` / `.pref-group + .pref-group` get `border-top: 1px solid color-mix(in oklab, var(--fomio-border-soft) 70%, transparent)` instead of bottom margin
- `padding: 14px 0` per group (vertical rhythm, not a box)
- Remove the group from the late "final mobile design pass" selector so its card chrome isn't re-asserted

#### 2. `apps/web/mobile/mobile.scss`

For `&.user-preferences-page` on touch (under `body.fomio-surface-touch.fomio-sidebar-active:not(.fomio-auth-mode)`):

- `.fomio-me-stack-header` — remove gradient, box-shadow, and blur; use flat background
- `.new-user-content-wrapper` — zero out all margin, remove border/radius/gradient/shadow
- `#user-content` — transparent background, no borders
- `.user-navigation-secondary ul.nav-pills` — no border, radius, background, shadow (pills themselves stay)
- `.control-group`, `.pref-group` — `padding: 16px 0`, no border/radius/background
- Adjacent groups separated by `border-top` hairline

**Critical:** The "final mobile design pass" block in `mobile.scss` must only assert **item-level** card language (stream items, notification rows, invite rows, badge cards). It must not re-assert page-level chrome (stack-header gradient, wrapper card) — that chrome has been removed for all Me leaf screens.

### Configuration Scoping

- **Touch:** the touch shell block in `common.scss` (`body.fomio-sidebar-active.fomio-surface-touch:not(.fomio-auth-mode)`) owns the page-level + group-level flattening; `mobile.scss` carries only narrow-width refinements
- **Expanded / compact-desktop / rail:** the shared Me-leaf rule in `common.scss` (`body.fomio-sidebar-active:not(.fomio-auth-mode):not(.fomio-surface-touch).user-*-page`) owns the page-level flattening (plain `--fomio-bg` canvas, no wrapper card); `desktop.scss` "Settings detail alignment" (Slice 6B) carries the group-level hairline treatment at desktop density plus master-pane column alignment
- **Landscape touch (e.g., folded foldables >768px in touch mode):** Covered by `common.scss` touch shell definition under `body.fomio-surface-touch`

This ensures the flat treatment survives landscape phones, landscape foldables, coarse-touch contexts wider than 767px, and desktop windows resized across the rail boundary.

### Per-mode division of responsibility

| Mode | Navigation chrome | Detail surface |
|------|------------------|----------------|
| expanded / compact-desktop | Persistent master pane beside detail | Flat, `--fomio-column-w` measure |
| rail | Master pane as overlay (`fomio-master-pane-rail-open`) | Flat, same rules as desktop (rail shares the Slice selectors) |
| touch | Me stack header + bottom nav | Flat, touch gutters and 44px targets |

---

## Key Principles

1. **No decorative containment** — let spacing and typography carry the hierarchy
2. **Keep control affordances** — inputs, selects, buttons keep their borders (functional, not decorative)
3. **Hairline separators** — use transparent color-mixed hairlines to separate logical groups without boxing
4. **Responsive by nature** — full viewport width means content reflows cleanly at any width without fixed card insets
5. **Read-first** — the page reads as one continuous surface, not a stack of containers

---

## Future Application

### Candidates for Group-Level Flattening (hairlines instead of boxes)

- `/u/:username/preferences/security` (sessions, 2FA, trusted devices)
- `/u/:username/preferences/notifications` (if future redesign moves away from pill-based filtering)
- Discourse `settings_` pages that need touch optimization

### Where Item-Level Cards Stay

Page-level chrome is flat everywhere on Me leaf screens, but these keep
their item cards:

- **Activity, Notifications, Messages (stream lists)** — cards visually separate list items
- **Discovery/hub/category pages** — reading-focused designs that group content into byte/topic cards
- **Badges, Invites (detail-heavy lists)** — cards segment table-like content

### Applying to New Screens

1. Remove `.new-user-content-wrapper` border/radius/gradient/shadow
2. Remove nested `#user-content` card treatment
3. Replace per-group boxes with:
   - `padding: 16px 0` per `.control-group` / form section
   - `border-top: 1px solid color-mix(in oklab, var(--fomio-border-soft) 70%, transparent)` between adjacent groups
4. Use plain `--fomio-bg` for the page canvas
5. Apply to **all surface modes**: the touch shell block in `common.scss` for touch, the shared non-touch Me-leaf rule in `common.scss` for page chrome, and `desktop.scss` for desktop-density group rules — never a touch-only redesign
6. Exclude the page from the "final mobile design pass" selector if it inherited card chrome rules

---

## Testing Checklist

- [ ] Inputs, selects, textareas have visible 44px touch targets
- [ ] Form groups are visually separated by hairline, not boxes
- [ ] Page reads as one flat surface (no nested card stacking)
- [ ] Responsive: verify at 375px (compact phone), 390px (regular phone), 768px (rail), 1024px (compact desktop), 1280px (expanded)
- [ ] Resizing across the 767/768px boundary swaps navigation chrome only — page chrome stays visually stable
- [ ] Dark mode: hairlines visible without being too strong
- [ ] Keyboard focus visible on inputs (browser default or styled)
- [ ] No Discourse class overrides leak through — all scoped under `fomio-` rules

---

## Related Docs

- `surface-adaptation-model.md` — spatial context and interaction density rules
- `me-navigation.md` — parent/child account screen structure (preferences is a child leaf)
- `apps/web/CLAUDE.md` — "calm, reading-first, editorial spacing" principle and responsive breakpoint rules

---

## Commit Reference

- **Branch:** `claude/account-prefs-ui-redesign-g28jt4`
- **Commit:** `18157f2` — "Flatten account preferences to one surface on touch"
- **Files:** `apps/web/common/common.scss` (lines 9161+), `apps/web/mobile/mobile.scss` (lines 444+)
- **Branch:** `claude/happy-gauss-xa2wl9` — page-level flattening extended to Activity, Notifications, Messages, Invites, Badges (same two files)
- **Branch:** `claude/serene-bardeen-bojnij` — flat treatment extended to expanded / compact-desktop / rail: shared Me-leaf page rule in `common.scss`, group-level hairlines replace boxed control groups in `desktop.scss` Slice 6B, messages canvas gradient removed
