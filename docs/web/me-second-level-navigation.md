# Fomio mobile web — Me second-level navigation (Phase M2-A)

**Status:** planning only — no UI implementation in this phase.

**Authority:** Discourse owns routes, data, permissions, and all leaf content. Fomio owns **navigation presentation** (how the Me stack reads and how second-level menus are styled or duplicated in the shell), without replacing Discourse logic or inventing rows.

**Evidence:** Route and nav structure verified against `discourse/frontend/discourse/app/routes/app-route-map.js` and the templates/components cited inline below.

---

## 1. Overall model

| Level | Owner | What the user sees |
|-------|--------|-------------------|
| **Level 1** | Fomio | **Me landing** — primary grid/list of Me areas (Summary, Activity, …). Already implemented via the touch Me hub on landing surfaces only. |
| **Level 2** | Fomio (presentation) + Discourse (truth) | **Section menu** — where Discourse already exposes secondary navigation (pills, dropdowns, tabs), Fomio may present a **consistent second-level menu** that links to the **same native routes** and respects the same visibility rules. No custom data or filters. |
| **Level 3** | Discourse | **Leaf content** — lists, forms, streams. Unchanged. |

**Canonical username placeholder:** `:username` = signed-in user’s username (lower-case in URLs). Per-user paths mirror `/my/...` where Discourse provides redirects; Fomio helpers already prefer `/u/:username/...` where possible (`fomio-mobile-nav-paths.js`).

**Dock (touch):** For all paths under Me territory (`/my/*`, `/u/*` profile stack, `/notifications` per `isMePath`), the **Me** tab stays the active dock tab unless a separate rule overrides it (e.g. Saved tab for bookmark-heavy URLs — not the case for the areas below).

---

## 2. Level 1 / 2 / 3 by Me area

### 2.1 Summary

| Question | Answer |
|----------|--------|
| Leaf vs second-level | **Simple leaf / landing.** Primary user nav only; no Discourse secondary pill row for “Summary” itself. |
| Native routes | `/u/:username` redirects to Activity for **self** (`user/index` → `userActivity`); **Summary** is `user.summary` → `/u/:username/summary`. `/my`, `/my/summary` (Fomio hub treats `/my` and `/my/summary` as landing). |
| Fomio labels | Use Discourse copy: `user.summary.title` (see `user-nav.gjs`). |
| Body class | `user-summary-page` (`user/summary.gjs`). |
| Native nav to replace/hide later | **Primary** user nav: `.user-navigation-primary` / `UserNav` (only if product chooses to consolidate; not required for Summary-only). |
| Second-level Fomio menu | **No** (Level 2 not applicable). |

### 2.2 Activity

| Question | Answer |
|----------|--------|
| Leaf vs second-level | **Second-level navigation** (native horizontal pills). |
| Native routes (core) | From `user-activity.gjs` + `app-route-map.js` under `userActivity` (`path: /activity`): |

**Route map (Activity)**

| Fomio row label (mirror Discourse) | Route name | Path (under `/u/:username`) | Shown when |
|-----------------------------------|------------|-----------------------------|------------|
| All | `userActivity.index` | `/activity` | always |
| Topics | `userActivity.topics` | `/activity/topics` | always |
| Replies | `userActivity.replies` | `/activity/replies` | always |
| Read | `userActivity.read` | `/activity/read` | `user.showRead` |
| Drafts | `userActivity.drafts` | `/activity/drafts` | `user.showDrafts` |
| Pending | `userActivity.pending` | `/activity/pending` | `pending_posts_count > 0` |
| Likes (given) | `userActivity.likesGiven` | `/activity/likes-given` | always |
| Bookmarks | `userActivity.bookmarks` | `/activity/bookmarks` | `user.showBookmarks` |

| Plugin-dependent / outlet | Notes |
|---------------------------|--------|
| **Solved** | `discourse-solved` adds `userActivity.solved` via connector `user-activity-bottom` → `/activity/solved` (plugin). |
| **Votes** | `discourse-topic-voting` adds `/activity/votes` (plugin tests use `/u/.../activity/votes`). |
| **Other** | `PluginOutlet` `user-activity-bottom` (`user-activity.gjs`) — any plugin-added row must be preserved or explicitly documented if hidden. |

| Additional core route (no pill in template) | `userActivity.bookmarksWithReminders` → `/activity/bookmarks-with-reminders` exists in `app-route-map.js` but **no** `DNavigationItem` in `user-activity.gjs`. Do not invent a Fomio row unless product confirms it should appear; deep link may still exist. |

