# Taxonomy Admin-First Migration

Date: 2026-06-17

## Rule

When Discourse already exposes a taxonomy, navigation, or composer behavior through admin configuration or category/tag data, prefer that over theme hard-coding.

Theme code should only own:

- Fomio terminology and copy
- Fomio layout and reading UX
- Cross-surface presentation rules that Discourse does not model

Theme code should not own:

- canonical category structure
- tag availability
- default category selection
- default category notification behavior
- default category page mode
- whether category names appear in page titles

## Verified Core Controls

The following core settings already exist in Discourse and should be treated as the first control plane:

| Concern | Core control |
| --- | --- |
| Desktop `/categories` layout | `desktop_category_page_style` |
| Mobile `/categories` layout | `mobile_category_page_style` |
| Default composer category | `default_composer_category` |
| Include category in topic page title | `topic_page_title_includes_category` |
| Hide uncategorized badge | `suppress_uncategorized_badge` |
| Default nav tags | `default_navigation_menu_tags` |
| Default category watch state | `default_categories_watching` |
| Default category tracking state | `default_categories_tracking` |
| Default category muted state | `default_categories_muted` |
| Default category watch-first-post state | `default_categories_watching_first_post` |
| Default category normal state | `default_categories_normal` |

Source:

- [discourse/config/site_settings.yml](/Users/ismailzabalawi/Projects/Fomio/discourse/config/site_settings.yml)

Relevant definitions:

- `desktop_category_page_style` and `mobile_category_page_style`
- `default_navigation_menu_tags`
- `suppress_uncategorized_badge`
- `default_composer_category`
- `topic_page_title_includes_category`
- `default_categories_*`

## Current Live Backend Findings

Observed through the live backend on `https://meta.fomio.app`:

- `/categories` is already rendered as a Fomio Hub index by the theme.
- The live category tree currently contains 12 visible top-level categories/hubs.
- The backend taxonomy itself is not yet normalized:
  - mixed naming styles are present, for example `BUSINESS & Finance`, `Entertainment & arts`, and `lifestyle`
  - some hub descriptions are complete, some are missing
  - some hubs have terets/subcategories, some do not
- Public `/tags` currently resolves to a 404 page, so tags are not yet a stable public taxonomy surface.
- Admin search for `tag` confirms Discourse exposes tag-related controls such as `default_navigation_menu_tags` and tag-count settings.

## Current Theme Ownership

The theme is already doing the right thing in several places by deriving taxonomy from live category data instead of hard-coded lists.

### Good: backend-derived

- [apps/web/javascripts/discourse/lib/fomio-hub-catalog.js](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/lib/fomio-hub-catalog.js)
  Builds the hub catalog from live category sources.
- [apps/web/javascripts/discourse/connectors/above-site-header/fomio-sidebar.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/connectors/above-site-header/fomio-sidebar.gjs)
  Builds hub and teret navigation from `site.categories`.
- [apps/web/javascripts/discourse/connectors/above-site-header/fomio-master-pane.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/connectors/above-site-header/fomio-master-pane.gjs)
  Mirrors the same category-driven model.
- [apps/web/javascripts/discourse/connectors/below-discovery-categories/fomio-categories.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/connectors/below-discovery-categories/fomio-categories.gjs)
  Renders the hub index from live categories.
- [apps/web/javascripts/discourse/connectors/discovery-list-controls-above/fomio-hub-chrome.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/connectors/discovery-list-controls-above/fomio-hub-chrome.gjs)
  Resolves hub and teret state from the actual category tree.
- [apps/web/javascripts/discourse/components/shared/fomio-composer-category-picker.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-composer-category-picker.gjs)
  Uses `composer.categories` instead of a theme-owned category registry.
- [apps/web/javascripts/discourse/connectors/full-page-search-below-search-header/fomio-search-filter-chips.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/connectors/full-page-search-below-search-header/fomio-search-filter-chips.gjs)
  Already branches on `siteSettings.tagging_enabled`.

### Good: minimal theme settings

- [apps/web/settings.yml](/Users/ismailzabalawi/Projects/Fomio/apps/web/settings.yml)
  Only contains `fomio_app_url`, which is appropriate. Taxonomy is not encoded in theme settings today.

## Additional Route-Level Overrides Found

The first audit understated how aggressively the theme owns discovery routes. These are not just style tweaks.

### `/categories` is effectively replaced

- [apps/web/javascripts/discourse/connectors/below-discovery-categories/fomio-categories.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/connectors/below-discovery-categories/fomio-categories.gjs)
  Injects a complete Fomio Hub index.
- [apps/web/common/common.scss](/Users/ismailzabalawi/Projects/Fomio/apps/web/common/common.scss)
  Hides core `.contents`, `.list-controls`, and `#navigation-bar` for the categories page while the custom Hub surface is mounted.

This means `desktop_category_page_style` and `mobile_category_page_style` may still exist in admin, but the theme can bypass their visible effect on `/categories`.

