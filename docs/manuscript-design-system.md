# Design System Strategy: The Manuscript Modernist

## 1. Overview & Creative North Star
The Creative North Star for this design system is **"The Digital Curator."** 

This system rejects the frantic, high-density layouts of modern social media in favor of the rhythmic, spacious cadence of a premium literary journal. We are moving away from "web app" aesthetics and toward "manuscript" tactility. To break the "template" look, we employ **Intentional Asymmetry**: long-form text may be offset to the right, leaving generous, "marginalia-style" whitespace on the left. We utilize **Overlapping Layers** where images or pull-quotes slightly break the container bounds, suggesting a physical stack of fine papers rather than a flat digital screen.

## 2. Colors & Surface Architecture
Our palette is rooted in the warmth of high-grade paper and the earthiness of terracotta ink.

### The "No-Line" Rule
Standard 1px borders are strictly prohibited for sectioning. Structural definition must be achieved through **Tonal Shifts**. To separate a sidebar from a main feed, transition from `surface` (#FFFFFF) to `surface-container-low` (#F4F4F0). If a boundary feels "lost," increase the spacing rather than adding a stroke.

### Surface Hierarchy & Nesting
Treat the interface as a physical desk.
- **Base Layer:** `background` (#FAF9F5) — The desk itself.
- **Secondary Layer:** `surface-container-low` (#F4F4F0) — Large structural areas or sections.
- **Active Layer:** `surface-container-lowest` (#FFFFFF) — The "Paper." Use this for cards and reading panes to create a natural, soft lift.

### The Glass & Gradient Rule
For floating elements (like a navigation bar or a "Quick Note" modal), use **Glassmorphism**. Apply `surface-container-lowest` at 85% opacity with a `24px` backdrop-blur. To give our CTAs "soul," use a subtle linear gradient on `primary` buttons, transitioning from `primary` (#A22D21) at the top left to `primary-container` (#C44536) at the bottom right.

## 3. Typography: Editorial Authority
The hierarchy is designed to mirror a printed monograph. 

*   **Display & Headlines (Newsreader):** These are our "Voice." With tight tracking (-0.02em), they feel dense, authoritative, and ink-heavy. Use `display-lg` for essay titles to command immediate focus.
*   **Body (Newsreader):** While the UI uses Raleway, the *content* lives in Newsreader. It is optimized for long-form immersion, providing the "unhurried" feel requested.
*   **Labels & UI (Work Sans):** These are our "Tools." Semibold weights with wide tracking (0.04em) ensure that even at small sizes (`label-sm`), the UI remains legible and sophisticated without competing with the serif narrative.

## 4. Elevation & Depth
We eschew the "material" drop-shadow in favor of **Ambient Light Layering.**

*   **The Layering Principle:** Depth is achieved by stacking. A `surface-container-highest` (#E3E2DF) element should only exist atop a `surface-container` (#EFEEEA) base. This creates a "recessed" or "elevated" effect through color math alone.
*   **Ambient Shadows:** When a floating state is unavoidable (e.g., a dropdown), use a "Whisper Shadow": `0 12px 40px rgba(27, 28, 26, 0.05)`. The shadow color is a tinted version of `on-surface`, never a neutral grey.
*   **The "Ghost Border":** For inputs or cards requiring high definition, use a `1px` stroke of `outline-variant` at **15% opacity**. It should be felt, not seen.

## 5. Components

### Buttons
*   **Primary:** Pill-shaped (`9999px`), `primary` gradient fill, `on-primary` text.
*   **Secondary:** Pill-shaped, `surface-container-high` fill. No border.
*   **Tertiary:** Text only in `primary`, Semibold Work Sans, 0.04em tracking.

### Cards
*   **The Manuscript Card:** `18px` radius. Background: `surface-container-lowest`. No border. Padding should be compact (e.g., normal spacing level) to allow the serif type to breathe.

### Input Fields
*   **Editorial Inputs:** `12px` radius. Background: `surface-container-low`. On focus, transition background to `surface-container-lowest` with a `Ghost Border`.

### Lists & Navigation
*   **The "No-Divider" Rule:** Forbid the use of horizontal rules (`<hr>`). Use compact vertical whitespace or a subtle background shift between list items.
*   **The Marginalia Sidebar:** Contextual actions should appear in the margins, using `label-md` typography to distinguish them from the main story.

### Specialized Component: The "Reading Progress" Rail
A vertical 2px line in `primary-fixed-dim` that sits in the left margin, growing as the user scrolls. It provides a sense of place without cluttering the "Paper" surface.

## 6. Do's and Don'ts

### Do:
*   **Embrace the Gutter:** Use oversized margins. If it feels like "too much" white space, it’s likely just right.
*   **Use Tonal Transitions:** Define areas by moving from #FAF9F5 to #F4F4F0.
*   **Tighten Serif Kerning:** Ensure Newsreader headings feel like a single cohesive block of ink.

### Don't:
*   **Don't use Solid Blacks:** Use `on-surface` (#1B1C1A) for text to maintain the "charcoal on cream" warmth.
*   **Don't use Box Shadows on everything:** Reserve elevation for elements that truly "float" (modals, tooltips).
*   **Don't use 1px Dividers:** They shatter the manuscript illusion. Use space or tonal blocks instead.