| Body class | `user-activity-page` |
| Native nav selector | `.user-navigation.user-navigation-secondary` + `HorizontalOverflowNav` (activity). |
| Second-level Fomio menu | **Yes** — mirror native rows + outlet-derived rows per site. |

### 2.3 Notifications

| Question | Answer |
|----------|--------|
| Leaf vs second-level | **Second-level navigation** (native). **Audit source:** `user-notifications.gjs` only — do not invent rows. |

**Route map (Notifications)** — paths relative to `/u/:username/notifications`

| Fomio row label (mirror Discourse) | Route name | Path segment | Shown when |
|-----------------------------------|------------|--------------|------------|
| All | `userNotifications.index` | `/notifications` (index) | always |
| Responses | `userNotifications.responses` | `/notifications/responses` | always |
| Likes received | `userNotifications.likesReceived` | `/notifications/likes-received` | always |
| Mentions | `userNotifications.mentions` | `/notifications/mentions` | `siteSettings.enable_mentions` |
| Edits | `userNotifications.edits` | `/notifications/edits` | always |
| Links | `userNotifications.links` | `/notifications/links` | always |

| Plugin-dependent / outlet | `PluginOutlet` `user-notifications-bottom` — plugins may append rows. |

| Body class | `user-notifications-page` |
| Native nav selector | `.user-navigation.user-navigation-secondary` (notifications). |
| Note | `/notifications` global path is Me-tab territory in Fomio path helpers; secondary pills still live on the user notifications route structure above for per-user URLs. |
| Second-level Fomio menu | **Yes** — mirror `user-notifications.gjs` + `user-notifications-bottom` connectors. |

### 2.4 Messages (private messages)

| Question | Answer |
|----------|--------|
| Leaf vs second-level | **Second-level navigation** — pill row **plus** inbox **dropdown** (group inboxes, tags). |

**User inbox** (`user-private-messages/user.gjs`) — paths under `/u/:username/messages`:

| Fomio row label (mirror Discourse) | Route name | Path | Shown when |
|-----------------------------------|------------|------|------------|
| Latest | `userPrivateMessages.user.index` | `/messages` | always |
| Sent | `userPrivateMessages.user.sent` | `/messages/sent` | always |
| New | `userPrivateMessages.user.new` | `/messages/new` | `viewingSelf` only |
| Unread | `userPrivateMessages.user.unread` | `/messages/unread` | `viewingSelf` only |
| Archive | `userPrivateMessages.user.archive` | `/messages/archive` | always |

| Additional native UI (not duplicate rows) | **Messages dropdown** (`MessagesDropdown` in `user/messages.gjs`) — inbox vs **group** PMs (`/messages/group/:name/...`), and **Tags** when `site.can_tag_pms` → tag routes under `userPrivateMessages.tags`. **Custom rows** may be registered via `registerCustomUserNavMessagesDropdownRow` (`user-private-messages.js`). |

| Group inbox secondary** | `user-private-messages/group.gjs` — Latest, New, Unread, Archive (no Sent); only when viewing a group context. |

| Body class | `user-messages-page` (`user/messages.gjs`). |
| Native nav selector | `.user-navigation.user-navigation-secondary` (`.messages-nav`) + breadcrumb dropdown. |
| Second-level Fomio menu | **Yes** — must account for **pills + dropdown** parity (Fomio presents links; Discourse still owns state). |

### 2.5 Invites

| Question | Answer |
|----------|--------|
| Leaf vs second-level | **Second-level navigation** (native tabs — **not** a simple leaf). |
| Native routes | `userInvited` → `/u/:username/invited` with `userInvited.show` + `:filter`: |

| Fomio row label | Route | Path |
|-----------------|-------|------|
| Pending | `userInvited.show` (`pending`) | `/invited/pending` |
| Expired | `userInvited.show` (`expired`) | `/invited/expired` |
| Redeemed | `userInvited.show` (`redeemed`) | `/invited/redeemed` |

| Hidden when | Template gates `bodyClass` + nav on `can_see_invite_details` (`user-invited.gjs`). |

| Body class | `user-invites-page` (when allowed). |
| Native nav selector | `.user-navigation.user-navigation-secondary` (invites). |
| Second-level Fomio menu | **Yes** — mirror pending / expired / redeemed. |

### 2.6 Badges