### Mobile shell navigation is fully custom

- [apps/web/javascripts/discourse/connectors/above-site-header/fomio-bottom-bar.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/connectors/above-site-header/fomio-bottom-bar.gjs)
  Replaces mobile navigation with Fomio-owned `Home`, `Discover`, `Create Byte`, `Notifications`, and `Me`.
- [apps/web/common/common.scss](/Users/ismailzabalawi/Projects/Fomio/apps/web/common/common.scss)
  Owns the bottom-bar layout and reserves page space for it.

This is a product shell override, not an admin-configurable Discourse navigation surface.

### Fomio shell mode claims discovery routes globally

- [apps/web/javascripts/discourse/api-initializers/fomio-layout.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/api-initializers/fomio-layout.gjs)
  Applies `body.fomio-sidebar-active` across non-auth, non-native routes.
- [apps/web/javascripts/discourse/api-initializers/theme-initializer.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/api-initializers/theme-initializer.gjs)
  Treats `/categories` as a first-class Fomio home-like route in mobile handoff logic.
- [apps/web/javascripts/discourse/lib/fomio-mobile-nav-paths.js](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/lib/fomio-mobile-nav-paths.js)
  Folds `/categories` and `/c/...` into Fomio discovery path semantics.

### Discovery topic lists are heavily re-skinned

- [apps/web/javascripts/discourse/api-initializers/my-theme.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/api-initializers/my-theme.gjs)
  Adds `--fomio-discovery-list` and `--fomio-discovery-item` classes.
- [apps/web/common/common.scss](/Users/ismailzabalawi/Projects/Fomio/apps/web/common/common.scss)
- [apps/web/mobile/mobile.scss](/Users/ismailzabalawi/Projects/Fomio/apps/web/mobile/mobile.scss)
- [apps/web/desktop/desktop.scss](/Users/ismailzabalawi/Projects/Fomio/apps/web/desktop/desktop.scss)

These files substantially replace the native discovery list presentation for `/latest`, `/categories`, and `/c/...`.

## Migration Matrix

| Concern | Own in admin/backend | Own in theme | Current status | Action |
| --- | --- | --- | --- | --- |
| Hub list | Yes, via categories | Only presentation | Already backend-derived | Keep backend-derived |
| Teret list | Yes, via subcategories | Only presentation | Already backend-derived | Keep backend-derived |
| `/categories` page body | Core can own, but theme currently replaces it | Yes, currently | Strong override exists | Decide whether to keep full replacement or reintroduce more core ownership |
| Mobile discovery nav | Core does not provide Fomio shell | Yes | Fully theme-owned | Keep as product shell, but treat separately from taxonomy |
| Discovery list layout | Core can render lists, theme heavily re-skins | Yes | Strong override exists | Audit for places where admin settings should still win |
| Byte terminology | No | Yes | Theme-owned copy | Keep in locales/theme |
| Hub/Teret terminology | No | Yes | Theme-owned copy | Keep in locales/theme |
| Hub descriptions | Yes, via category descriptions | Only layout treatment | Backend data already used | Normalize descriptions in admin |
| Hub ordering | Yes, via category ordering | No unless supplemental UI sort is necessary | Theme reflects category ordering in most places | Prefer admin ordering |
| Category visibility/permissions | Yes | No | Pure backend concern | Manage in admin only |
| Default composer category | Yes | Theme may read only | Core setting exists | Remove any parallel assumptions |
| Category page style | Yes | Theme may adapt around it | Core setting exists | Read and respect before overriding |
| Default nav tags | Yes | Theme may display or rename | Core setting exists | Decide if tags are productized before building UI |
| Tag availability | Yes | Theme may hide/relabel | Unclear product role, `/tags` currently 404 | Resolve in admin/product model first |
| Default category follow state | Yes | No | Core settings exist | Use admin defaults |
| Topic title includes category | Yes | Theme should not duplicate | Core setting exists | Respect core behavior |
| Uncategorized suppression | Yes | Theme should not emulate | Core setting exists | Respect core behavior |
| Search category/tag labels | Partly | Yes | Theme relabels correctly; logic reads `tagging_enabled` | Keep, but align with backend tag strategy |

## First Execution Slices

### Slice 1: backend normalization

Do this in admin before touching theme code:

- normalize hub naming and casing
- normalize hub descriptions
- confirm which categories are true hubs
- confirm which subcategories are true terets
- decide whether tags are part of the public taxonomy
- configure `default_composer_category`
- configure default category follow states
- review `desktop_category_page_style` and `mobile_category_page_style`

### Slice 2: remove theme duplication

Audit for any theme logic that:

- assumes a category should be first
- assumes tags are present or absent without reading `siteSettings`
- imposes a category order that conflicts with admin order
- treats presentation copy as if it were taxonomy data

### Slice 3: lock terminology and presentation

Keep these in theme code:

- `Hub`, `Teret`, `Byte` naming in [apps/web/locales/en.yml](/Users/ismailzabalawi/Projects/Fomio/apps/web/locales/en.yml)
- Fomio shell layout
- hub/teret visual treatment
- composer, search, and profile language

## Immediate Code Targets

These are the first files to review after backend normalization:

- [apps/web/javascripts/discourse/connectors/above-site-header/fomio-sidebar.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/connectors/above-site-header/fomio-sidebar.gjs)
- [apps/web/javascripts/discourse/connectors/above-site-header/fomio-master-pane.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/connectors/above-site-header/fomio-master-pane.gjs)
- [apps/web/javascripts/discourse/connectors/below-discovery-categories/fomio-categories.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/connectors/below-discovery-categories/fomio-categories.gjs)
- [apps/web/javascripts/discourse/components/shared/fomio-composer-category-picker.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/components/shared/fomio-composer-category-picker.gjs)
- [apps/web/javascripts/discourse/connectors/full-page-search-below-search-header/fomio-search-filter-chips.gjs](/Users/ismailzabalawi/Projects/Fomio/apps/web/javascripts/discourse/connectors/full-page-search-below-search-header/fomio-search-filter-chips.gjs)

## Practical Working Rule

Before adding taxonomy behavior in `apps/web`, check this order:

1. Can admin settings solve it?
2. Can category or tag data solve it?
3. Can existing client `siteSettings` solve it?
4. Only then add theme logic.

## Site Texts Audit

The correct first pass is `Admin > Customize > Site texts`, because many native Discourse labels are overrideable there before touching theme locales.

Observed on:

- `/admin/customize/site_texts?q=topic`
- `/admin/customize/site_texts?q=category`
- `/admin/customize/site_texts?q=tag`
- `/admin/customize/site_texts?q=post`

### High-value core strings available in Site Texts

These are good candidates to rename at the Discourse text layer instead of theme code.

#### `topic` / `topics`

Examples observed:

- `js.topic.title`
- `js.topic.create`
- `js.topic.list`
- `js.categories.topics`
- `js.user.summary.topics`
- `js.user_action_groups.4`
- `topics`
- `reports.topics.title`
- `rss_description.hot`
- `rss_description.top`

Likely Fomio direction:

- `Topic` -> `Byte`
- `Topics` -> `Bytes`
- `new topic` -> `new byte`
- `New Topic` -> `New Byte`
- `Topic Options` -> `Byte Options`
- `Pin Topic` -> `Pin Byte`

#### `category` / `categories`

Examples observed:

- `js.categories.category`
- `js.category_title`
- `js.category.none`
- `js.category.all`
- `js.category.save`
- `js.category.slug`
- `js.category.name`
- `js.category.create`
- `js.category.list`
- `activerecord.attributes.topic.category_id`
- `reports.activity_by_category.labels.category`

Likely Fomio direction:

- `Category` -> `Hub` or `Teret`, depending on context
- `All categories` -> `All Hubs`
- `Save category` -> avoid broad replacement until context is checked
- `Category name` -> likely `Hub name` only in top-level category administration is not safe for blanket replacement

Important constraint:

`category` is not a globally safe blind replacement because Discourse uses one word for both top-level categories and subcategories. Fomio splits those into `Hub` and `Teret`, so many `category` keys need contextual review instead of mass replace.

#### `tag` / `tags`

Examples observed:

- `tags.title`
- `js.search.tags`
- `js.tagging.tags`
- `js.category.tags`
- `js.user.tag_settings`
- `js.user.messages.tags`
- `js.tagging.all_tags`
- `js.sidebar.all_tags`
- `js.tagging.selector_tags`
- `rss_by_tag`
- `rss_description.tag`
- `js.tagging.groups.title`

Important constraint:

Tag terminology should not be mass-renamed until the product decision is made on whether tags remain public, are hidden, or are mapped into a Fomio-visible concept. Right now `/tags` is not a stable public surface.

#### `post` / `posts`

Examples observed:

- `js.review.types.reviewable_post.title`
- `js.posts`
- `js.groups.posts`
- `js.about.post_count`
- `js.categories.posts`
- `js.original_post`
- `js.post_list.title`
- `rss_num_posts.one`

Likely Fomio direction:

- `Post` is not globally safe to rename to `Byte`
- in many places `post` means `reply`, not top-level content
- some keys should become `Reply` / `Replies`
- some should remain `Post` in admin/moderation contexts if they refer to raw Discourse primitives

### Ownership Rule From This Audit

Use Site Texts first for:

- core labels the user sees in native Discourse UI
- education and system copy
- admin-configurable wording that the theme does not own

Use theme locales second for:

- Fomio-only UI surfaces
- shell navigation labels
- custom components and connectors

Do not mass-replace blindly in Site Texts for:

- `category`
- `post`
- `tag`

Those require contextual review because the Fomio taxonomy does not map one-to-one to Discourse primitives.
