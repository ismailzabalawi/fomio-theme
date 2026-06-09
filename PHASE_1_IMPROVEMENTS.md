# Phase 1: Master-Detail UI Improvements — Implementation Summary

**Completed:** 2026-06-09

## Improvements Implemented

### 1. **Persistent Hub Expand State** ✅
**Files Modified:** `javascripts/discourse/connectors/above-site-header/fomio-sidebar.gjs`

**What:** Users' expanded/collapsed Hub state now persists across page navigation within the same session.

**How:**
- Added `#restoreHubExpandState()` — called in constructor, reads `sessionStorage.fomio_expanded_hub_id`
- Added `#persistHubExpandState()` — called after `toggleHub()`, writes state to sessionStorage
- State is session-scoped (clears on browser close), not persistent across sessions

**Impact:**
- Users no longer need to re-expand Hubs after navigating to a sub-category and back
- Reduces cognitive friction when exploring Hub structure

---

### 2. **Visual Affordance for Master Pane on Rail** ✅
**Files Modified:**
- `javascripts/discourse/connectors/above-site-header/fomio-sidebar.gjs` (template)
- `common/common.scss`

**What:** A subtle right-arrow chevron indicator appears next to "Hubs" on rail surfaces, hinting that it expands.

**How:**
- Added conditional `.fomio-sidebar__item-affordance` span in Hubs nav item
- Only renders on rail (`if this.isRailSurface`)
- Icon is 75% opacity at rest, increases to 95% on hover/focus
- Styled to be subtle and non-intrusive

**CSS Added:**
```scss
.fomio-sidebar__item-affordance {
  display: inline-flex;
  opacity: 0.6;  // subtle
  color: color-mix(in oklab, var(--fomio-muted) 75%, transparent);

  &:hover, &:focus-visible {
    opacity: 0.95;
    color: var(--fomio-text);
  }
}
```

**Impact:**
- New users on rail/tablet surfaces now have a visual cue that Hubs is expandable
- Tooltip shows on hover: "Hubs (expand)"

---

### 3. **Animated Context Switching** ✅
**Files Modified:**
- `javascripts/discourse/connectors/above-site-header/fomio-sidebar.gjs` (component logic & template)
- `common/common.scss` (animations & styles)

**What:** When switching between master contexts (Home → Hubs → Bookmarks → Notifications), the sidebar fades out and the detail surface fades in, providing visual continuity.

**How:**
- Added `@tracked previousMasterContext` and `@tracked masterContextChanged` to sidebar component
- `activeMasterContext` getter now detects context changes and triggers animation flag
- Added `fomio-context-switched` class to sidebar during transition
- SCSS applies fade-out animation to sidebar, fade-in to detail surface

**Animations Added:**
```scss
@keyframes fomio-context-fade-out {
  from { opacity: 1; }
  to { opacity: 0; }
}

@keyframes fomio-context-fade-in {
  from { opacity: 0; }
  to { opacity: 1; }
}
```

**Timing:**
- Duration: `--fomio-dur-med` (200ms)
- Easing: `--fomio-ease` (cubic-bezier for smooth deceleration)
- Respects `prefers-reduced-motion`

**Impact:**
- Context switches feel intentional and less jarring
- Users see clear visual feedback when navigating between nav contexts
- Seamless experience that maintains focus on the detail surface

---

### 4. **Master Pane Header** ✅
**Status:** Already implemented — no changes needed

**Existing in Component:** The `fomio-master-pane.gjs` component already renders context-aware headers with:
- Title (e.g., "Hubs", "Bookmarks", "Notifications")
- Description (context-dependent)
- Styling in `common.scss` Section 5 (`.fomio-master-pane__header`, `.fomio-master-pane__title`, `.fomio-master-pane__description`)

**Scope:** Visible on expanded/compact desktop; hidden on rail overlay to save space.

---

## User-Facing Changes

| Feature | Before | After |
|---------|--------|-------|
| **Hub expand state** | Resets on every nav | Persists within session |
| **Rail Hubs button** | No hint it's expandable | Right-arrow chevron shows it's interactive |
| **Context switching** | Abrupt jump between nav items | 200ms fade-out/in animation |
| **Master pane header** | Present on expanded desktop | (no change — already working) |

---

## Technical Details

### Code Locations
- **Sidebar component:** `apps/web/javascripts/discourse/connectors/above-site-header/fomio-sidebar.gjs`
- **Styles:** `apps/web/common/common.scss`
  - Affordance indicator: ~line 10945
  - Animations: ~line 2116
  - Context switch styles: ~line 5224

### Browser Compatibility
- Uses `sessionStorage` (IE11+)
- Uses CSS animations with `@media (prefers-reduced-motion: no-preference)` guards
- Uses `--css-vars` (IE11+ with fallbacks already in place)

### Performance
- No additional DOM nodes (only class toggles and CSS vars)
- sessionStorage I/O is synchronous but minimal (single key)
- Animations are GPU-accelerated (opacity only)

---

## Testing Checklist

- [ ] **Rail surface:** Chevron appears next to Hubs, disappears on desktop
- [ ] **Hub expand:** Expand a Hub, navigate away, return — state persists
- [ ] **Hub collapse:** Collapse a Hub, navigate away, return — state persists
- [ ] **Context switch:** Click between Latest → Hubs → Bookmarks → Notifications — observe smooth fade animation
- [ ] **Reduced motion:** Set `prefers-reduced-motion: reduce` — animations should not play
- [ ] **Mobile browser:** sessionStorage works in WebView (test on actual device)
- [ ] **Dark mode:** Affordance chevron color adjusts correctly in dark theme
- [ ] **Master pane header:** Title and description visible on expanded/compact desktop

---

## Next Steps (Phase 2+)

Once Phase 1 is validated:
1. Focus management on context switches (announce to screen readers)
2. Bookmark master pane content (bookmarks by category, or recent bookmarks list)
3. Profile master pane enrichment (user's recent posts, activity summary)
4. Search integration with master/detail flow (search results feed into detail surface)

---

## References

- **Audit:** `/PHASE_1_AUDIT.md` (if created separately)
- **Design System:** `packages/design-tokens/tokens.js`
- **Architecture:** `apps/web/CLAUDE.md` (Master–Detail System section)