| Question | Answer |
|----------|--------|
| Leaf vs second-level | **Simple leaf** — no native secondary pill row in `user/badges.gjs`. |
| Native routes | `user.badges` → `/u/:username/badges`. |
| Body class | `user-badges-page`. |
| Second-level Fomio menu | **No**. |

### 2.7 Preferences

| Question | Answer |
|----------|--------|
| Leaf vs second-level | **Second-level navigation** (native pills). **Audit source:** `preferences.gjs`. |

**Route map (Preferences)** — paths under `/my/preferences` (Discourse canonical for prefs)

| Fomio row label (mirror Discourse) | Route name | Path | Shown when |
|-----------------------------------|------------|------|------------|
| Account | `preferences.account` | `/my/preferences/account` | always |
| Security | `preferences.security` | `/my/preferences/security` | always |
| Profile | `preferences.profile` | `/my/preferences/profile` | always |
| Emails | `preferences.emails` | `/my/preferences/emails` | always |
| Notifications | `preferences.notifications` | `/my/preferences/notifications` | always |
| Tracking | `preferences.tracking` | `/my/preferences/tracking` | `model.can_change_tracking_preferences` |
| Users | `preferences.users` | `/my/preferences/users` | always |
| Interface | `preferences.interface` | `/my/preferences/interface` | always |
| Navigation menu | `preferences.navigation-menu` | `/my/preferences/navigation-menu` | always |

| Plugin outlets (may add rows) | `user-preferences-nav-under-interface`, `user-preferences-nav` (`preferences.gjs`). |

| Routes in `app-route-map.js` **not** in the core `preferences.gjs` pill row | `preferences.apps`, `preferences.tags`, `preferences.email`, `preferences.second-factor` — **do not** add to Fomio second-level until confirmed visible via Discourse UI on target sites (may be deep links or secondary screens). **Apps** is a common expectation for admins; verify per deployment. |

| Body class | `user-preferences-page`. |
| Native nav selector | `.user-navigation.user-navigation-secondary` (preferences). |
| Second-level Fomio menu | **Yes** — mirror `preferences.gjs` rows + outlet rows for installed plugins. |

### 2.8 Manage user (staff)

| Question | Answer |
|----------|--------|
| Leaf vs second-level | **Admin leaf** — Discourse **admin** user screen, not the user profile template stack. |
| Native route | From profile: `user.adminPath` / hub uses `/admin/users/:id/:username` (`adminManageUserPathForUser` in theme). Mobile primary nav uses plain `<a href={{@user.adminPath}}>` in `user-nav.gjs` (`user-nav__admin`). |
| Body class | **Not** the user profile `user-*-page` classes — admin templates own their classes (confirm when styling). |
| Second-level Fomio menu | **No** unless product audits **native** admin tabs for that screen and decides to mirror them (out of scope unless explicitly specified). |

### 2.9 About

| Question | Answer |
|----------|--------|
| Leaf vs second-level | **Simple leaf** (site About). |
| Native route | `/about` (`about` route). |
| Body class | `about-page` (`about.gjs`). |
| Second-level Fomio menu | **No**. |

### 2.10 Sign out

| Question | Answer |
|----------|--------|
| Leaf vs second-level | **Action only** — not a content screen. |
| Native route | Discourse logout (`/logout` — server/session; no second-level menu). |
| Second-level Fomio menu | **No**. |

---

## 3. Master route map (summary table)

| Me area | Second-level Fomio menu? | Key paths |
|---------|-------------------------|-----------|
| Summary | No | `/u/:username/summary`, `/my`, `/my/summary` |
| Activity | Yes | `/u/:username/activity...` (+ plugins solved/votes) |
| Notifications | Yes | `/u/:username/notifications...` |
| Messages | Yes | `/u/:username/messages...` (+ group/tags variants) |
| Invites | Yes | `/u/:username/invited/{pending,expired,redeemed}` |
| Badges | No | `/u/:username/badges` |
| Preferences | Yes | `/my/preferences/...` |
| Manage user | No (admin) | `/admin/users/:id/:username` |
| About | No | `/about` |
| Sign out | No | `/logout` |

---

## 4. Plugin-dependent / outlet-dependent rows (must not break silently)

| Area | Mechanism | Examples |
|------|-----------|----------|
| Activity | `user-activity-bottom` | Solved, Votes, other plugins |
| Notifications | `user-notifications-bottom` | Plugin-defined |
| Preferences | `user-preferences-nav*`, `user-preferences-nav-under-interface` | Plugin-defined tabs |
| Messages | `registerCustomUserNavMessagesDropdownRow`, `user-messages-*` outlets | Custom inbox rows, controls |

