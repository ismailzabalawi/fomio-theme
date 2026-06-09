# Apps/Web Phase 1 Shared Components Audit

Purpose: turn the finished Layer 1, Layer 2, and Layer 3 design-system pages into an implementation checklist for `apps/web`.

This document treats the design-system HTML artifacts as the contract and the current shared Glimmer components under `apps/web/javascripts/discourse/components/shared/` as the starting point.

## Rules

- Build component contracts first, feature integrations second.
- Shared component APIs live in `components/shared/`.
- Discourse outlet wiring lives in `api-initializers/` and connectors.
- `apps/web/common/common.scss` is the primary style host.
- `apps/web/desktop/desktop.scss` and `apps/web/mobile/mobile.scss` should only carry renderer-specific overrides.

## Source Of Truth

- Layer 1 `Controls`
  - `/Users/ismailzabalawi/Projects/Fomio/artifacts/fomio-design-system-3/Fomio Buttons & Inputs.html`
- Layer 2 `Content`
  - `/Users/ismailzabalawi/Projects/Fomio/artifacts/fomio-design-system-3/Fomio Content Layer.html`
- Layer 3 `Interaction`
  - User-approved `Fomio Interaction Layer v2.html` from the later design-system archive

## Token / Style Host

- Primary style host:
  - [common.scss](/Users/ismailzabalawi/Projects/Fomio/apps/web/common/common.scss)
- Desktop-only overrides:
  - [desktop.scss](/Users/ismailzabalawi/Projects/Fomio/apps/web/desktop/desktop.scss)
- Mobile-only overrides:
  - [mobile.scss](/Users/ismailzabalawi/Projects/Fomio/apps/web/mobile/mobile.scss)

## Current Shared Components

Shared component directory:
- [components/shared](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared)

Current inventory:
- `fomio-avatar.gjs`
- `fomio-badge.gjs`
- `fomio-button.gjs`
- `fomio-byte-card.gjs`
- `fomio-card.gjs`
- `fomio-command-palette.gjs`
- `fomio-composer-category-picker.gjs`
- `fomio-dropdown.gjs`
- `fomio-ephemeral-sheet.gjs`
- `fomio-empty-state.gjs`
- `fomio-identity.gjs`
- `fomio-input.gjs`
- `fomio-list.gjs`
- `fomio-list-item.gjs`
- `fomio-list-section-header.gjs`
- `fomio-list-separator.gjs`
- `fomio-meta-row.gjs`
- `fomio-modal.gjs`
- `fomio-notifications-menu.gjs`
- `fomio-radio-group.gjs`
- `fomio-ph-icon.gjs`
- `fomio-search-input.gjs`
- `fomio-search-sheet.gjs`
- `fomio-segmented-control.gjs`
- `fomio-select.gjs`
- `fomio-textarea.gjs`
- `fomio-toast.gjs`
- `fomio-tabs.gjs`

## Audit Status Legend

- `Keep`: component belongs in the shared system as-is conceptually.
- `Normalize`: component belongs in the shared system but API, naming, or behavior still needs cleanup.
- `Extract`: useful shared behavior is embedded in a feature component and should be pulled into a generic shared component.
- `Defer`: valid, but not required for Phase 1.

## Layer 1: Controls

### 1. Button

- File:
  - [fomio-button.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-button.gjs)
- Status:
  - `Keep`
- Why:
  - Already maps to the Layer 1 contract and uses shared control class helpers.
- Phase 1 tasks:
  - Verify props match the canonical vocabulary: `variant`, `size`, `disabled`, `loading`, `leadingIcon`, `trailingIcon`.
  - Confirm loading state is visually represented in SCSS, not just logically disabled.
  - Confirm icon spacing and icon-only button styles exist in `common.scss`.

### 2. Input / Search Input

- File:
  - [fomio-input.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-input.gjs)
  - [fomio-search-input.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-search-input.gjs)
- Status:
  - `Keep` for `fomio-input.gjs`
  - `Normalize` for `fomio-search-input.gjs`
- Why:
  - A canonical generic input component now exists; search input remains the Layer 1 `variant="search"` specialization.
- Phase 1 tasks:
  - Keep `fomio-search-input.gjs` as the `variant="search"` specialization.
  - Normalize `onInput` and `onChange` behavior with Layer 1 conventions.
  - Confirm search input supports the same `label`, `hint`, and `error` contract as generic input.

### 3. Select

- File:
  - [fomio-select.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-select.gjs)
