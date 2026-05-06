# Fomio Rich-Editor Composer — Reference

This document describes the current composer implementation in `apps/web` after the reset away from the custom block-shell experiment.

The live composer is now the native Discourse composer, restyled by the Fomio theme and extended through supported theme APIs.

## Current Model

The current stack is:

1. Discourse composer remains the source of truth.
2. The theme forces the composer into rich-editor mode.
3. The theme hides the fixed toolbar in the rich editor.
4. A custom ProseMirror extension shows a floating selection toolbar for text selections.
5. The rest of publish, drafts, uploads, validation, permissions, preview, mentions, links, and moderation remain core Discourse behavior.

## Files That Matter

### Behavior

- [apps/web/javascripts/discourse/api-initializers/fomio-rich-editor-toolbar.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/api-initializers/fomio-rich-editor-toolbar.gjs)
  - Forces the composer to rich-editor mode via `composer-force-editor-mode`
  - Overrides the rich-editor placeholder via `composer-editor-reply-placeholder`
  - Registers the floating-toolbar rich-editor extension

- [apps/web/javascripts/discourse/lib/fomio-selection-toolbar-extension.js](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/lib/fomio-selection-toolbar-extension.js)
  - ProseMirror plugin for floating selection UI
  - Shows a compact toolbar on non-empty text selections
  - Buttons: `bold`, `italic`, `link`
  - Uses core `ToolbarBase`, `ToolbarButtons`, and `UpsertHyperlink`

- [apps/web/javascripts/discourse/connectors/before-composer-fields/fomio-fullscreen-composer-fields.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/connectors/before-composer-fields/fomio-fullscreen-composer-fields.gjs)
  - Restores title/category/tags fields when the composer enters fullscreen
  - Uses the `before-composer-fields` outlet because core hides these fields when `viewFullscreen` is true

- [apps/web/javascripts/discourse/connectors/above-site-header/fomio-composer.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/connectors/above-site-header/fomio-composer.gjs)
  - The old full-screen shell connector now renders nothing
  - This file is intentionally neutralized so native Discourse composer UI is used

### Styling

- [apps/web/common/common.scss](/Users/ismailzabalawi/Projects/Fomio/apps/web/common/common.scss)
  - Desktop and shared composer surface styling
  - Border, background, field sizing, fullscreen field spacing
  - Hides `composer-action-title`
  - Hides the stock top rich-editor toolbar
  - Styles the floating selection toolbar
  - Aligns placeholder color and editor borders with theme tokens

- [apps/web/mobile/mobile.scss](/Users/ismailzabalawi/Projects/Fomio/apps/web/mobile/mobile.scss)
  - Mobile composer layout overrides
  - Stacks title/category/tags cleanly
  - Reflows submit row into a compact mobile layout

### Strings

- [apps/web/locales/en.yml](/Users/ismailzabalawi/Projects/Fomio/apps/web/locales/en.yml)
  - Theme-owned composer strings
  - Rich-editor placeholder currently: `Write your byte here.`

## Discourse Extension Points In Use

### Transformer: Force Rich Editor

The theme uses the Discourse value transformer:

- `composer-force-editor-mode`

This is applied from core in:

- [discourse/frontend/discourse/app/components/composer-editor.gjs](/Users/ismailzabalawi/Projects/Fomio/discourse/frontend/discourse/app/components/composer-editor.gjs:1086)

The theme returns:

- `USER_OPTION_COMPOSITION_MODES.rich`

This means:

- the markdown textarea path is out of scope
- the editor mode toggle is suppressed by core because `forceEditorMode` is set

### Transformer: Placeholder Override

The theme uses:

- `composer-editor-reply-placeholder`

Core computes the placeholder key in:

- [discourse/frontend/discourse/app/components/composer-editor.gjs](/Users/ismailzabalawi/Projects/Fomio/discourse/frontend/discourse/app/components/composer-editor.gjs:143)

The theme returns its own locale key:

- `themePrefix("composer.rich_placeholder")`

### Rich Editor Extension

The theme registers a ProseMirror extension through:

- `api.registerRichEditorExtension(...)`

Core API entry:

- [discourse/frontend/discourse/app/lib/plugin-api.gjs](/Users/ismailzabalawi/Projects/Fomio/discourse/frontend/discourse/app/lib/plugin-api.gjs:3342)

Rich-editor extension registry:

- [discourse/frontend/discourse/app/lib/composer/rich-editor-extensions.js](/Users/ismailzabalawi/Projects/Fomio/discourse/frontend/discourse/app/lib/composer/rich-editor-extensions.js:143)

### Fullscreen Field Reinsertion

Core intentionally hides the title/category/tags block in fullscreen:

- [discourse/frontend/discourse/app/components/composer-container.gjs](/Users/ismailzabalawi/Projects/Fomio/discourse/frontend/discourse/app/components/composer-container.gjs:285)

The theme restores those controls through the outlet:

- `before-composer-fields`

## Floating Toolbar Behavior

### What It Does

The floating toolbar appears only when:

- the active editor is inside `#reply-control`
- the editor has focus
- the selection is a non-empty `TextSelection`
- the selected text is not effectively blank

