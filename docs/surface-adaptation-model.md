# Fomio Web — Surface Adaptation Model

## Core Principle

Fomio Web does not adapt by shrinking layouts blindly. It adapts by changing interaction density and navigation behavior based on available spatial context.

The shell persists. The interaction model adapts. The reading experience remains primary.

## Surface Modes

Do not model surfaces as desktop/tablet/mobile. Model them as spatial modes:

```ts
type SurfaceMode = "expanded" | "compact-desktop" | "rail" | "touch";
```

### 1) Expanded (`>= 1280px`)

Behavior:
- full sidebar
- wide detail surface
- future multi-pane ready

Characteristics:
- persistent navigation with full labels
- wide editorial spacing
- room for contextual side panes

### 2) Compact Desktop (`1024px-1279px`)

Behavior:
- reduced sidebar
- focused reading surface

Characteristics:
- reduced spacing and typography density
- contextual sidebar collapse allowed
- no multi-pane behavior

### 3) Rail (`768px-1023px`)

Behavior:
- sidebar rail
- single detail surface
- reduced density

Characteristics:
- symbolic navigation with floating labels
- tighter spacing and smaller typography
- compact thumbnails
- persistent search affordance

### 4) Touch (`< 768px`)

Behavior:
- bottom navigation
- scroll-priority reading
- minimal contextual header

Characteristics:
- thumb-first interaction
- content width maximized
- overlays replace persistent side panels

## Foldables

Foldables are dynamic spatial devices. Do not classify by device type.

Adapt to spatial context (width, orientation, posture, interaction mode):
- folded -> `touch`
- unfolded portrait -> `rail`
- unfolded landscape -> `compact-desktop` when spatially valid

Do not hardcode tablet or foldable detection.

## Critical Edge Rules

1) Sidebar leak prevention
- Fomio shell state overrides Discourse layout state.
- Do not trust Discourse sidebar defaults as layout authority.

2) Landscape phone safety
- Touch-first behavior wins when input is coarse.
- Preserve bottom navigation on coarse pointer touch contexts.

3) Narrow desktop windows
- Degrade to `rail`, not `touch`.
- Keep desktop interaction patterns while reducing density.

4) Composer continuity
- Composer is shell infrastructure, not route-level UI.
- Resizing, rotating, and folding must not lose draft state or push composer offscreen.

5) Search behavior by surface
- expanded: persistent search affordance
- rail: icon plus floating reveal
- touch: overlay search

6) Multi-pane future safety
- never hardcode single-column assumptions
- keep detail surface contracts adaptable for future split views

## Transition Rules

Surface transitions must be predictable, continuous, and non-destructive.

Preferred transition:
- expanded sidebar -> rail sidebar -> bottom navigation

Avoid abrupt model swaps where the user loses orientation.

## Implementation Guidance

- Never detect "tablet" or "foldable" as product logic.
- Prefer spatial and interaction signals:
  - width breakpoints
  - pointer/hover capability
- Preserve context first, then reduce density.
- Never hide core navigation randomly to satisfy a breakpoint.