- Status:
  - `Keep`
- Why:
  - Already exists and fits Layer 1.
- Phase 1 tasks:
  - Confirm `label`, `hint`, `error`, `placeholder`, `leadingIcon`, `trailingIcon`, `disabled`, and loading behavior match the design-system contract.
  - Decide whether this remains native-select based for the real theme or if a custom dropdown belongs separately in Layer 3.

### 4. Textarea

- File:
  - [fomio-textarea.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-textarea.gjs)
- Status:
  - `Keep`
- Why:
  - Already exists and fits Layer 1.
- Phase 1 tasks:
  - Align invalid/error API to the same vocabulary used by `fomio-select.gjs` and the future generic input component.
  - Confirm serif body styling and hint/error presentation match the Layer 1 page.

## Layer 2: Content

### 5. Avatar

- File:
  - [fomio-avatar.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-avatar.gjs)
- Status:
  - `Keep`
- Why:
  - Strong Layer 2 fit and already supports size/palette/badge concepts.
- Phase 1 tasks:
  - Confirm supported sizes and palette names match the finalized Layer 2 catalog.
  - Confirm online/badge states map cleanly to the approved `Avatar` family.

### 6. Identity

- File:
  - [fomio-identity.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-identity.gjs)
- Status:
  - `Normalize`
- Why:
  - Belongs in Layer 2, but should be documented as a composition of `Avatar` + text metadata rather than a one-off.
- Phase 1 tasks:
  - Normalize prop naming with the Layer 2 `MetaRow` and author display rules.
  - Confirm it stays display-only and does not absorb interaction logic.

### 7. Card

- Files:
  - [fomio-card.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-card.gjs)
  - [fomio-byte-card.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-byte-card.gjs)
- Status:
  - `Keep` for `fomio-card.gjs`
  - `Normalize` for `fomio-byte-card.gjs`
- Why:
  - `fomio-card.gjs` is a generic container; `fomio-byte-card.gjs` is a domain composition that should consume Layer 2 primitives instead of defining them.
- Phase 1 tasks:
  - Keep `fomio-card.gjs` as the canonical container.
  - Audit `fomio-byte-card.gjs` to ensure it composes `Card`, `Avatar`, `MetaRow`, and tag styles rather than re-inventing them.

### 8. List / ListItem / Section Header / Separator

- Files:
  - [fomio-list.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-list.gjs)
  - [fomio-list-item.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-list-item.gjs)
  - [fomio-list-section-header.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-list-section-header.gjs)
  - [fomio-list-separator.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-list-separator.gjs)
- Status:
  - `Keep`
- Why:
  - These map directly to the finalized Layer 2 `ListItem` and `SectionHeader` families.
- Phase 1 tasks:
  - Verify `fomio-list-item.gjs` prop names for `title`, `subtitle`, `meta`, `leadingIcon`, and `trailingIcon`.
  - Confirm active/danger/disabled visual states remain display-oriented and do not take on overlay behavior.
  - Align `fomio-list-section-header.gjs` with the finalized Layer 2 `SectionHeader` family instead of a list-only naming constraint if needed.

### 9. Missing Layer 2 shared pieces

- Files:
  - [fomio-badge.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-badge.gjs)
  - [fomio-meta-row.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-meta-row.gjs)
  - [fomio-empty-state.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-empty-state.gjs)
- Status:
  - `Keep`
- Why:
  - These families now exist as clear shared wrappers and should become the default Layer 2 display primitives for feature UIs.
- Phase 1 tasks:
  - Rewire existing feature UIs to consume these wrappers instead of feature-local markup.
  - Audit naming consistency with the finalized Layer 2 HTML contract.

## Layer 3: Interaction

### 10. SegmentedControl

- File:
  - [fomio-segmented-control.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-segmented-control.gjs)
- Status:
  - `Keep`
- Why:
  - Direct match to finalized Layer 3 `Selection`.
- Phase 1 tasks:
  - Confirm API vocabulary uses `selectedKey` and `onSelect` semantics consistently, even if the internal arg names stay backward-compatible.
  - Confirm icon-only and disabled segment states are styled.

### 11. Search Sheet / Ephemeral Sheet

- Files:
  - [fomio-search-sheet.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-search-sheet.gjs)
  - [fomio-ephemeral-sheet.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-ephemeral-sheet.gjs)
- Status:
  - `Keep`
- Why:
  - These are valid Layer 3 `Overlay` / `Utility surface` primitives.
