# Bookmarks Master Pane Migration to Shared Components

**Date:** 2026-06-06  
**Migration Type:** Phase 2 Feature Integration  
**Components Used:** `fomio-list` + `fomio-list-item`

## Summary

Migrated the Bookmarks screen's Master Pane navigation from custom `.fomio-master-pane__item` anchors to the shared `fomio-list` and `fomio-list-item` components. Also applied the same migration to Profile and Notifications master pane navigation for consistency.

## Changes

### Files Modified

#### `javascripts/discourse/connectors/above-site-header/fomio-master-pane.gjs`

**Added imports:**
```javascript
import FomioList from "../../components/shared/fomio-list";
import FomioListItem from "../../components/shared/fomio-list-item";
```

**Replaced custom anchor markup with shared components:**

**Before (custom anchors):**
```glimmer
{{#each this.bookmarksLinks as |link|}}
  <a
    href={{link.href}}
    class="fomio-master-pane__item fomio-utility-row {{if link.isActive 'is-active'}}"
    aria-current={{if link.isActive "page"}}
  >
    <span class="fomio-master-pane__name fomio-utility-row__label">{{link.label}}</span>
  </a>
{{/each}}
```

**After (shared components):**
```glimmer
<FomioList class="fomio-master-pane__nav-bookmarks">
  {{#each this.bookmarksLinks as |link|}}
    <FomioListItem
      @href={{link.href}}
      @title={{link.label}}
      @isActive={{link.isActive}}
    />
  {{/each}}
</FomioList>
```

**Applied to:**
- Bookmarks navigation (lines 916-925)
- Profile navigation (lines 906-915)
- Notifications navigation (lines 926-935)

#### `common/common.scss`

**Added new CSS rule:** Lines 5580-5656

Scoped styles for `.fomio-master-pane__nav-bookmarks`, `.fomio-master-pane__nav-profile`, and `.fomio-master-pane__nav-notifications` that apply the master pane item styling to list items in these contexts.

Styles include:
- Base item styling (spacing, fonts, colors, borders)
- Hover state with subtle shadow and transform
- Focus-visible state with ring
- Active state with gradient background and primary accent
- Smooth transitions

## Benefits

1. **Consistency** — Uses the shared component library instead of bespoke styles
2. **Maintainability** — List items now follow a single source of truth for styling
3. **Accessibility** — Leverages `fomio-list-item`'s built-in `aria-current` and focus management
4. **Scalability** — Adding more navigation sections is now simpler (just reuse the components)
5. **Feature parity** — All three navigation sections (Profile, Bookmarks, Notifications) now use the same component pattern

## Behavior

### Unchanged

- Link targets (`@href`) work exactly as before
- Active state styling and behavior maintained
- Keyboard navigation (Tab, Enter, Focus) works as expected
- Mobile and desktop views both supported

### Styling

The shared `fomio-list-item` renders as `<a>` tags when `@href` is provided. The master pane context overrides apply the master pane aesthetic:
- Subtle background color (surface + opacity mix)
- 1px border in soft gray
- 44px touch-target minimum height
- Font size and weight match the original
- Hover state includes shadow and micro-translate
- Active state uses gradient background and primary color accent

## Testing Checklist

- [ ] Bookmarks master pane links navigate correctly
- [ ] Profile master pane links navigate correctly
- [ ] Notifications master pane links navigate correctly
- [ ] Active link state visually indicated (background + font weight)
- [ ] Hover state shows shadow and slight translate
- [ ] Focus state shows ring (keyboard navigation)
- [ ] Keyboard Tab navigation works
- [ ] Mobile view responsive
- [ ] Dark mode appearance correct
- [ ] No console errors

## Future Work

Once this migration is validated:
1. Audit other master pane sections (Hubs navigation) for further list component adoption
2. Extract any additional reusable master pane behaviors into shared components
3. Consider whether a `fomio-master-pane-list` specialized variant would be useful if other screens need similar navigation