**Rule:** Fomio second-level menus must either **consume the same visibility** as Discourse (preferred) or **delegate** to native nav for plugin rows — do not ship hard-coded lists that omit plugin outlets unless documented as an explicit product tradeoff.

---

## 5. Rows to hide when unavailable (non-exhaustive)

| Row / area | Condition |
|------------|-----------|
| Activity: Read / Drafts / Bookmarks | Discourse `user.showRead`, `showDrafts`, `showBookmarks` |
| Activity: Pending | `pending_posts_count > 0` |
| Notifications: Mentions | `siteSettings.enable_mentions` |
| Messages: New / Unread | `viewingSelf` |
| Messages: Tags inbox | `site.can_tag_pms` |
| Invites tab bar | `can_see_invite_details` |
| Preferences: Tracking | `model.can_change_tracking_preferences` |
| Me hub: Badges | Fomio hub already gates on `enable_badges` + badge count (`fomio-me-hub.gjs`) — second-level should not contradict |

---

## 6. Native nav selectors (for future hide/replace)

| Screen | Secondary nav container | Notes |
|--------|---------------------------|--------|
| Activity | `.user-navigation-secondary` on `body.user-activity-page` | Horizontal pills |
| Notifications | `.user-navigation-secondary` on `body.user-notifications-page` | Horizontal pills |
| Messages | `.user-navigation-secondary` + `#user-navigation-secondary__horizontal-nav` | Pills + dropdown |
| Preferences | `.user-navigation-secondary` on `body.user-preferences-page` | Horizontal pills |
| Invites | `.user-navigation-secondary` on `body.user-invites-page` | `NavItem` pills |

Primary user nav (`UserNav`, `.user-navigation-primary`) appears across profile sections; Fomio may hide/replace **secondary** first per M2-A scope.

---

## 7. Recommended implementation order

1. **Notifications** — smallest core set, clear template audit (`user-notifications.gjs`), outlet for plugins.
2. **Activity** — highest row count + plugin outliers (solved/votes); validate conditional rows.
3. **Preferences** — many rows + outlets; confirm **Users** and **Navigation menu** parity with product copy.
4. **Messages** — pills + dropdown + group/tag contexts; highest interaction complexity.
5. **Invites** — three-tab model; gate on `can_see_invite_details`.
6. **Leaves** (Summary, Badges, About, Sign out, Manage user) — no second-level menu work unless primary nav changes.

---

## 8. Do-not list (phase guardrails)

- Do not rebuild Discourse data or duplicate Activity/Notifications/Messages/Preferences **logic**.
- Do not hide native content globally — only targeted chrome per approved design.
- Do not use **body-class sync** between hub and leaf routes for navigation state.
- Do not schedule **side effects from getters** or render hooks to force nav state.
- Do not reintroduce **`fomio-mobile-web-mode`**.
- Do not add **fake rows** (every link must map to a real Discourse route or plugin route).
- Do not show **chevrons on inert** rows.
- Do not remove **plugin-added** rows without documenting the plugin and the tradeoff.

---

## 9. Uncertainties / follow-ups

| Topic | Uncertainty |
|-------|-------------|
| Admin “Manage user” | Exact body classes and tab structure live in admin app; audit before any Fomio second-level mirroring. |
| `bookmarks-with-reminders` | Route exists in core map but is absent from `user-activity.gjs` pills — confirm whether Fomio should expose it. |
| `preferences.apps` / `preferences.tags` | Not in core `preferences.gjs` nav; may appear via plugins or direct navigation — confirm on meta.fomio.app before adding labels. |
| `/u/:username` vs Summary | Discourse redirects **self** from `/u/:username` to **Activity** (`user/index`); Fomio Me landing intentionally treats own summary/root as hub — document UX alignment so users are not surprised by Discourse redirects when opening raw profile URLs. |

---

## 10. References (Discourse source)

- `discourse/frontend/discourse/app/routes/app-route-map.js` — canonical route paths.
- `discourse/frontend/discourse/app/templates/user-activity.gjs` — Activity secondary nav.
- `discourse/frontend/discourse/app/templates/user-notifications.gjs` — Notifications secondary nav.
- `discourse/frontend/discourse/app/templates/user-private-messages/user.gjs` — Messages pills.
- `discourse/frontend/discourse/app/templates/user/messages.gjs` — Messages layout + dropdown.
- `discourse/frontend/discourse/app/templates/preferences.gjs` — Preferences secondary nav.
- `discourse/frontend/discourse/app/templates/user-invited.gjs` — Invites secondary nav.
- `discourse/frontend/discourse/app/components/user-nav.gjs` — Primary Me tabs + Manage user link.
- `apps/web/javascripts/discourse/lib/fomio-mobile-nav-paths.js` — Fomio path helpers + Me landing detection.