- Phase 1 tasks:
  - Normalize public API naming around `open`, `defaultOpen`, `onOpenChange`, `dismissible`, and `size`.
  - Decide whether `fomio-ephemeral-sheet.gjs` is the canonical web implementation for the Layer 3 `BottomSheet` family.

### 12. Notifications Menu

- File:
  - [fomio-notifications-menu.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-notifications-menu.gjs)
- Status:
  - `Normalize`
- Why:
  - Useful Layer 3 shell, but still strongly tied to Fomio notification data and desktop/mobile routing behavior.
- Phase 1 tasks:
  - Keep as a product shell for now.
  - Extract any reusable substructures into generic Layer 3 pieces:
    - tabs
    - grouped list shell
    - footer action row
  - Preserve product logic in this component instead of pushing it down into the generic interaction primitives.

### 13. Missing Layer 3 shared pieces

- Status:
  - `Covered`
- Why:
  - The finalized Layer 3 contract is now covered at the primitive level. The remaining work is feature adoption and API normalization.
- Phase 1 tasks:
  - Reuse these shared interaction components before adding new bespoke shells.

## Feature Adoption Status

- Files:
  - [fomio-composer-category-picker.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-composer-category-picker.gjs)
  - [fomio-notifications-menu.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-notifications-menu.gjs)
  - [fomio-mobile-search-palette.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-mobile-search-palette.gjs)
- Status:
  - `Adopted on shared primitives`
- Why:
  - These feature shells now consume the shared Layer 3 components and should be treated as reference adopters, not primitive-definition candidates.
- Ongoing cleanup:
  - Keep product data/loading logic local.
  - Avoid re-introducing custom interaction state that duplicates `Dropdown`, `Tabs`, or `CommandPalette`.

## Reviewed Feature Compositions

- [fomio-me-filter-chips.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-me-filter-chips.gjs)
  - Status:
    - `Resolved`
  - Decision:
    - Keep as a feature composition.
    - Use `fomio-segmented-control.gjs` as the underlying Layer 3 interaction surface.
  - Why:
    - The component owns feature behavior beyond selection UI: filter state, `document.body` syncing, lifecycle cleanup, and empty-state detection.

- [fomio-me-activity-nav.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-me-activity-nav.gjs)
  - Status:
    - `Resolved`
  - Decision:
    - Keep as a feature composition.
    - Do not force it into `Tabs` or `SegmentedControl`.
  - Why:
    - It is route navigation built on anchors, not an in-place selection control with local panels or button-only interaction.
  - Follow-up:
    - Treat this as evidence for a future shared `pill nav / tab links` primitive.

- [fomio-user-profile-summary.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-user-profile-summary.gjs)
  - Status:
    - `Resolved`
  - Decision:
    - Keep the feature boundary.
    - Improve it by composing existing shared Layer 1/2 pieces where they fit.
  - Why:
    - This is primarily a profile-specific composition of identity, facts, stats, actions, and expanded details rather than a primitive definition.

## Phase 1 Execution Order

1. Confirm shared control helpers and content helpers remain the canonical class-name generators:
   - `lib/fomio-control-classes`
   - `lib/fomio-content-classes`
   - `lib/fomio-interaction-classes`
2. Normalize existing Layer 1 components:
   - `Button`
   - generic `Input`
   - `SearchInput`
   - `Select`
   - `Textarea`
3. Normalize existing Layer 2 primitives:
   - `Avatar`
   - `Identity`
   - `Card`
   - `ListItem`
   - `ListSectionHeader`
4. Extract missing Layer 2 families:
   - `Badge/Tag`
   - `MetaRow`
   - `EmptyState`
5. Normalize existing Layer 3 primitives:
   - `SegmentedControl`
   - `Dropdown`
   - `Tabs`
   - `EphemeralSheet`
   - `Modal`
   - `RadioGroup`
   - `SearchSheet`
   - `Toast`
   - `CommandPalette`
6. Re-audit feature components so they consume the normalized primitives.

## Definition Of Done For Phase 1

- All Phase 1 shared components live under `components/shared/`.
- Their styles are owned primarily by `common.scss`.
- Feature components consume the shared APIs instead of re-declaring visuals inline.
- Layer boundaries are preserved:
  - Layer 1: controls
  - Layer 2: content display
  - Layer 3: interaction surfaces
- No new Discourse outlet-specific feature work is started until the above checklist is stable.
