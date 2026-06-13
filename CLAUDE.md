# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**`apps/web/`** is the Discourse theme for Fomio. All web theme work happens here and is synced directly to Discourse via GitHub.

## Product Constitution (Highest Authority)

`apps/mobile/docs/00-product/product-ui-rules.md` governs all UI and copy decisions across every surface.

Terminology is non-negotiable:

| Use | Never use |
|-----|-----------|
| Hub | Category, Section, Group |
| Teret | Subcategory, Channel, Thread |
| Byte | Post, Article, Topic, Entry |

## Dev Commands

All commands run from the **repo root** (`/fomio/`):

```bash
npm run tokens:check   # Verify common.scss tokens are in sync with packages/design-tokens
npm run tokens:fix     # Auto-sync tokens from packages/design-tokens into common.scss

# Terminology check (run from repo root)
node apps/mobile/scripts/check-terminology.js
```

There is no local build step — the theme is deployed by pushing to GitHub, which Discourse syncs automatically.

## Skills

| Skill | Triggers |
|-------|---------|
| `fomio-web-ds` | `/web-ds`, `/token`, `/layout`, `/auth-ui`, `/editorial`, `/sidebar`, `/breakpoint`, `/component` (shared component updates) |
| `discourse-theme-developer` | `/outlet`, `/transformer`, `/connector`, `/scss`, `/theme` |
| `discourse-archeologist` | `/trace`, `/schema`, `/serialize` — when tracing what Discourse API returns |

## Architecture Philosophy — Sidebar OS & Master–Detail System

Fomio Web is **not** a traditional forum frontend or website. It is a persistent shell-based reading and discussion environment built on three foundational principles:

**Sidebar OS + Master–Detail Navigation + Persistent Shell Architecture**

Every UI, UX, and engineering decision must align with this model.

### The Mental Model

Traditional forums: `Page → Page → Page`

Fomio Web:
```
Persistent Shell
 ├── Navigation Layer (Master)  ← always visible
 └── Content Surface (Detail)  ← updates contextually
```

The user should feel they remain inside a single environment. Only content changes — not the shell.

### Shell Structure

```
<FomioShell>
  <SidebarMaster />
  <TopContextBar />
  <DetailSurface />
</FomioShell>
```

Only `<DetailSurface>` changes across navigation transitions. The shell persists.

### The Sidebar Is the OS

The sidebar is not a decorative nav element. It is the operating system of Fomio. It must feel persistent, stateful, and contextual — closer to Arc, Linear, Notion, or VSCode than to a forum sidebar or responsive nav drawer.

The sidebar eventually owns: active route, expanded Hubs/Terets, recent Bytes, reading history, pinned content, drafts, unread states, notification summaries, search navigation, and command palette integration.

### Navigation Depth → Sidebar Depth

Complex routes (Settings → Account → Security → Sessions) become expandable sidebar trees — not deeper page stacks. The Detail Surface updates while the shell stays put.

### Division of Responsibility

| Layer | Owned by |
|-------|----------|
| Backend, permissions, sessions, moderation, posting, notifications | Discourse |
| Experience, navigation, interaction philosophy, visual identity, information architecture | Fomio |

Do not rebuild Discourse logic. Reshape the experience around it.

### Reading-First

The reading surface is the primary visual object. Navigation and controls are secondary. All UI must preserve calmness, focus, and editorial spacing. The interface must never resemble Reddit, traditional forums, or social-media engagement systems.

### Progressive Disclosure

Standard users see a calm, lightweight reading UI. Moderators and admins see contextual tools and expanded menus. Complexity is revealed gradually — never exposed to all users by default.

### Product Goals

- Eliminate traditional forum navigation fatigue
- Reduce route-depth complexity
- Preserve user context across navigation
- Create a calm, reading-first environment
- Support future multi-surface consistency (mobile, CLI, web)

### Anti-Patterns — Never Build

- Route-heavy navigation
- Breadcrumb dependency
- Full-page-reload feeling
- Sidebar-as-drawer architecture
- Reddit-like engagement systems
- Visually noisy moderation systems
- Authentication that feels like entering a different product

### Future Expansion Targets

- **Split view:** Sidebar | Feed | Preview — or — Sidebar | Byte | Comments
- **Search as navigation:** command palette, routing, contextual discovery (Arc / Linear model)
- **Persistent composer:** docked, floating, or side-sheet — never disconnects from reading context
- **Persistent workspaces:** reading sessions, pinned contexts, focused modes
- **Shared philosophy** across mobile, CLI, and web (implementations differ; principles do not)

