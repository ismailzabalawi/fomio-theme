# Fomio UI Design Philosophy

Read this before designing or reviewing any screen, component, flow, or AI-assisted draft. It defines what "good" looks like at Fomio and gives you the tools to detect when a design is drifting toward generic or AI-obvious territory.

---

## Core Philosophy

**Read first. Act clearly. Reveal complexity gradually.**

Every design decision flows from this sentence:
- **Read first** — content hierarchy beats chrome; the first screenful shows meaningful content, context, and one next step.
- **Act clearly** — primary actions are obvious and minimal; secondary and destructive actions are de-emphasized or deferred.
- **Reveal complexity gradually** — standard users see a calm reading UI; moderators and admins see expanded tools only when relevant.

---

## 5 Core Values

| Value | What it means |
|---|---|
| Clarity over ornament | Layout and copy explain what matters before decoration does. No hero sections, gradients, or glow unless they carry meaning. |
| Specificity over genericness | Nav labels, page titles, empty states, and calls to action use Fomio's real nouns (Hub, Teret, Byte, Explore, Review) — never generic SaaS defaults (Dashboard, Analytics, Users). |
| Calm surfaces, strong hierarchy | Spacing, type scale, and contrast create order before any new surface, elevation, or motion is introduced. One dominant region per screen; secondary regions visibly quieter. |
| Accessible by default | Focus rings, touch targets, contrast, reflow, status messages, and keyboard paths are part of the design — not an engineering pass-through after sign-off. |
| Complete states over happy-path polish | Empty, loading, error, long-content, permissions, and moderation states are designed before visual refinement escalates. |

---

## 10 Design Principles

### 1. Content before chrome
The first screenful shows meaningful content, title, context, and one primary next step. Shell and decorative containers never dominate the viewport before content appears.

### 2. Hierarchy over symmetry
One dominant region per screen; secondary regions are visibly quieter. Equal spacing, equal card sizes, and equal visual weight for all items destroys scanning priority. Use deliberate asymmetry — size, weight, spacing — to signal importance.

### 3. Lists before cards
Use lists for repetitive scan tasks (feeds, search results, activity). Use cards only for self-contained objects where grouping adds meaning (a featured Byte, a Hub tile, a composer context card). Never use cards as the default surface for everything.

### 4. One primary action per region
Each screen region exposes one primary action and at most one secondary action. Everything else goes into a menu, overflow control, or contextual reveal. This applies to list rows, feed items, moderation queues, and settings panels.

### 5. Progressive disclosure
Show the action the user needs now. Defer admin, destructive, and uncommon tools to overflow menus or secondary panels. Never expose every mode and permission simultaneously because the system supports them.

### 6. Real states before happy-path polish
Every critical flow ships with all six states designed before visual polish escalates:
- **Empty** — explain why and what to do next; include a next action if meaningful
- **Loading** — skeleton when layout shape is known; spinner for short waits; progress for measurable operations
- **Error** — state what failed, where, and what the user can do; errors are always textual
- **Long content** — readable line length, clear truncation rules, explicit expand/collapse that preserves focus
- **Permissions** — show unavailable actions with explanation when the constraint is learnable; otherwise hide them. Use `fomio-permission-notice` (see `docs/dsp-001-permission-state.md`)
- **Moderation** — everyday actions separated from management actions; context preserved before irreversible decisions. Use `fomio-moderation-bar` + review surface (see `docs/dsp-002-moderation-surface.md`)

### 7. Product-specific navigation
Top-level nav uses Fomio nouns and task language. No generic labels unless they are literally core product concepts. "Explore" beats "Dashboard"; "Review queue" beats "Admin"; "Inbox" beats "Notifications."

### 8. Semantics over decoration
Color is never the only signal. Focus is always visible. Status changes are announced to assistive technology. Meaning is carried by text, shape, iconography, position, and ARIA in addition to color.

### 9. Purposeful motion only
Motion confirms cause and effect, teaches spatial change, or orients the user. If an animation teaches nothing, remove it. Always respect `prefers-reduced-motion`. Decorative hover animations, card float effects, and entrance transitions are not "premium" — they are noise.

### 10. Accessibility is a quality bar, not a phase
WCAG 2.2 requirements are design intent from day one: focus rings visible and not obscured, touch targets ≥ 44×44px, text contrast ≥ 4.5:1, non-text contrast ≥ 3:1, keyboard order matching visual flow, errors always textual, no color-only signaling.

---

## AI Anti-Patterns — Reject These

When reviewing AI-assisted drafts or generated screens, explicitly check for and reject:

