# Bookmarks Search Form Migration

**Date:** 2026-06-06  
**Component:** Bookmark search form on `/u/:username/activity/bookmarks`  
**Approach:** Connector-based replacement using `fomio-search-input` + `fomio-button`

## Summary

Replaced the native Discourse bookmark search form with a Fomio-styled search form using shared components. The functionality remains identical while the UI now matches the Fomio design system.

## Implementation

### New Files

**`javascripts/discourse/connectors/above-user-bookmarks/fomio-bookmark-search.gjs`**

A connector that:
1. Injects at the `above-user-bookmarks` plugin outlet
2. Only renders on the bookmarks page (`/activity/bookmarks` or `/bookmarks` routes)
3. Provides a search form composed of:
   - `FomioSearchInput` — Search field with magnifying glass icon
   - `FomioButton` — Primary search button with icon
4. Handles:
   - Text input changes → updates controller's `searchTerm`
   - Enter key → triggers search
   - Button click → triggers search

### Modified Files

**`common/common.scss`**

Added scoped styles under `.user-activity-bookmarks-page`:
- Hides native `.bookmark-search-form` with `display: none`
- Styles `.fomio-bookmark-search-form` as a flex container
- Input takes full width, button stays fixed width
- Proper spacing between input and button

## Behavior

**Input Behavior:**
- User types in search field → `controller.searchTerm` updates in real-time
- Press Enter → search executes
- Click search button → search executes
- Same search results as before (native search logic untouched)

**Visual:**
- Search input uses `fomio-search-input` styling (blue border on focus, magnifying glass icon)
- Button is primary red (Fomio primary color)
- Both aligned vertically with gap between them
- Matches master pane aesthetic

## Testing Checklist

- [ ] Bookmarks page loads without errors
- [ ] Search form visible and styled correctly
- [ ] Type in search field → results filter
- [ ] Press Enter in search field → search executes
- [ ] Click search button → search executes
- [ ] Search results display correctly
- [ ] Clear search → all bookmarks show again
- [ ] Focus state shows on input and button
- [ ] Keyboard Tab navigation works
- [ ] Mobile view responsive (input + button stack or shrink appropriately)
- [ ] Dark mode appearance correct
- [ ] No console errors

## Notes

- The connector uses the `above-user-bookmarks` outlet to inject the form
- The native Discourse form is hidden, not removed, preserving DOM stability
- Event handlers directly call `controller.search()` and update `controller.searchTerm`
- Component is only rendered on bookmarks pages via route check
- Button includes search icon for visual context (matches common search UX)

## Next Steps (Phase 2 Work)

After QA:
1. Migrate "Select All / Clear All" buttons to shared components
2. Refactor bookmark list table structure
3. Test across all surfaces (desktop, tablet, mobile)
4. Validate dark mode appearance