### Surface Adaptation Model (Required)

See `docs/surface-adaptation-model.md`.

Fomio adapts by changing interaction density and navigation behavior based on spatial context. It does not adapt by blindly shrinking or hiding UI.

Required surface modes:
- `expanded` (`>= 1280px`)
- `compact-desktop` (`1024px-1279px`)
- `rail` (`768px-1023px`)
- `touch` (`< 768px`)

Rules:
- preserve shell continuity across transitions
- degrade desktop to `rail` for narrow windows, not `touch`
- treat foldables as dynamic spatial contexts, not static device types
- keep composer state stable across resize, rotate, and fold transitions

### The Final Test

> Fomio Web should never feel like "a themed Discourse forum."
> It should feel like a modern operating environment for reading and discussion.

---

## Stack

- **Components:** GJS (`.gjs`) only — no legacy widgets, no `.hbs`
- **Entry points:** `apiInitializer` from `discourse/lib/api`
- **Settings:** `settings.yml` → `import { settings } from "virtual:theme"` (all keys prefixed `fomio_`)
- **i18n:** `locales/en.yml` → `i18n(themePrefix("key"))` — never inline strings
- **Styling:** SCSS with `fomio-` class prefix, `--d-*` Discourse variables for color
- **Source of truth for Discourse internals:** `discourse/` at repo root — read-only

## Shared Component System

Fomio Web uses a **three-layer design system** for reusable components. All shared components live in `javascripts/discourse/components/shared/` and are styled in `common.scss`.

### Three Layers

**Layer 1: Controls** — form elements and basic input components
- `fomio-button.gjs` — Button with variants (primary, secondary, ghost, danger), sizes, loading, icons
- `fomio-input.gjs` — Text input with label, hint, error, icons (search variant available as `fomio-search-input.gjs`)
- `fomio-select.gjs` — Select dropdown with label, hint, error, icons
- `fomio-textarea.gjs` — Textarea with label, hint, error
- `fomio-switch.gjs` — Toggle switch for boolean settings with on/off states

**Layer 2: Content** — display and information components
- `fomio-avatar.gjs` — User avatar with sizes, palette, online state, badge
- `fomio-badge.gjs` — Inline badge/tag for labeling and categorization
- `fomio-card.gjs` — Generic card container (base for byte-card, context cards, etc.)
- `fomio-identity.gjs` — Avatar + name + subtitle composition
- `fomio-list.gjs`, `fomio-list-item.gjs`, `fomio-list-section-header.gjs`, `fomio-list-separator.gjs` — List family
- `fomio-meta-row.gjs` — Metadata row (label + value) for facts, stats, details
- `fomio-empty-state.gjs` — Illustration + message + action for empty views
- `fomio-icon-pill.gjs` — Circular icon container with tones (accent, danger, info, success, warning) for settings rows and list items

**Layer 3: Interaction** — surface and behavior components
- `fomio-segmented-control.gjs` — Inline selection control (pills/buttons)
- `fomio-tabs.gjs` — Tab interface with keyboard navigation
- `fomio-dropdown.gjs` — Dropdown menu with keyboard navigation and nested submenus
- `fomio-command-palette.gjs` — Command/search palette with fuzzy find
- `fomio-search-sheet.gjs` — Bottom sheet for full-screen search
- `fomio-ephemeral-sheet.gjs` — Temporary overlay/modal surface
- `fomio-modal.gjs` — Full modal dialog
- `fomio-popover.gjs` — Contextual overlay anchored to a trigger (title, body, optional confirm/cancel) — lighter than modal
- `fomio-radio-group.gjs` — Radio button group
- `fomio-toast.gjs` — Toast notification
- `fomio-notice.gjs` — Inline, in-flow status message (info/success/warning/danger) with optional dismiss
- `fomio-banner.gjs` — Full-width, page-level announcement bar (info/success/warning/danger) with optional action + dismiss
- `fomio-loading-spinner.gjs` — Animated loading spinner for button states and async feedback

**Feature compositions** (use shared primitives, not layer-definition candidates):
- `fomio-notifications-menu.gjs` — Product-specific notification center shell
- `fomio-mobile-search-palette.gjs` — Mobile search UI composition
- `fomio-composer-category-picker.gjs` — Composer category selection
- `fomio-me-filter-chips.gjs` — "Me" filter behavior composition
- `fomio-user-profile-summary.gjs` — Profile identity + stats + actions
- `fomio-me-activity-nav.gjs` — Route-based activity navigation (not a selection control)
- `fomio-byte-card.gjs` — Byte preview card composition