| Anti-pattern | Why it fails | Replace with |
|---|---|---|
| Perfect symmetry everywhere | Destroys hierarchy; everything reads the same importance | Weighted hierarchy: one dominant region, secondary quieter, tertiary in overflow |
| Card saturation | Visual noise; false boundaries between items that should scan as a list | Open layout first; card only when grouping adds meaning |
| Generic SaaS navigation labels | Makes Fomio feel interchangeable with any dashboard product | Fomio nouns: Explore, Following, Create, Inbox, Profile, Review |
| Persistent action overload | Cognitive load; accidental destructive clicks | One primary persistent action; secondary on hover/focus; destructive in overflow |
| Decorative gradients or glass on every surface | Competes with readability and status clarity | Flat surfaces everywhere; one brand accent moment per screen max |
| Happy-path-only mockups | Conceals implementation risk; ships incomplete product | State matrix (empty/loading/error/permissions/moderation) required before polish sign-off |

---

## Component-Level Rules

### Layout
- Design for all four surface modes: expanded (≥1280px), compact-desktop (1024–1279px), rail (768–1023px), touch (<768px)
- Content priority must survive the layout change — not just shrink the same composition
- See `docs/responsive-design.md` for file ownership rules

### Spacing
- Use spacing to group, separate, and signal importance — never equal spacing by default
- One base scale; density presets agreed before component work begins

### Cards
- Cards are opt-in, not the default surface
- On scan-heavy pages: card usage should be below 50% of major content regions
- Lists are the default for repetitive items

### Navigation
- Top-level labels: no generic SaaS nouns; every label is a Fomio noun or task
- Tab count: minimum needed for wayfinding; too many tabs reduce findability
- Use the smallest navigation model that preserves wayfinding

### Actions
- 1 persistent primary action per region
- 0–1 secondary actions (visible on hover/focus or inline)
- All remaining actions in overflow/menu
- Destructive and admin actions never compete visually with ordinary tasks

### States (required for every interactive component)
- hover, focus, pressed, selected, disabled, loading, success, error
- All states use ARIA attributes as the source of truth; SCSS keys off them

### Typography
- Legibility and scalable hierarchy over graphic styling
- Must survive 200% text resize without loss (WCAG)
- Text spacing (line-height, letter-spacing, word-spacing) adjustments must not break layout

### Color
- Never color-only for meaning
- Text contrast: ≥ 4.5:1 normal, ≥ 3:1 large text
- Non-text UI contrast: ≥ 3:1 for relevant boundaries
- Focus ring must meet non-text contrast in all states

### Motion
- Teaches state change, hierarchy, or spatial transition — or it's removed
- `prefers-reduced-motion` always respected
- No entrance animations unless they orient the user

### Accessibility thresholds
- Touch targets: ≥ 44×44px (Apple guidance; WCAG minimum is 24×24px)
- Focus: always visible, never obscured by overlays or sticky elements
- Keyboard order: matches visual reading flow
- Status changes: announced via `role="status"` or `aria-live`

---

## AI-Genericness Self-Check

Use this before shipping any screen or component. These are Fomio internal thresholds — tune them after auditing real screens.

| Metric | Healthy | Review | Risk |
|---|---|---|---|
| Card saturation on primary scan pages | 0–35% of major regions | 36–50% | >50% |
| Persistent actions per list/feed item | 1–2 | 3 | 4+ |
| Identical sibling module widths on first screen | <50% | 50–70% | >70% |
| Product-specific top-level nav labels | ≥80% | 60–79% | <60% |
| Critical-flow state coverage (all 6 states) | 100% | 80–99% | <80% |
| Accessibility blockers at release | 0 | 1 with exception | Any unresolved |

---

## State Matrix — Required Before Polish Sign-Off

Every critical flow must have all six states designed before visual refinement work begins. "Critical flow" = any flow a user reaches through normal navigation.

| State | Required content |
|---|---|
| Empty | Reason + next action (if meaningful) |
| Loading | Skeleton (known layout) / spinner (unknown duration) / progress (measurable) |
| Error | What failed + where + what to do now (always textual) |
| Long content | Truncation rule + expand/collapse preserving focus |
| Permissions | Explanation when learnable — use `fomio-permission-notice` (see `docs/dsp-001-permission-state.md`); hidden when not |
| Moderation | Context preserved; everyday vs management separated — use `fomio-moderation-bar` + review surface (see `docs/dsp-002-moderation-surface.md`) |

---

## Review Workflow

Every design (including AI-assisted drafts) passes through these gates in order:

1. **Problem statement check** — does the design solve the stated user task?
2. **Principles review** — do all 10 principles hold? reject if generic or decorative
3. **State matrix review** — all 6 states present for every critical flow?
4. **Accessibility and semantics review** — contrast, focus, targets, ARIA, keyboard order
5. **Component reuse check** — are shared components used where they exist?
6. **Engineering feasibility** — is it buildable without framework workarounds?
7. **QA with edge cases** — permissions, long content, simultaneous states

A design that fails gates 2, 3, or 4 returns to the concept stage — it does not move to engineering.

---

## Resources

- **Responsive design rules**: `docs/responsive-design.md` — file ownership, surface mode patterns, anti-patterns
- **Component checklist**: `docs/component-checklist.md` — build checklist including state matrix
- **Shared component guide**: `docs/shared-component-development.md` — composition patterns and API conventions
- **Senior Product UI Policy**: `docs/senior-product-ui-policy.md` — project-wide design bar (repo root)
