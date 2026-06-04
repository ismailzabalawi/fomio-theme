# Fomio Composer — Native Surface Extraction

Scope: `apps/web` topic creation flow only.

This document extracts the parts of the create-topic experience that still render core Discourse UI or behavior, even though the outer composer shell is already restyled as Fomio.

## What Fomio Already Owns

The full-page create shell is already theme-owned:

- topbar via `before-composer-controls`
- fullscreen title/category/tags reinsertion via `before-composer-fields`
- right rail via `composer-after-composer-editor`
- status bar and hints via `composer-fields-below`
- editor canvas styling in [common.scss](/Users/ismailzabalawi/Projects/Fomio/apps/web/common/common.scss:15333)

Evidence:

- [fomio-composer-topbar.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/connectors/before-composer-controls/fomio-composer-topbar.gjs:1)
- [fomio-fullscreen-composer-fields.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/connectors/before-composer-fields/fomio-fullscreen-composer-fields.gjs:1)
- [composer-container.gjs](/Users/ismailzabalawi/Projects/Fomio/discourse/frontend/discourse/app/components/composer-container.gjs:263)

## Still Native In Create Topic

### 1. Title field logic and validation

The fullscreen connector reuses core `ComposerTitle`, not a Fomio title component.

Evidence:

- [fomio-fullscreen-composer-fields.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/connectors/before-composer-fields/fomio-fullscreen-composer-fields.gjs:24)
- [composer-title.gjs](/Users/ismailzabalawi/Projects/Fomio/discourse/frontend/discourse/app/components/composer-title.gjs:1)

What is still native:

- title validation rules
- title focus behavior
- featured-link auto-detection behavior
- title error presentation through `PopupInputTip`

Theme coverage today:

- input chrome is styled
- validation popover itself is not composer-specific themed

### 2. Category chooser dropdown

The Fomio connector reuses core `CategoryChooser`.

Evidence:

- [fomio-fullscreen-composer-fields.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/connectors/before-composer-fields/fomio-fullscreen-composer-fields.gjs:32)
- [composer-container.gjs](/Users/ismailzabalawi/Projects/Fomio/discourse/frontend/discourse/app/components/composer-container.gjs:321)

What is still native:

- chooser interaction model
- dropdown body
- result rows
- search/filter behavior
- empty/loading states

Theme coverage today:

- only the closed `.select-kit-header` is styled in the composer shell
- no composer-scoped styling was found for the chooser popup body/rows

### 3. Tag chooser dropdown and chip input

The Fomio connector reuses core `MiniTagChooser`.

Evidence:

- [fomio-fullscreen-composer-fields.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/connectors/before-composer-fields/fomio-fullscreen-composer-fields.gjs:50)
- [composer-container.gjs](/Users/ismailzabalawi/Projects/Fomio/discourse/frontend/discourse/app/components/composer-container.gjs:345)

What is still native:

- tag autocomplete
- dropdown body
- selected-tag chips/input behavior
- validation flow

Theme coverage today:

- only the closed `.select-kit-header` is styled in the composer shell
- no composer-scoped styling was found for tag popup content

### 4. Validation popovers

Category and tag validation use core `PopupInputTip`. Title validation inside `ComposerTitle` also uses the same component.

Evidence:

- [fomio-fullscreen-composer-fields.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/connectors/before-composer-fields/fomio-fullscreen-composer-fields.gjs:42)
- [composer-title.gjs](/Users/ismailzabalawi/Projects/Fomio/discourse/frontend/discourse/app/components/composer-title.gjs:255)
- [popup-input-tip.gjs](/Users/ismailzabalawi/Projects/Fomio/discourse/frontend/discourse/app/components/popup-input-tip.gjs:1)

What is still native:

- popover markup
- dismissal behavior
- icon treatment
- placement and default class contract

Theme coverage today:

- no create-composer-specific styling was found for `.popup-tip`

### 5. Rich editor behavior beyond the custom floating toolbar

The theme forces rich-editor mode and overlays some Fomio behavior, but the editor itself is still core Discourse.

Evidence:

- [fomio-rich-editor-toolbar.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/api-initializers/fomio-rich-editor-toolbar.gjs:1)
- [composer-editor.gjs](/Users/ismailzabalawi/Projects/Fomio/discourse/frontend/discourse/app/components/composer-editor.gjs:1)

What is still native:

- upload handling
- paste behavior
- mentions/hashtags/linkification
- preview pipeline
- moderation and validation hooks
- most toolbar commands, even if the stock rich toolbar is hidden

Theme coverage today:

- body typography and framing are styled
- selection formatting toolbar is replaced with a Fomio extension
- underlying editor interactions are still Discourse-owned

### 6. Link insertion modal

Fomio’s selection toolbar still opens core `UpsertHyperlink`.

Evidence:

- [fomio-selection-toolbar-extension.js](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/lib/fomio-selection-toolbar-extension.js:1)
- [upsert-hyperlink.gjs](/Users/ismailzabalawi/Projects/Fomio/discourse/frontend/discourse/app/components/modal/upsert-hyperlink.gjs:1)

What is still native:

- modal shell
- internal topic search results
- form layout
- confirm/cancel interactions

Theme coverage today:

- no composer-specific styling was found for `.upsert-hyperlink-modal` or `.insert-link`

### 7. Submit row controls and status utilities

The create flow still relies on core submit/status components inside the Fomio shell.

Evidence:

- [composer-container.gjs](/Users/ismailzabalawi/Projects/Fomio/discourse/frontend/discourse/app/components/composer-container.gjs:401)
- [common.scss](/Users/ismailzabalawi/Projects/Fomio/apps/web/common/common.scss:15820)
- [mobile.scss](/Users/ismailzabalawi/Projects/Fomio/apps/web/mobile/mobile.scss:59)

What is still native:

- `ComposerSaveButton`
- discard button behavior
- mobile upload trigger
- mobile preview toggle
- upload progress row
- draft status row

Theme coverage today:

- button chrome and spacing are partially styled
- the utility/status internals are still core Discourse markup and behavior

## Extraction Summary

The create-topic experience is currently split like this:

- Fomio-owned: layout, shell, typography, topbar, right rail, status bar, hints, selection toolbar
- Discourse-owned: title logic, category chooser popup, tag chooser popup, validation popovers, editor engine, link modal, submit/upload/draft utility controls

## Recommended Work Order

1. Category chooser popup and tag chooser popup
2. Validation popovers
3. Link insertion modal
4. Submit/upload/draft utility row
5. Any remaining editor-native affordances that still visually leak through after the above

This order isolates the most visible native surfaces first without touching the publish pipeline or replacing core composer behavior.