### Interactive Behavior Layer

**`api-initializers/fomio-ui-components.gjs`** manages all stateless, interactive DOM behavior:
- **Dropdown** — `aria-expanded` toggle, click-outside close, keyboard navigation (Arrow keys, Escape, nested submenus via ArrowRight)
- **Tabs** — `aria-selected` state, panel visibility via `aria-hidden`, keyboard navigation (Arrow keys, Home/End)
- **Switch** — `aria-checked` toggle via click or Space/Enter
- **Chip** — `aria-pressed` toggle; single-select groups via `data-chip-group="single"`
- **Surface observer** — IntersectionObserver lazy-reveal for `.fomio-surface--hidden` → `.fomio-surface--observed`

State lives in **aria attributes** — SCSS keys off them without extra JS class names. All handlers use document-level event delegation (one listener per event type, persists across routes).

### Style Host

All shared component styles are defined in `common.scss`:
- **Section 1A** — `--fomio-*` tokens (color, typography, spacing)
- **Section 1B** — Dark mode color overrides
- **Sections 2–6** — Layer 1, 2, 3 component styles (`.fomio-button`, `.fomio-input`, `.fomio-dropdown`, etc.)

Desktop-only and mobile-only refinements go in `desktop/desktop.scss` and `mobile/mobile.scss` respectively.

### Component API Conventions

All shared components follow these conventions:
- **Props:** Use semantic names (`variant`, `size`, `disabled`, `loading`, `leadingIcon`, `trailingIcon`, `@label`, `@hint`, `@error`)
- **Styling:** Apply only `fomio-*` classes; let SCSS handle size/variant/state appearance
- **Accessibility:** Use ARIA attributes (`aria-expanded`, `aria-selected`, `aria-checked`, `aria-pressed`, `aria-hidden`, `aria-disabled`) for semantic meaning
- **Display-only:** Components themselves are stateless; consumers manage state via `@args` and event handlers (`@onClick`, `@onSelect`, `@onOpenChange`)
- **Composition:** Layer 2 and 3 components compose Layer 1 primitives where it makes sense; feature components use any layer as needed

### When to Add a Shared Component

Add to `components/shared/` if the component:
1. Is used across multiple features (not feature-specific)
2. Fits cleanly into one of the three layers (or is a composition of existing layers)
3. Has a simple, generic API (not product-logic-heavy)
4. Belongs in a design system (not a one-off experimental UI)

If unsure, keep feature UIs local first, then extract once a second use appears. Use the audit in `docs/phase-1-shared-components-audit.md` as the authoritative layer definition.

## Current File Structure

