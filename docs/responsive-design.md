# Fomio Web — Responsive Design Reference

Read this before writing any CSS that targets a specific screen size, surface mode, or device type. It covers how Discourse delivers stylesheets, how Fomio's surface model maps to CSS, which file to put styles in, and the patterns to use.

---

## 1. How Discourse Delivers CSS

Discourse splits stylesheet delivery in two dimensions:

### UA-Based Bundle Split (server-side)

Discourse serves three stylesheet folders based on user-agent:

| Folder | When applied |
|--------|-------------|
| `common/` | Always — every page, every device |
| `desktop/` | Non-mobile user agents |
| `mobile/` | Mobile user agents |

The UA classification uses `site.mobileView`, which Discourse defines as **viewport width < 640px** (or forced mobile mode). This is not the same as "is a phone" — a phone in landscape at 768px gets the desktop bundle.

**Implication:** `mobile/mobile.scss` is applied to narrow windows only. It is not a reliable proxy for touch devices, foldables, or landscape phones. Surface-mode classes in `common/` are the correct layer for touch-specific behavior.

### Discourse's Viewport Breakpoints

Discourse's own system (used in Discourse core SCSS):

```scss
// discourse/app/assets/stylesheets/lib/viewport.scss
$breakpoints: (
  sm:  40rem,   // 640px — Discourse "mobile" threshold
  md:  48rem,   // 768px
  lg:  64rem,   // 1024px
  xl:  80rem,   // 1280px
  2xl: 96rem,   // 1536px
);

// Mixins:
@include viewport.from(md)  { ... }  // width >= 768px
@include viewport.until(md) { ... }  // width <  768px
```

Discourse core uses **rem units** so breakpoints respect the user's root font-size. These are available in Discourse core CSS but not directly importable in theme SCSS. Use pixel equivalents in theme code.

### Body and HTML Classes Set by Discourse

Discourse adds these to the document automatically — use them in selectors:

| Class | When set |
|-------|----------|
| `html.mobile-view`, `body.mobile-view` | Viewport < 640px (Discourse mobile bundle active) |
| `html.desktop-view`, `body.desktop-view` | Viewport ≥ 640px |
| `body.has-sidebar-page` | Discourse built-in sidebar is active |
| `html.keyboard-visible` | Soft keyboard is open (touch) |
| `body.ios-device` | iOS UA detected |

---

## 2. Fomio's Surface Model

Fomio overlays its own surface classification on top of Discourse's UA split. This is the **authoritative layer for layout decisions**. Never use raw breakpoints as a substitute for surface-mode scoping.

### Surface Modes

```ts
type SurfaceMode = "expanded" | "compact-desktop" | "rail" | "touch";
```

| Mode | Viewport | Body class | Shell behavior |
|------|----------|------------|----------------|
| `expanded` | ≥ 1280px | `body.fomio-surface-expanded` | Full sidebar with labels |
| `compact-desktop` | 1024–1279px | `body.fomio-surface-compact-desktop` | Narrower sidebar |
| `rail` | 768–1023px | `body.fomio-surface-rail` | Icon-only sidebar rail |
| `touch` | < 768px (or coarse pointer) | `body.fomio-surface-touch` | Bottom navigation, no sidebar |

These classes are applied by `fomio-layout.gjs`. They are set on `body` before paint.

### Additional Fomio Body Classes

| Class | Meaning |
|-------|---------|
| `body.fomio-sidebar-active` | Fomio sidebar is mounted (non-touch modes) |
| `body.fomio-auth-mode` | Auth page — sidebar and shell chrome are suppressed |
| `html.fomio-color-dark` | Dark mode active (set by `fomio-color-mode.gjs`) |
| `body.fomio-surface-ready` | Surface resolver has completed its first classification |

---

## 3. Which File to Put Styles In

This is the single most important decision. Get it wrong and styles break on foldables and landscape phones.

### Decision Tree

```
Is this style correct on every surface?
  → common/common.scss

Does this style only apply to touch-interaction contexts
(bottom nav, swipe behavior, thumb targets, safe areas)?
  → common/common.scss, scoped to body.fomio-surface-touch
  NOT mobile/mobile.scss alone

Does this style apply at narrow widths regardless of touch/pointer mode?
(e.g. tighter spacing when the viewport is small)
  → mobile/mobile.scss (and/or common.scss with an @media query)

Does this style apply only on desktop/expanded surfaces?
(e.g. sidebar layout, hover states, wide reading column)
  → desktop/desktop.scss

Does this style apply to a specific surface mode?
  → common/common.scss, scoped to the surface body class
```

### The Common Mistake

**Wrong:**
```scss
// mobile/mobile.scss
body.fomio-sidebar-active { ... }  // WON'T fire on a wide phone or foldable
```

**Right:**
```scss
// common/common.scss
body.fomio-surface-touch.fomio-sidebar-active { ... }  // fires on any touch context
```

`mobile/mobile.scss` is applied based on viewport width < 640px. A phone in landscape at 768px will never receive it. A foldable unfolded to 900px will never receive it. The touch surface class is the right boundary.

---

## 4. SCSS Patterns

### Surface-Mode Scoping (preferred)

