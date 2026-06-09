# Fomio web — Me navigation (parent → child)

**Status:** Active model for touch + desktop Me surfaces in `apps/web/`.  
**Supersedes:** archived M2 mirrored L2 docs in [`_archive/`](./_archive/) (see `_archive/me-second-level-navigation.md` for historical route tables).

---

## 1. Authority

| Layer | Owner |
|-------|--------|
| Routes, serializers, permissions, plugin outlets, leaf templates | Discourse |
| Me **hub** presentation (landing grid), touch **back to Me** header, optional **in-page** filter chips (additive) | Fomio theme |

Canonical paths and helpers: [`javascripts/discourse/lib/fomio-mobile-nav-paths.js`](../../javascripts/discourse/lib/fomio-mobile-nav-paths.js).

---

## 2. Parent → child model

| Level | Surface | Behavior |
|-------|---------|----------|
| **Parent** | Me hub (`connectors/below-site-header/fomio-me-hub.gjs`) | Fomio-owned landing; links use native `/u/:username/...` and `/my/...` URLs. |
| **Child** | Activity, Notifications, Messages, Invites, Preferences, Badges | **Discourse templates unchanged.** User navigates with normal Ember transitions / full URLs. |
| **Touch chrome** | `fomio-me-stack-header` (`connectors/below-site-header/fomio-me-stack-header.gjs`) | `‹ Me` back to summary hub; section title from `meSectionTitleKey()`. |

We **do not** mirror Discourse’s secondary pill row into a parallel nav (historical reference: [`apps/web/_archive/me-embedded-l2/`](../../_archive/me-embedded-l2/README.md), kept **outside** `javascripts/discourse/` so it is not compiled into the theme).

---

## 3. Optional filter chips (notifications inbox only)

**Outlet (verified):** `user-notifications-above-filter` in `discourse/frontend/discourse/app/templates/user/notifications-index.gjs`.

**Implementation:**

- Component: `javascripts/discourse/components/fomio-me-filter-chips.gjs`
- Connector: `connectors/user-notifications-above-filter/fomio-me-notifications-filter-chips.gjs` (only when `currentRouteName === "userNotifications.index"`)

Chips set `data-fomio-me-notifications-filter` on `document.body` (`all` clears the attribute). SCSS in `common/common.scss` shows/hides `li.notification` rows by type classes from Discourse (`discourse/.../lib/notification-types/base.js`: `.notification` + hyphenated type, e.g. `.liked`, `.mentioned`).

**Limitations:**

- Chips are **orthogonal** to Discourse’s read/unread filter control; both may apply.
- Plugin-added notification types may need SCSS updates if they should appear inside a bucket.
- **Activity** does not ship chips yet: mixed `UserAction` rows in `PostList` do not expose stable per-row type classes for pure-CSS filtering without DOM changes. Use native activity pills until a future design pass.

---

## 4. Where we do **not** add chips

| Area | Reason |
|------|--------|
| **Messages** | Inbox / sent / unread / archive / group / tags load **different datasets** per route — keep native pills + dropdown. |
| **Invites** | Status tabs map to different server queries — native pills. |
| **Preferences** | Native tab + form chrome — no Fomio filter row. All Me leaf screens use the **one-flat-surface page treatment on touch**; preferences additionally drops per-group boxes (see `touch-preferences-redesign-pattern.md`). |
| **Badges** | Single list — no chips. |
| **Activity** | No stable row-level selectors for “all” stream; use native secondary nav. |

If product later needs chip-like shortcuts here, prefer **`router.transitionTo` to existing Discourse child routes** (URLs + deep links stay correct). That requires a small DSP; do not reintroduce `in-element` mirroring.

---

## 5. Studio — web-adapted critique (this change set)

**Pass 1 — Experience Architect:** PASS — Me reads as Discourse-native child screens; chips use `--fomio-*` tokens and compact pill rhythm; terminology uses Hub / Teret / Byte rules in new `me_filter_chips` copy only (no forbidden synonyms).

**Pass 2 — Frontend Engineer:** PASS — `user-notifications-above-filter` verified in Discourse tree; GJS-only; no `fetch`; no `in-element` into core nav; SCSS scoped under `body.user-notifications-page[...]` + `#user-content .user-notifications-list`.

**Pass 3 — Product Engineer:** CONDITIONAL PASS — Manual verify in Safari + Chrome: keyboard focus order (chips → native filter → list), `aria-pressed` on chips, unread/read filter interaction, and long lists with “Load more”. Automated theme tests not run in this repo slice.

---

## 6. `apps/web-beta`

This workspace does not include a live `apps/web-beta/` theme tree. When the beta track returns, mirror:

- `components/fomio-me-filter-chips.gjs`
- `connectors/user-notifications-above-filter/fomio-me-notifications-filter-chips.gjs`
- `common/common.scss` (Me chip block)
- `locales/en.yml` (`me_filter_chips` keys)
- This doc

See [`apps/web-beta/README.md`](../../../web-beta/README.md).