---

## 11. Phase M2-B — Notifications (implemented)

**Shipped in theme (`apps/web/`):**

| Piece | Location |
|-------|----------|
| Section menu component | `javascripts/discourse/components/fomio-notifications-section-menu.gjs` |
| Connector (hosts component) | `javascripts/discourse/connectors/top-notices/fomio-notifications-section-menu.gjs` |
| Scoped SCSS | `common/common.scss` — root `body.user-notifications-page:has(.fomio-notifications-section-menu)` (M2-B block at end of file) |
| Aria label | `locales/en.yml` → `notifications_submenu.nav_aria` |

**Behavior:**

- The connector mounts from Discourse’s `top-notices` outlet (`discourse/.../application.gjs`), gated on logged-in + **URL from `router.currentURL`** (and `userNotifications.*` route name as fallback). Do **not** use the outlet’s `currentPath` argument for gating — it is Ember’s dot-path (`user.userNotifications.index`), not `/u/…/notifications`.
- The menu is rendered with `{{#in-element parent insertBefore=null}}` (Ember 6+ only allows `null` for `insertBefore`) so content **appends** to `.user-navigation.user-navigation-secondary`; **`order: -1`** on the menu and a column flex layout on the secondary nav place it **above** the native pill row and dismiss controls.
- **Native suppression:** only when the Fomio menu is present (`body.user-notifications-page:has(.fomio-notifications-section-menu)`), the six core `li.user-nav__notifications-*` items are `display: none`. If the menu never mounts, **native pills stay visible** (no blank strip). **`user-notifications-bottom` plugin rows** typically use `li` elements **without** those class prefixes, so they remain in the native strip when present.
- When there are **no** plugin rows, the native `nav.horizontal-overflow-nav` is hidden entirely via `:not(:has(ul.nav-pills > li:not([class*="user-nav__notifications-"])))`.
- **Limitation:** If a third-party connector reuses a class containing `user-nav__notifications-`, it could be hidden incorrectly; document any such plugin. If `in-element` never resolves after 12 animation frames, the Fomio menu does not appear and native pills remain (by design).

**Not changed:** notification stream, filters, dismiss control, routes, or other Me areas.

---

## 12. Phase M2-C — Activity (implemented)

**Shipped in theme (`apps/web/`):**

| Piece | Location |
|-------|----------|
| Section menu component | `javascripts/discourse/components/fomio-activity-section-menu.gjs` |
| Connector | `javascripts/discourse/connectors/top-notices/fomio-activity-section-menu.gjs` |
| Scoped SCSS | `common/common.scss` — `body.user-activity-page:has(.fomio-activity-section-menu)` (block after M2-B) |
| Aria label | `locales/en.yml` → `activity_submenu.nav_aria` |

**Shared pattern (M2-B / M2-C):**

- Mount from **`top-notices`**; gate on **`router.currentURL`** and optional **`router.currentRouteName`** fallback — never outlet `currentPath`.
- Find `#main-outlet .user-main .user-navigation.user-navigation-secondary` and its direct child `nav.horizontal-overflow-nav`.
- Render with `{{#in-element parent insertBefore=null}}` (append only); **`order: -1`** + column flex on the secondary nav stacks the Fomio menu above native pills.
- Retry with **`requestAnimationFrame`** (36 attempts) if the nav is late.
- **Native suppression** only when `:has(.fomio-activity-section-menu)` is true so a failed insert leaves native pills.
- **Conditional rows** use `controller:user` computed getters `showRead` / `showDrafts` / `showBookmarks` (same as `@controller.user` in `user-activity.gjs`), `pending_posts_count` on the profile user model, and `currentUser` for draft count labels — same sources as `UserActivityController` / `UserController`.
- **Plugins:** non-core `li` items under `user-activity-bottom` are scanned once the horizontal nav exists; labels/hrefs are mirrored into the Fomio list. If any are mirrored, the component adds `fomio-activity-section-menu--mirrored-plugins` and SCSS hides duplicate native plugin `li` rows. If a plugin row mounts after the scan window, it may remain only in the native strip (documented limitation).

**Not changed:** Activity stream, routes, or other Me areas (Messages, Preferences, Invites, Notifications behavior).