```
apps/web/
├── about.json                        # Discourse color schemes (light + dark palette)
├── settings.yml                      # fomio_* settings (fomio_app_url)
├── locales/en.yml                    # themePrefix() strings
├── common/
│   ├── common.scss                   # --fomio-* tokens + all shared styles
│   ├── embedded.scss                 # Styles for Discourse embed widget (currently empty)
│   ├── head_tag.html                 # Google Fonts preconnect + stylesheet link
│   ├── body_tag.html                 # Trust line injection into /user-api-key/new
│   ├── header.html                   # Shared header injection (all surfaces)
│   ├── after_header.html             # Shared after-header injection (all surfaces)
│   └── footer.html                   # Shared footer injection (all surfaces)
├── desktop/
│   ├── desktop.scss                  # Desktop-only styles (768px+)
│   ├── head_tag.html                 # Desktop-only <head> injections
│   ├── body_tag.html                 # Desktop-only <body> injections
│   ├── header.html                   # Desktop-only header markup
│   ├── after_header.html             # Desktop-only after-header markup
│   └── footer.html                   # Desktop-only footer markup
├── mobile/
│   ├── mobile.scss                   # Mobile-only styles (0–767px)
│   ├── head_tag.html                 # Mobile-only <head> injections
│   ├── body_tag.html                 # Mobile-only <body> injections
│   ├── header.html                   # Mobile-only header markup
│   ├── after_header.html             # Mobile-only after-header markup
│   └── footer.html                   # Mobile-only footer markup
├── docs/
│   ├── auth-ui-stitch-guide.md       # Design prompts for all 17 auth screens
│   ├── manuscript-design-system.md  # Design system strategy reference
│   └── web/
│       ├── composer-audit.md         # Composer feature audit
│       └── rich-editor-composer-reference.md  # Rich editor integration notes
└── javascripts/discourse/
    ├── api-initializers/
    │   ├── theme-initializer.gjs     # Auth UI enhancements + mobile handoff (see below)
    │   ├── fomio-ui-components.gjs   # Interactive behavior layer: dropdowns, tabs, switches, chips, surface observer
    │   ├── fomio-color-mode.gjs      # Dark mode: syncs html.fomio-color-dark
    │   ├── fomio-layout.gjs          # Sidebar layout: toggles body.fomio-sidebar-active
    │   ├── fomio-rich-editor-toolbar.gjs  # Forces rich editor mode; registers ProseMirror toolbar extension
    │   └── my-theme.gjs             # Legacy placeholder — do not add to
    ├── components/
    │   └── shared/                   # Shared three-layer design system components
    │       ├── Layer 1 (Controls): fomio-button, fomio-input, fomio-search-input, fomio-select, fomio-switch,
    │       │                       fomio-textarea
    │       ├── Layer 2 (Content): fomio-avatar, fomio-badge, fomio-card, fomio-icon-pill, fomio-identity,
    │       │                      fomio-list*, fomio-meta-row, fomio-empty-state, fomio-byte-card
    │       └── Layer 3 (Interaction): fomio-segmented-control, fomio-tabs, fomio-dropdown, fomio-command-palette,
    │                                  fomio-search-sheet, fomio-ephemeral-sheet, fomio-modal, fomio-popover,
    │                                  fomio-radio-group, fomio-toast, fomio-notice, fomio-banner,
    │                                  fomio-loading-spinner, fomio-notifications-menu
    ├── lib/
    │   └── fomio-selection-toolbar-extension.js  # ProseMirror floating selection toolbar
    └── connectors/
        ├── above-site-header/fomio-sidebar.gjs   # Persistent non-touch sidebar nav (expanded/compact/rail)
        ├── above-site-header/fomio-bottom-bar.gjs # Mobile bottom navigation bar
        ├── before-composer-controls/fomio-composer-topbar.gjs  # Composer topbar: mode label, back, close (create/edit)
        ├── before-composer-fields/fomio-fullscreen-composer-fields.gjs  # Restores title/category/tags in fullscreen
        ├── composer-open/fomio-composer-reply-context.gjs  # Reply: teret tag + byte title context card
        ├── composer-action-after/fomio-composer-edit-banner.gjs  # Edit: "editing your byte" banner
        ├── composer-after-composer-editor/fomio-composer-rail.gjs  # Create/edit: word count, outline, checks rail
        ├── composer-fields-below/fomio-composer-statusbar.gjs  # Create/edit: saved indicator + counts
        ├── composer-fields-below/fomio-composer-hints.gjs  # Create/edit: ⌘↵ / esc keyboard hints
        ├── discovery-list-controls-above/fomio-hub-chrome.gjs  # Hub page chrome: breadcrumb, hero, Teret tabs, filter bar
        ├── below-discovery-categories/fomio-categories.gjs     # /categories index: grid/list toggle, search, hub cards
        ├── full-page-search-above-search-header/fomio-search-header.gjs  # Search page title header
        ├── login-header-bottom/fomio-login-subheader.gjs
        ├── create-account-header-bottom/fomio-signup-subheader.gjs
        ├── post-links/fomio-post-interactions.gjs  # Per-post interaction bar
        ├── topic-list-main-link-bottom/fomio-topic-context.gjs
        ├── topic-title/fomio-topic-reading-meta.gjs
        └── after-topic-footer-buttons/fomio-topic-app-handoff.gjs  # Mobile: Open in Fomio → byte deep link
```

## Composer Architecture

> See `docs/web/rich-editor-composer-reference.md` for full detail.

The composer is the **native Discourse composer**, restyled in place and extended only through supported theme APIs (plugin outlets, value transformers, rich-editor extensions). The Ember layer is never modified.

An earlier full-screen overlay experiment (`fomio-composer.gjs`, `fomio-block-editor.gjs`, the `.fomio-cm-*` SCSS, and the block/slash/source-toggle locale keys) has been **fully removed** — do not reintroduce a parallel composer shell.

### Editorial surface (three modes)

Driven by Discourse's own `composer-action-${dasherize(action)}` class on `#reply-control`:

- **Create** (`.composer-action-create-topic`) and **Edit** (`.composer-action-edit`) → full-page editorial surface beside the persistent sidebar (`left: var(--fomio-surface-sidebar-offset)`), with topbar, right rail (word count / outline / checks), and status bar.
- **Reply** (`.composer-action-reply`) → stays a refined in-context bottom sheet with a byte-context card; no rail/status bar.