```scss
// Expanded sidebar — common.scss
body.fomio-sidebar-active.fomio-surface-expanded:not(.fomio-auth-mode) {
  .fomio-sidebar { width: var(--fomio-sidebar-width); }
}

// Rail — common.scss
body.fomio-sidebar-active.fomio-surface-rail:not(.fomio-auth-mode) {
  .fomio-sidebar { width: var(--fomio-sidebar-rail-width); }
}

// Touch — common.scss
body.fomio-surface-touch {
  .fomio-sidebar { display: none; }
}
```

### Raw Media Queries (use when surface class isn't specific enough)

Use pixel values that align with surface boundaries:

```scss
// Tablet mid-range within desktop.scss
@media (min-width: 768px) and (max-width: 1099px) { ... }

// Wide desktop only
@media (min-width: 1280px) { ... }

// Narrow-viewport refinement in mobile.scss or common.scss
@media (max-width: 767px) { ... }
```

**Never mix raw media queries and surface-mode classes** for the same behavior — pick one authority per rule.

### Dark Mode

```scss
// Light only (default)
.fomio-card { background: var(--fomio-card); }

// Dark override
html.fomio-color-dark .fomio-card { ... }
```

### Safe Area Insets

Define custom properties on the touch shell, then consume them in components. Do not scatter raw `env()` calls across pages.

```scss
// common.scss — define once on the shell
body.fomio-surface-touch {
  --fomio-safe-top:    env(safe-area-inset-top, 0px);
  --fomio-safe-bottom: env(safe-area-inset-bottom, 0px);
}

// Consume anywhere
.fomio-bottom-bar {
  padding-bottom: calc(var(--fomio-safe-bottom, 0px) + 0.5rem);
}
```

### Fluid Typography (use `clamp`)

```scss
// Scales between a floor and ceiling across the viewport
font-size: clamp(1.15rem, 5.8vw, 1.55rem);

// Preferred over fixed sizes at specific breakpoints for body text and titles
```

---

## 5. Breakpoint Reference

### Fomio Surface Thresholds (source of truth)

| Threshold | Value | Meaning |
|-----------|-------|---------|
| Touch → Rail | `768px` | Bottom bar gives way to sidebar rail |
| Rail → Compact | `1024px` | Rail expands to compact sidebar |
| Compact → Expanded | `1280px` | Compact expands to full sidebar |
| Discourse mobile | `640px` | Discourse UA split (affects bundle, not surface) |

### How They Interact

Discourse's UA split fires at **640px**. Fomio's touch surface fires at **768px**. The gap (640–767px) receives the desktop CSS bundle but shows the touch shell. Styles that must apply in this band belong in `common.scss` under `body.fomio-surface-touch`, not in `mobile/mobile.scss`.

---

## 6. Pointer and Hover Context

Surface mode is based on viewport width, but interaction model also depends on pointer type. Use media features when behavior must differ by input — not just size.

```scss
// Hover states — only on fine pointer devices
@media (hover: hover) and (pointer: fine) {
  .fomio-card:hover { ... }
}

// Touch-safe minimum hit target
.fomio-sidebar__item {
  min-height: 44px; // WCAG 2.5.5 touch target minimum
}
```

The sidebar fallback before `fomio-surface-ready` is set uses both width and pointer:
```scss
@media (min-width: 768px) and (hover: hover) and (pointer: fine) {
  body.fomio-sidebar-active:not(.fomio-surface-ready) .fomio-sidebar {
    display: flex;
  }
}
```

---

## 7. Anti-Patterns

**Never do these:**

```scss
// ✗ Device detection as layout authority
.is-ipad { ... }
.is-mobile-device { ... }

// ✗ Relying on mobile.scss as the only source of touch behavior
// mobile.scss is width-only; a wide phone never sees it

// ✗ Hardcoding pixel values that duplicate surface thresholds
@media (max-width: 767px) { ... }  // okay in mobile.scss; duplicate if also in common.scss

// ✗ Raw env() scattered outside the touch shell
padding-top: env(safe-area-inset-top); // define on body.fomio-surface-touch, then consume via var()

// ✗ Overriding Discourse classes without fomio- scope
.topic-list { ... }  // must be .fomio-sidebar-active .topic-list or similar
```

---

## 8. Foldables and Orientation

Foldables are dynamic spatial devices. Do not hardcode screen-size assumptions for them.

| State | Expected surface |
|-------|-----------------|
| Folded (narrow) | `touch` |
| Unfolded portrait (~768px+) | `rail` |
| Unfolded landscape (wide) | `compact-desktop` or `expanded` |

The surface resolver in `fomio-layout.gjs` handles this dynamically. CSS should respond to the body class, not to a static device-type assumption.

---

## 9. File Assignment Summary

| What you're styling | File |
|--------------------|------|
| Tokens, shared component base styles | `common/common.scss` |
| Touch shell behavior (bottom bar, safe areas, overlays) | `common/common.scss` under `body.fomio-surface-touch` |
| Dark mode component overrides | `common/common.scss` under `html.fomio-color-dark` |
| Sidebar expanded/compact states | `common/common.scss` under surface body classes |
| Sidebar rail state | `common/common.scss` under `body.fomio-surface-rail` |
| Narrow viewport refinements (typography, spacing density) | `mobile/mobile.scss` |
| Wide viewport layout (reading column, sidebar widths) | `desktop/desktop.scss` |
| Mid-range tablet overrides (768–1099px) | `desktop/desktop.scss` with `@media` query |
