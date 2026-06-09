# Bookmarks Bulk Select Buttons Migration

**Date:** 2026-06-06  
**Component:** Select All / Clear All buttons in bookmark list  
**Approach:** Connector-based replacement with Phosphorus icons

## Summary

Replaced the native Discourse bulk select buttons ("Select All" / "Clear All") with Fomio-styled buttons using `fomio-button` components and Phosphorus icons.

## Implementation

### New Files

**`javascripts/discourse/connectors/bookmark-list-table-header/fomio-bulk-select-buttons.gjs`**

A connector that:
1. Injects at the `bookmark-list-table-header` outlet
2. Renders only when there are selected bookmarks (`bulkSelectHelper.selected.length > 0`)
3. Uses `fomio-button` with secondary variant and Phosphorus icons:
   - **Select All** — `fomio-ph-checks` icon
   - **Clear All** — `fomio-ph-x` icon
4. Calls the bookmark-list component's `selectAll()` and `clearAll()` actions

### Modified Files

**`common/common.scss`**

Added styles under `.user-activity-bookmarks-page`:
- Hide native `.bulk-select-all` and `.bulk-clear-all` buttons
- Style `.fomio-bulk-select-buttons` as flex container
- Proper spacing between buttons

## Behavior

**Unchanged:**
- Bulk selection still works the same way
- Actions are passed directly to the bookmark list component
- Only shows when there are selected items

**Changed:**
- Visual appearance matches Fomio design system
- Uses Phosphorus icons (`ph-checks`, `ph-x`) instead of Discourse icons
- Secondary button variant (less prominent than primary)

## Icon Mapping

| Action | Phosphorus Icon | Meaning |
|--------|-----------------|---------|
| Select All | `fomio-ph-checks` | All items selected (checkmark) |
| Clear All | `fomio-ph-x` | Remove all selections (X) |

## Testing Checklist

- [ ] Buttons appear in the bookmark list header
- [ ] "Select All" button has checkmark icon
- [ ] "Clear All" button has X icon
- [ ] Click "Select All" — all bookmarks become selected
- [ ] Click "Clear All" — all selections removed
- [ ] Buttons only show when items are selected
- [ ] Button styling matches Fomio design
- [ ] Icons are properly centered and sized
- [ ] Mobile view responsive
- [ ] Dark mode appearance correct
- [ ] No console errors

## Next Steps (Phase 3 Work)

After QA:
1. Refactor bookmark list table structure to use shared components
2. Test across all surfaces (desktop, tablet, mobile)
3. Validate dark mode appearance