Live editor metrics (word/char counts, heading outline) come from a read-only ProseMirror extension (`lib/fomio-composer-metrics-extension.js`) that writes a tracked singleton (`lib/fomio-composer-metrics-store.js`); pure derivations live in `lib/fomio-composer-metrics.js` (unit-tested in `tests/fomio-composer-metrics.test.js`). The connectors listed in the file tree read that store.

### Active composer extension points

**`fomio-rich-editor-toolbar.gjs`** (the main file):
- Forces rich-editor mode via `registerValueTransformer("composer-force-editor-mode")` → `USER_OPTION_COMPOSITION_MODES.rich`; markdown textarea path is out of scope
- Overrides the placeholder via `registerValueTransformer("composer-editor-reply-placeholder")`
- Registers `lib/fomio-selection-toolbar-extension.js` via `api.registerRichEditorExtension`

**`lib/fomio-selection-toolbar-extension.js`** — ProseMirror plugin:
- Shows a floating Bold / Italic / Link toolbar on non-empty `TextSelection` inside `#reply-control`
- Lightweight DOM implementation: `FomioSelectionToolbarPluginView` creates a simple `<div class="fomio-selection-toolbar">` with three `<button>` elements
- Uses `UpsertHyperlink` modal (Discourse core primitive) for link editing
- Access ProseMirror classes through extension params (e.g. `pmState.TextSelection`), not direct package imports — theme bundles do not resolve raw `prosemirror-*` imports
- i18n keys: `composer.toolbar_aria_label`, `composer.toolbar_bold`, `composer.toolbar_italic`, `composer.toolbar_link` (fallbacks to English labels if missing)

**`connectors/before-composer-fields/fomio-fullscreen-composer-fields.gjs`**:
- Restores title/category/tags in fullscreen mode — core deliberately removes them when `viewFullscreen` is true
- Uses the `before-composer-fields` outlet

### Styling the composer

The native `#reply-control` is styled under `body.fomio-sidebar-active #reply-control` in `common.scss` (section "7. Composer shell"). The fixed top toolbar (`.d-editor-button-bar__wrap`) is hidden because the floating toolbar replaces it. `.composer-action-title` is also hidden.

The full-page Create / Edit surface is pure CSS, scoped to `&.open.composer-action-create-topic, &.open.composer-action-edit`: it pins `#reply-control` to the viewport beside the sidebar (`left: var(--fomio-surface-sidebar-offset)`), turns `.reply-to` into the sticky topbar, centres the writing column (`--fomio-composer-measure`), and absolutely positions the rail + status bar. Reply is left as the native bottom sheet. Connector visuals live in section "7b. Composer editorial connectors"; touch overrides in `mobile/mobile.scss`. The metrics extension's `update(view)` is wrapped in try/catch — it can never throw into editor setup (see failure mode 3).

**Open-canvas behaviour** (`lib/fomio-composer-canvas.js`): the writing column reads as one open canvas (`cursor: text`, seams removed, editable fills the viewport). A document-level, capture-phase `mousedown` listener focuses the editor and drops the caret at the end when the user clicks the canvas dead space (margins / below the text), in create/edit only. It focuses the same element core focuses (`.d-editor-container .d-editor-input`) and uses a standard DOM range — no ProseMirror internals. The focus *decision* is the pure, unit-tested `shouldFocusCanvas()`; only the DOM glue is runtime-only. Every branch is guarded so it can never break a normal click.

### Known failure modes

1. **Direct ProseMirror package imports** (`import { TextSelection } from "prosemirror-state"`) fail — use extension params instead.
2. **Unimported helpers in GJS templates** — strict-mode templates only see explicitly imported values; always import `hash`, `fn`, `eq`, etc.
3. **Extension plugin errors cascade**: if the floating toolbar extension throws during editor setup, typing can stop entirely. Check theme JS errors before debugging input behavior.

## Hub & Categories UI

### `connectors/discovery-list-controls-above/fomio-hub-chrome.gjs`

Renders the Hub page chrome above the topic list on any `/c/…` route. Does **not** render on `/categories` (where `category` arg is null). Includes:

- **Breadcrumb** — "Hubs" → hub name
- **Hero** — color swatch (first letter), hub name, description, byte/reply counts (`fmtK` rounds to `k`)
- **Teret tabs** — "All" plus one tab per sub-category; active tab derived from current URL
- **Filter bar** — Latest / Top / New, active state from `router.currentURL`