It hides when:

- the selection collapses
- the editor loses focus
- the selection is not plain text

### Buttons

The current v1 toolbar includes:

- `bold`
- `italic`
- `link`

`bold` and `italic` use ProseMirror mark toggles.

`link` opens core Discourse `UpsertHyperlink`:

- [discourse/frontend/discourse/app/components/modal/upsert-hyperlink.gjs](/Users/ismailzabalawi/Projects/Fomio/discourse/frontend/discourse/app/components/modal/upsert-hyperlink.gjs)

### Positioning

The toolbar is positioned from the current ProseMirror selection using:

- `view.coordsAtPos(selection.from)`
- `view.coordsAtPos(selection.to)`

The theme builds a virtual trigger rect and passes it to Discourse Float Kit menu rendering.

### Why We Use Core Primitives

The toolbar deliberately reuses:

- `ToolbarBase`
- `ToolbarButtons`
- `UpsertHyperlink`
- Discourse Float Kit `menu.show(...)`

This avoids inventing a second formatting system or manually mutating composer state.

## Current Styling Rules

### Composer Shell

The native composer frame is themed under:

- `body.fomio-sidebar-active #reply-control`

Key choices:

- use theme background and border tokens
- keep Discourse structure intact
- restyle, do not replace

### Hidden Elements

The theme currently hides:

- `.composer-action-title`
- `.d-editor-button-bar__wrap` for rich editor

The first removes the “Create a new topic” header block.
The second removes the fixed top toolbar because the floating toolbar replaces it for rich text formatting.

### Input and Editor Sizing

Current shared rules normalize:

- title field
- category field
- tags field
- editor panel inset
- editor placeholder color

This was necessary because default Discourse field metrics and Fomio typography caused vertical misalignment.

### Mobile Footer

On mobile, the composer footer is reflowed into:

- left: upload action
- right: primary action group

This is done in `apps/web/mobile/mobile.scss` because core mobile composer layout and the Fomio button styling were fighting each other.

## Known Constraints

### Fullscreen Composer Is Not Symmetric With Open Composer

Core Discourse treats fullscreen as a different composer state, not a pure size change.

Important consequence:

- title/category/tags are removed from core markup in fullscreen

That is why the theme has to restore them through an outlet connector.

### The Old Block Composer Is Still In The Repo

The previous custom shell and block editor files still exist in the repository, but they are not the active composer path now.

Relevant old files:

- [apps/web/javascripts/discourse/components/fomio-block-editor.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/fomio-block-editor.gjs)
- [apps/web/javascripts/discourse/connectors/above-site-header/fomio-composer.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/connectors/above-site-header/fomio-composer.gjs)

The connector is intentionally disabled. The old component remains as historical code and should not be treated as current behavior.

### Rich Editor Only

The current implementation assumes:

- no markdown textarea support
- no toolbar parity for markdown mode
- no custom block serialization path

If markdown mode is ever reintroduced, the current floating-toolbar implementation is not enough by itself.

## Failure Modes We Hit

These are worth documenting because they are easy to repeat.

### 1. Direct ProseMirror Package Imports In Theme Code

Bad:

- `import { TextSelection } from "prosemirror-state"`

Why it failed:

- Discourse theme bundles do not resolve raw package imports the same way app/core code does

Correct approach:

- use the ProseMirror classes provided through the rich-editor extension params, for example `pmState.TextSelection`

### 2. Strict-Mode GJS Template Helpers Must Be Imported

Bad:

- using `{{hash ...}}` in GJS template scope without importing `hash`

Why it failed:

- strict-mode templates only see values explicitly in scope

Correct approach:

- `import { hash } from "@ember/helper";`

### 3. Plugin Init Failures Cascade Into Editor Breakage

When the floating-toolbar extension throws during editor setup:

- the ProseMirror editor can fail to finish initializing
- typing can stop working
- `updateState` errors appear later as secondary failures

If typing suddenly dies, check theme JS compile/runtime errors first before debugging input behavior.

## Recommended Verification Checklist

When changing composer behavior, verify all of the following:

1. Open normal composer and confirm title, category, and editor all render.
2. Open fullscreen composer and confirm title/category/tags are still visible.
3. Select text in rich editor and confirm floating toolbar appears.
4. Test `bold`, `italic`, and `link`.
5. Confirm the fixed top toolbar is hidden.
6. Confirm publish still works.
7. Confirm draft auto-save still works.
8. Confirm uploads still work from the mobile and desktop footer/button path.
9. Confirm the mobile submit row still aligns after any button styling changes.

## Current Scope

The current implementation is intentionally limited.

Included now:

- rich-editor-only composer
- floating selection toolbar
- fullscreen title/category/tags restoration
- Fomio surface styling for native Discourse composer

Not included now:

- markdown-mode toolbar support
- custom block composer shell
- custom publish pipeline
- custom upload pipeline
- custom serializer

## Suggested Next Docs

If this composer work continues, the next useful docs would be:

1. A visual token map for composer-specific colors, radii, and spacing.
2. A mobile composer interaction guide with screenshots.
3. A “remove old shell” cleanup note once the repo no longer needs the historical block-editor files.