---

## 13. Phase M2-D — Preferences (implemented)

**Shipped in theme (`apps/web/`):**

| Piece | Location |
|-------|----------|
| Section menu component | `javascripts/discourse/components/fomio-preferences-section-menu.gjs` |
| Connector | `javascripts/discourse/connectors/top-notices/fomio-preferences-section-menu.gjs` |
| Scoped SCSS | `common/common.scss` — `body.user-preferences-page:has(.fomio-preferences-section-menu)` (block after M2-C) |
| Aria label | `locales/en.yml` → `preferences_submenu.nav_aria` |

**Behavior:**

- Same **top-notices** mount and **`router.currentURL`** gating as M2-B / M2-C (`/my/preferences` and `/my/preferences/*`; `preferences.*` route name as fallback). Never outlet `currentPath`.
- **`in-element`** appends into `.user-navigation.user-navigation-secondary` with **`insertBefore=null`**; flex **`order: -1`** on the Fomio menu stacks it above the native pill strip.
- **Native suppression:** only when `:has(.fomio-preferences-section-menu)`, the nine core `li.user-nav__preferences-*` items from `preferences.gjs` are **`display: none`**. Class names are **enumerated** (not a `user-nav__preferences-*` substring) so plugin tabs such as **`user-nav__preferences-chat`** are not hidden by the core rule.
- **Tracking** row is included only when `controller:preferences.model.can_change_tracking_preferences` is true (same source as `preferences.gjs`).
- **Plugin rows:** non-core `li` elements under `ul.nav-pills` (e.g. from `user-preferences-nav` / related outlets) are scanned once the horizontal nav exists; label + `href` are mirrored into the Fomio list. If any are mirrored, the component adds **`fomio-preferences-section-menu--mirrored-plugins`** and SCSS hides duplicate native non-core `li` rows (same idea as M2-C). **Limitation:** rows that are not discoverable as `li` with an `a[href]` inside `ul.nav-pills` (late-mounting or unusual outlet DOM) may only appear in the native strip; **`user-preferences-nav-under-interface`** content that does not yield a matching `li` is not mirrored by this scan.
- **Not listed in Fomio core rows:** `preferences.apps`, `preferences.tags`, `preferences.email`, and `preferences.second-factor` are omitted unless they appear as normal nav rows on the site (they are not in core `preferences.gjs` pills).

**Not changed:** preference forms, save behavior, routes, Notifications, Activity, Messages, or Invites.

---

## 14. Phase M2-E — Invites (implemented)

**Shipped in theme (`apps/web/`):**

| Piece | Location |
|-------|----------|
| Section menu component | `javascripts/discourse/components/fomio-invites-section-menu.gjs` |
| Connector | `javascripts/discourse/connectors/top-notices/fomio-invites-section-menu.gjs` |
| Scoped SCSS | `common/common.scss` — `body.user-invites-page:has(.fomio-invites-section-menu)` (block after M2-D) |
| Aria label | `locales/en.yml` → `invites_submenu.nav_aria` |

**Behavior:**

- Same **top-notices** mount and **`router.currentURL`** gating as M2-B / M2-C / M2-D (`/^\/u\/[^/]+\/invited(\/|$)/`; `userInvited` route name prefix as fallback). Never outlet `currentPath`.
- **`in-element`** appends into `.user-navigation.user-navigation-secondary` with **`insertBefore=null`**; flex **`order: -1`** stacks the Fomio menu above the native strip.
- **Visibility:** native secondary nav (and `body.user-invites-page`) only exist when `can_see_invite_details` is true (`user-invited.gjs`). If the nav never appears, **`scheduleInsertion` does not resolve** and the Fomio menu does not mount — native behavior unchanged.
- **Native suppression:** when `:has(.fomio-invites-section-menu)`, the entire **`nav.horizontal-overflow-nav`** under invites secondary nav is hidden (core template has three `NavItem` pills and no plugin outlet; pills have no stable `user-nav__*` classes).
- **Rows:** Pending, Expired, Redeemed → `/u/:username/invited/pending|expired|redeemed`. Labels prefer **`controller:user-invited`** `pendingLabel` / `expiredLabel` / `redeemedLabel` (same counts as native tabs), with **`user.invited.*_tab`** fallbacks.
- **Active state:** `router.currentURL` path match (`/invited` and `/invited/pending` both count as Pending).

**Not changed:** invite lists, routes, permissions, Notifications, Activity, or Preferences.