Hub resolution: if the outlet passes a sub-category (Teret), the component walks up to `parent_category_id` to find the Hub, then lists the Hub's sibling Terets.

### `connectors/below-discovery-categories/fomio-categories.gjs`

Replaces the default `/categories` page body. Features:
- Grid / List view toggle (tracked `@view`)
- Live search (tracked `@searchQuery`) filtering hub name and description
- **Grid:** `.fomio-hub-card` — color swatch, name, byte count, description, Teret pills
- **List:** `.fomio-hub-row` — swatch, name + Teret names, description, byte count, chevron

Only top-level categories (no `parent_category_id`) are shown as Hubs. Terets are derived from `site.categories` on the client — no extra API calls.

### `connectors/full-page-search-above-search-header/fomio-search-header.gjs`

Injects an `<h1>` title above the Discourse full-page search bar. Title string comes from `search_page.title` in `locales/en.yml`.

---

## `theme-initializer.gjs` — Scope

> **Do not modify this file without reading both this section and the Auth & Handoff Flow section.**
> The guards look like dead code but removing either breaks sign-in.

This initializer runs on every Ember page change and on initial page load. It handles:

1. **Scoped mobile handoff** — post app-initiated signup activation only (`fomio_post_activation_expires_at`); keeps auth-session GUARD 1/2 for User API Key sign-in
2. **Signup password strength bar** — terracotta meter injected under `#new-account-password`
3. **Forgot-password modal** — inline email validity hint, "Back to sign in" link, success-state reshape
4. **2FA TOTP** — OTP grid styling, eyebrow/heading/code-label injection, backup/passkey switch links
5. **2FA backup code** — key icon, warning pill, auto-formatting `xxxx-xxxx-xxxx`, switch links
6. **Passkey loading state** — spinner + label swap on button click while biometric dialog is open

All DOM manipulation is idempotent — each function checks for its own markers (`data-fomio-*`, class names) before injecting.

## `body_tag.html` — Trust Line

The `/user-api-key/new` authorization page is rendered by Rails with `no_ember: true` — the apiInitializer never runs there. The trust line ("You're authorizing the official Fomio app.") is injected via an inline `<script>` in `body_tag.html`, which Discourse injects into every page's `<body>`. The script finds `.authorize-api-key` and guards against double-injection.

## `fomio-color-mode.gjs` — Dark Mode

Discourse ships two color-scheme `<link>` tags (`link.light-scheme`, `link.dark-scheme`) and toggles their `media` attribute to switch modes. This initializer observes those attributes and toggles `html.fomio-color-dark`, letting `common.scss` target dark-mode overrides via `.fomio-color-dark .fomio-*` selectors.

## `about.json` — Discourse Color Schemes

Defines the `Fomio` (light) and `Fomio Dark` color schemes. Discourse maps these to `--d-*` CSS variables site-wide. When changing brand colors, update both `about.json` (for `--d-*` variables used in Discourse core UI) and `common.scss` Section 1 (for `--fomio-*` tokens used in theme SCSS). Run `npm run tokens:check` to verify the theme tokens are in sync with `packages/design-tokens`.

## Auth & Handoff Flow

> The guards below look like dead code but removing either one breaks sign-in.

### How the mobile app opens Discourse web

| Flow | Browser primitive | Purpose |
|------|------------------|---------|
| Sign-in | `WebBrowser.openAuthSessionAsync` | Opens ASWebAuthenticationSession (iOS) / Chrome Custom Tab (Android). The session captures the first `fomio://` deep link it sees and returns it to the app. |
| Sign-up | `WebBrowser.openBrowserAsync` | Opens a plain browser. No deep link interception — the user must complete all Discourse web steps before the app gets control back. |

### Sign-in flow (User API Key auth)

```
App calls openAuthSessionAsync(/user-api-key/new)
  → Discourse 302s to /login        (user not logged in on web)
  → User fills login form
  → Discourse redirects to /        (post-login default)
  → Discourse redirects to /user-api-key/new
  → User taps "Authorize"
  → Discourse redirects to fomio://auth_redirect?payload=...
  → ASWebAuthenticationSession catches it, returns payload to app
  → lib/auth.ts decrypts payload, stores API key
```

**GUARD 1** (`theme-initializer.gjs` `/login` and `/session/*` handlers):
When the session opens `/user-api-key/new` and Discourse 302s to `/login` (or to `/session/*` for SSO, 2FA, OTP, or passkeys), `performance.getEntriesByType('navigation')[0].redirectCount > 0` is true.
The theme must NOT fire the `fomio://signin?autoAuth=true` redirect, or the auth session intercepts that deep link (no `payload`) and throws "Authorization cancelled".
- On `/login` with `redirectCount > 0`: sets `sessionStorage['fomio_auth_flow'] = '1'`
- On `/session/*` with `redirectCount > 0`: calls `markFomioAuthFlowIfRedirected()` which sets the same flag

**GUARD 2** (`theme-initializer.gjs` home handler):
After the user logs in, Discourse redirects to `/` before proceeding to `/user-api-key/new`.
The home handler checks for the `fomio_auth_flow` flag and skips **any** app handoff, then clears the flag.
Without this guard, a home-page `fomio://signin?autoAuth=true` redirect could fire during the User API Key session; the session would intercept it (wrong URL, no `payload`) and sign-in would fail.

### Sign-up flow (scoped auto-return)

```
App calls openBrowserAsync(/signup?fomio=1)
  → … account-created → /u/activate-account/:token
  → Theme sets fomio_post_activation_expires_at (short TTL) when app-signup marker was present
  → User activates; Discourse JS: window.location.href = "/"
  → Browser lands on /
  → If expiry valid: showHandoffOverlay(`${fomio_app_url}signin?autoAuth=true`)
  → Mobile opens auth modal
```

Ordinary mobile visits to `/`, `/latest`, etc. **do not** auto-open the app.

**Do NOT add redirects at `/u/account-created` or before the Activate Account action.**

### Direct `/login` tap (email link, mobile browser)

Web login stays in-browser. Use explicit CTAs (e.g. topic footer handoff) or sign in from the Fomio app.

### Paths that bypass handoff entirely

`isDiscourseAuthSupportingPath()` blocks the handoff overlay for:
`/user-api-key`, `/session/`, `/password-reset`, `/u/activate-account`, `/u/account-created`, `/signup`, `/invites`, `/u/confirm`, `/auth/`

### Deep links used

| Deep link | Destination |
|-----------|-------------|
| `fomio://signin?autoAuth=true` | `app/(auth)/auth-modal` — via `apps/mobile/lib/deep-linking.ts` |
| `fomio://byte/:id` | Specific Byte — `connectors/after-topic-footer-buttons/fomio-topic-app-handoff.gjs` |

All deep links are constructed from the `fomio_app_url` theme setting. Never hardcode `fomio://`.

### Sources verified against

- Discourse activation redirect: `discourse/frontend/discourse/app/templates/activate-account.gjs:84`
- Discourse login redirect on unauthenticated API key request: `app/controllers/user_api_keys_controller.rb:26-33`
- App auth session: `apps/mobile/lib/auth.ts signIn()`
- App deep link routing: `apps/mobile/lib/deep-linking.ts`

---

## Rules

- **Always verify outlets** before using: `rg '<PluginOutlet @name="name"' discourse/app`
- **Always verify transformers** before using: `rg 'applyValueTransformer.*"key"' discourse/app`
- **Transformers before workarounds:** transformer → connector → `onPageChange` → DOM (last resort)
- **All CSS scoped** under `fomio-` prefix — no bare Discourse class overrides
- **No fetch calls** in theme JS — themes are UI-only
- **`lib/` files are not entry points** — Discourse's theme build only compiles `api-initializers/`, `connectors/`, and `components/` as entry points. Files in `lib/` are never compiled standalone, but CAN be imported via relative path from those compiled files (e.g. `import ext from "../lib/fomio-selection-toolbar-extension"`). Do not import `lib/` files from other `lib/` files.
- **No hardcoded deep links** — always use `fomio_app_url` setting
- **No hardcoded hex values** in SCSS — use `--fomio-*` tokens from `common.scss` Section 1
- **No forbidden terminology** in `locales/en.yml` or any component copy

### Shared Component Rules

- **Shared components are display-only** — no business logic, no API calls, no data fetching
- **State management:** Components receive state as `@args`; consumers manage state and pass event handlers (`@onClick`, `@onSelect`, `@onOpenChange`)
- **Styling via `fomio-*` classes only** — never apply Discourse classes; let SCSS handle variant/size/state styling
- **Accessibility first** — use ARIA attributes (`aria-expanded`, `aria-selected`, `aria-checked`, `aria-disabled`) for semantic meaning; test with screen readers
- **Keep APIs simple** — use semantic prop names (`variant`, `size`, `disabled`, `loading`, `leadingIcon`, `trailingIcon`, `@label`, `@hint`, `@error`); avoid prop proliferation
- **Composition over specialization** — reuse Layer 1/2 components in Layer 3; avoid creating near-duplicate components
- **Document your component** — include a brief summary comment at the top explaining its role and public props
- **Test across surfaces** — verify behavior on desktop, tablet (768px), and mobile (<768px) breakpoints before shipping

## Design System Notes

### Color — Shared Token System

The web theme and mobile app share the same canonical palette from `packages/design-tokens/tokens.js`. `common.scss` Section 1 mirrors `toCssVariables('light')` — run `npm run tokens:check` after any token change to catch drift.

| Token | Value | Variable |
|-------|-------|----------|
| Primary | `#C44536` terracotta | `--fomio-primary` |
| Background | `#F8F7F3` cream | `--fomio-bg` |
| Text | `#1A1A1A` | `--fomio-text` |
| UI font | Raleway | `--fomio-font-ui` |
| Body font | Lora (serif) | `--fomio-font-serif` |

`common.scss` also has legacy alias variables (`--fomio-ink`, `--fomio-paper`, etc.) that map to the canonical names for backwards compatibility. Use canonical names (`--fomio-text`, `--fomio-bg`) in new code.

### Dark Mode

Dark palette is defined in `about.json` (`Fomio Dark` scheme) and Section **1B** of `common.scss`. The **web theme uses warm brown** (`#1a1917` background, terracotta accent `#e67458`) per the Fomio Design System Handoff — not AMOLED. The mobile app remains AMOLED via `packages/design-tokens`. `fomio-color-mode.gjs` toggles `html.fomio-color-dark` when the active Discourse color scheme is dark. Scope dark overrides under `html.fomio-color-dark` in SCSS.

### Responsive Breakpoints

| Range | Stylesheet applied |
|-------|--------------------|
| 0–767px | `mobile/mobile.scss` (Discourse applies automatically) |
| 768–899px | `desktop/desktop.scss` (tablet override) |
| 900px+ | `desktop/desktop.scss` (full desktop) |

Important: Discourse's stylesheet split is viewport-based, but Fomio's shell ownership is surface-based. Any behavior that must survive phone landscape, foldables, or coarse-touch devices wider than `767px` belongs in `common/common.scss` under `body.fomio-surface-touch`, not only in `mobile/mobile.scss`. Use `mobile/mobile.scss` for narrow-width refinements, not as the sole source of truth for the touch shell.

Safe area follows the same rule. Define touch-safe insets and derived page gutters in the touch shell (`body.fomio-surface-touch`) and have homepage/feed/components consume those variables. Do not scatter raw `env(safe-area-inset-*)` math across individual mobile pages unless the case is truly component-specific.

### Me Leaf Screens — One Flat Surface (all modes)

All Me leaf screens (Activity, Notifications, Messages, Invites, Preferences, Badges) use a **one-flat-surface pattern** at the page level on **every surface mode**: no canvas gradient, no wrapper card, unboxed pill tracks. The flat treatment is a property of the detail surface, not of the touch mode — only navigation chrome and density vary per mode (persistent master pane on expanded/compact-desktop, overlay master pane on rail, stack header + bottom nav on touch). The page is fully responsive without fixed card insets.

Within that flat surface, form screens (preferences) also drop per-control-group boxes — grouping comes from spacing and hairline separators (`border-top: 1px solid color-mix(...)`). On touch this lives in the touch shell block of `common.scss`; on desktop/rail in the "Settings detail alignment" block of `desktop.scss`. Stream/list screens (Activity, Notifications, Messages, Invites, Badges) keep **item-level** cards to separate rows.

**See:** `docs/web/touch-preferences-redesign-pattern.md` for full rationale, implementation guidance, and future application rules.

## Studio Protocols

All four protocols apply before any connector or component ships:

- **Design Critique** (3 passes, web-adapted)
- **Exploration Mode** (3 directions) when no existing pattern fits
- **Quality Audit** (6 passes) before merging to main
- **DS Evolution** (DSP required) before any new reusable component

See "Web Theme Adaptations" in `.cursor/rules/studio.mdc`.

## Ship Checklist

- [ ] Design critique passed (all 3 passes, web-adapted)
- [ ] Quality audit passed (all 6 passes)
- [ ] Terminology check: `node apps/mobile/scripts/check-terminology.js`
- [ ] Token sync check: `npm run tokens:check`
- [ ] Verified in both desktop and mobile Discourse preview
