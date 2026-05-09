# Fomio mobile web — Me second-level navigation

**Status:** Phases M2-B–M2-F **implemented** in `apps/web/` (Notifications, Activity, Preferences, Invites, Messages). Phase **M2-G** documents the stabilization pattern and limitations. Phase **M2-H1** (visual expanded Level 2 shell, mobile) is **implemented** in `apps/web/common/common.scss` and the five `fomio-*-section-menu` components; **QA** is recorded in **§18**. Phase **M2-H3** in-place expansion **feasibility audit** is in **§19** (no implementation commitment). Phase **M2-H** (§17) remains the broader exploration / guardrails doc. Section 1 below retains the original M2-A route and ownership model as reference.

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

---

## 15. Phase M2-F — Messages (implemented)

**Shipped in theme (`apps/web/`):**

| Piece | Location |
|-------|----------|
| Section menu component | `javascripts/discourse/components/fomio-messages-section-menu.gjs` |
| Connector | `javascripts/discourse/connectors/top-notices/fomio-messages-section-menu.gjs` |
| Scoped SCSS | `common/common.scss` — `body.user-messages-page:has(.fomio-messages-section-menu)` (block after M2-E) |
| Aria label | `locales/en.yml` → `messages_submenu.nav_aria` |

**Behavior:**

- Same **top-notices** mount and **`router.currentURL`** gating as prior M2 phases (`/^\/u\/[^/]+\/messages(\/|$)/`, `/^\/my\/messages(\/|$)/`, or route name prefix `userPrivateMessages`). Never outlet `currentPath`.
- **`in-element`** appends into `.user-navigation.user-navigation-secondary` with **`insertBefore=null`**; **`order: -1`** stacks the Fomio block above the native **MessagesDropdown** (`ol.category-breadcrumb`) and the pill strip.
- **User inbox rows** (when URL is not a group inbox): Latest, Sent, New, Unread (only if `controller:user.viewingSelf`), Archive — hrefs use the same path prefix as the current URL (`/u/.../messages` or `/my/messages`).
- **Group inbox rows** (`/messages/group/:name`): Latest; New, Unread, Archive only if **`viewingSelf`** — **no Sent** row (matches `user-private-messages/group.gjs`). Row order matches native.
- **New / Unread labels** prefer **`user-private-messages/user`** or **`user-private-messages/group`** `newLinkText` / `unreadLinkText` (counts via `pmTopicTrackingState`), with **`user.messages.new` / `user.messages.unread`** fallbacks.
- **Active state:** normalized path equality against each row’s target (Latest = inbox index only; PM tag routes under `/messages/tags/...` do not mark a core row active).
- **Native suppression:** when `:has(.fomio-messages-section-menu)`, hide only enumerated core `li` classes (`user-nav__messages-*` and `user-nav__messages-group-*`). Hide **`nav.horizontal-overflow-nav`** only when **no** non-core `li` remains (plugin or extra pills still show the strip). **`MessagesDropdown`** and **`navigation-controls`** are **not** hidden — group, tag, and **`registerCustomUserNavMessagesDropdownRow`** access stays intact.

**Limitations:**

- PM **tag** inbox routes are not duplicated in the Fomio list; users rely on the native dropdown (or direct URLs). Core rows may show no active item on tag-only views.
- If **`in-element`** never resolves after 36 animation frames, native pills stay visible.
- A plugin-added pill `li` whose class matches one of the enumerated `user-nav__messages-*` / `user-nav__messages-group-*` names could be hidden incorrectly (same class-collision caveat as M2-B).

**Not changed:** Notifications, Activity, Preferences, Invites, PM lists, routes, or permissions.

---

## 16. Phase M2-G — Stabilization (pattern, limits, testing)

### 16.1 Implemented areas

| Area | Component | Connector | SCSS block |
|------|-----------|-----------|------------|
| Notifications | `fomio-notifications-section-menu.gjs` | `connectors/top-notices/fomio-notifications-section-menu.gjs` | M2-B (`body.user-notifications-page`) |
| Activity | `fomio-activity-section-menu.gjs` | `connectors/top-notices/fomio-activity-section-menu.gjs` | M2-C (`body.user-activity-page`) |
| Preferences | `fomio-preferences-section-menu.gjs` | `connectors/top-notices/fomio-preferences-section-menu.gjs` | M2-D (`body.user-preferences-page`) |
| Invites | `fomio-invites-section-menu.gjs` | `connectors/top-notices/fomio-invites-section-menu.gjs` | M2-E (`body.user-invites-page`) |
| Messages | `fomio-messages-section-menu.gjs` | `connectors/top-notices/fomio-messages-section-menu.gjs` | M2-F (`body.user-messages-page`) |

### 16.2 Shared implementation pattern (all five)

1. **Outlet:** `top-notices` connector hosts the section component (see `discourse/.../application.gjs`).
2. **Gate:** `currentUser` must exist; path detection uses **`router.currentURL`** (strip query). **`router.currentRouteName`** is used only as a **fallback** when the URL pattern alone is insufficient (e.g. transitional states). **Never** use the outlet’s `currentPath` / `outletArgs` for URL matching — it is Ember’s dot path, not `/u/...`.
3. **DOM target:** `#main-outlet .user-main .user-navigation.user-navigation-secondary` with `:scope > nav.horizontal-overflow-nav` present (confirms native secondary nav has mounted). **No** dependency on `body` class timing before insertion; retries handle late layout.
4. **Retry:** `requestAnimationFrame` loop, **36** attempts, same idea across menus.
5. **Render:** `{{#in-element this.insertion.parent insertBefore=null}}` — **append only**; visual order uses **`order: -1`** on the Fomio `<nav>` inside a column flex container on `.user-navigation-secondary`.
6. **Host span:** `didInsert` → `scheduleInsertion`; `__host` span in `#main-container` is **`display: none`** under the matching **`body.user-*-page`** (scoped per area).
7. **Discourse ownership:** Routes, serializers, permissions, dismiss controls, dropdowns, forms, and lists stay native. Fomio only presents labeled links and scoped chrome suppression.
8. **Forbidden in this system:** `fomio-mobile-web-mode`, body-class sync for nav state, render-time side effects that mutate non-local state (plugin row extraction runs in the scheduled action after DOM is found, not from template-driven getters).

### 16.3 Route coverage (verification baseline)

**Notifications:** `/u/:username/notifications`, `.../responses`, `.../likes-received`, `.../mentions` (if `enable_mentions`), `.../edits`, `.../links`; global `/notifications` supported with `usernameFallback` from `currentUser`.

**Activity:** `/u/:username/activity`, `.../topics`, `.../replies`, `.../read`, `.../drafts`, `.../pending` (if count > 0), `.../likes-given`, `.../bookmarks`; conditional rows mirror `controller:user` / model fields.

**Preferences:** `/my/preferences`, `.../account`, `.../security`, `.../profile`, `.../emails`, `.../notifications`, `.../tracking` (if `can_change_tracking_preferences`), `.../users`, `.../interface`, `.../navigation-menu`.

**Invites:** `/u/:username/invited`, `.../pending`, `.../expired`, `.../redeemed`; Pending active for index and `/pending`.

**Messages:** `/u/:username/messages` (+ `sent`, `new`, `unread`, `archive` when applicable), `/my/messages` (+ same suffixes); **group** `/u/.../messages/group/:name` (or `/my/messages/group/:name`) with native row set; **tag** and custom inbox paths remain **dropdown / native** only (see limitations).

### 16.4 Plugin and dropdown strategy

| Area | Strategy |
|------|----------|
| **Notifications** | Core `li.user-nav__notifications-*` hidden when Fomio mounts; `user-notifications-bottom` rows usually remain in native strip unless their `li` reuses a core class substring (document per plugin). |
| **Activity** | Scan `ul.nav-pills` once nav exists; mirror non-core `li` into Fomio list; `--mirrored-plugins` hides duplicate native plugin `li`. Late-mounting plugins may only appear natively. |
| **Preferences** | Core classes enumerated; plugin tabs (e.g. `user-nav__preferences-chat`) stay in native strip unless mirrored; `--mirrored-plugins` hides mirrored duplicates. |
| **Invites** | No plugin outlet in core template; entire `horizontal-overflow-nav` hidden when Fomio mounts. |
| **Messages** | **MessagesDropdown** (`ol.category-breadcrumb`), **navigation-controls**, and custom dropdown rows stay visible; only enumerated core pill `li` classes are hidden; `horizontal-overflow-nav` hidden only when no extra non-core pills remain. |

### 16.5 Known limitations (non-exhaustive)

- **Insertion:** If `.user-navigation-secondary` / `horizontal-overflow-nav` never appears within the retry window, the Fomio menu does not mount and native UI remains (by design).
- **Class collisions:** Plugin `li` classes that reuse `user-nav__notifications-*`, `user-nav__activity-*`, or enumerated `user-nav__messages-*` / `user-nav__messages-group-*` names may be hidden incorrectly.
- **Activity / Notifications:** Substring rules `[class*="user-nav__…"]` can mis-classify a badly named plugin; treat as site-specific.
- **Preferences:** Outlet DOM that is not a normal `li` + `a[href]` under `ul.nav-pills` may not mirror.
- **Messages:** PM **tag** routes and some deep paths do not map a Fomio “active” row; users use the native dropdown or bookmarks.
- **Global `/notifications`:** Relies on `currentUser.username` for `/u/:username/notifications` hrefs.

### 16.6 Testing checklist (manual)

- [ ] Logged **out:** no Fomio section menus; native nav unchanged.
- [ ] Each area: navigate every **core** route above; Fomio list shows correct **active** state; native leaf content unchanged.
- [ ] **Notifications:** with `enable_mentions` on/off; plugin row (if any) still reachable.
- [ ] **Activity:** Read/Drafts/Bookmarks/Pending visibility matches profile; plugin row (e.g. solved) if installed.
- [ ] **Preferences:** Tracking tab respects `can_change_tracking_preferences`; plugin tab visible and/or mirrored.
- [ ] **Invites:** only when `can_see_invite_details`; three filters and counts match native labels when controller present.
- [ ] **Messages:** user inbox vs **group** inbox vs `/my/messages`; New/Unread only for **self**; dropdown opens for group/tag; no horizontal overflow on narrow viewport.
- [ ] **Resize / soft nav:** no stray blank secondary strip when Fomio menu absent.

### 16.7 Future refactor notes

- **Shared helper extraction:** Optional **only** if kept tiny (e.g. `pathNoQuery(router)`, `scheduleSecondaryNavInsertion({ isRoute, onFound })`) — **not** recommended in this phase unless duplication becomes a maintenance burden. Do **not** introduce a generic “menu engine” or collapse plugin handling into one abstraction.

---

## 17. Phase M2-H — Expandable Level 2 shell exploration

**Nature:** Exploration only. Do **not** fetch custom API data, rebuild native Discourse leaf screens, replace Activity / Notifications / Preferences / Invites / Messages content, or move forms or streams into custom data components.

### 17.1 Concept

Today (M2-B–F), **Level 1** is the Me landing; **Level 2** is a Fomio section menu stacked above native secondary chrome; **Level 3** is native Discourse content (lists, streams, forms) unchanged.

**M2-H explores** a more premium **mobile-web** read: Level 2 becomes an **expandable** Fomio section list where the **selected row** feels like it **opens** the content beneath it — one continuous surface — while **Level 3 stays fully native** (same routes, same DOM, same behavior). The row **navigates** (canonical URL); the **route** renders the content; Fomio uses **layout and CSS** so the transition reads as “drawer from the row” rather than “menu, then another page.”

### 17.2 Product rule

- **Level 2 may expand** (presentation).
- **Level 3 must remain native** (Discourse owns data, permissions, saves, pagination, dismiss controls, dropdowns).
- **Source of truth for active section:** `router.currentURL` (path without query), with `router.currentRouteName` only as a **fallback** where URL alone is ambiguous — same rule as M2-G. **Do not** use outlet `currentPath` / `outletArgs` for URL matching.

### 17.3 Why no API replacement

Discourse already owns streams, filters, notification state, PM tracking, invite lists, and every preference form field. Duplicating that data in the theme would:

- violate the **single source of truth** (stale counts, wrong gates, broken plugins),
- multiply **permission and Guardian** edge cases,
- break **plugin outlets** and custom rows that assume native templates,
- and require ongoing maintenance for every Discourse upgrade.

The exploration intentionally limits itself to **chrome and layout**, not parallel Level 3 screens.

### 17.4 Proposed visual behavior

1. **Active row expansion (accordion cue):** On the route that matches the active Level 2 link, the active item gets stronger hierarchy (e.g. larger label, tinted surface, optional chevron or left rail) and **vertical space** so it reads as a “header” for the content below. Inactive siblings stay as compact rows or chips (exact styling TBD in H1).
2. **Visual attachment to native content:** Without reparenting, apply a **shared panel treatment**: matching background on the Fomio menu block and the native content region immediately below (`#main-outlet .user-main` subtree), **collapsed internal gaps** (negative margin or reduced padding on the boundary), and consistent **corner radius** only where it does not clip overflow lists. The native **list / topic body / form** stays in place; only **spacing and surfaces** align.
3. **Route transitions:** Rely on normal Ember transitions; avoid hiding native content until the attachment illusion is stable (see risks). Prefer **opacity / background** continuity over animating the whole outlet if flashes appear.

### 17.5 Screen-by-screen suitability

| Area | Accordion-like expansion (strong “row opens content”) | Rationale |
|------|--------------------------------------------------------|-----------|
| **Activity** | **Suitable** | Stream-first; secondary nav is filter-like; fewer embedded controls in the nav band than Preferences. Plugin pills must remain reachable (mirrored or native strip). |
| **Notifications** | **Suitable** | List + dismiss patterns; active filter maps cleanly to URL segments. Watch dismiss row and plugin `user-notifications-bottom` rows. |
| **Invites** | **Suitable** | Three stable tabs; list content below. Low dropdown complexity. |
| **Messages** | **Suitable with constraints** | Pills accordion well for **user** and **group** inboxes, but **MessagesDropdown** (group inboxes, tags, `registerCustomUserNavMessagesDropdownRow`) must stay **fully native and visible**. Do not treat the dropdown as “just another row” — expansion styling applies to the **Fomio list + attached panel**, not to replacing dropdown behavior. Tag-only routes may show **no** active Fomio row (existing M2-F limitation). |

| Area | Softer “active section header + content panel” | Rationale |
|------|-----------------------------------------------|-----------|
| **Preferences** | **Prefer this over aggressive accordion** | Every sub-route is a **form** (save bars, validation, plugin tabs). Aggressive expansion or hiding chrome can imply the wrong **focus order** or **scroll containment**. Use a calm **active tab as section header** + single **content panel** rhythm; do not blindly apply the same motion/scale as Activity/Notifications. **Plugin tabs** (`user-preferences-nav*`) must not be collapsed away or duplicated incorrectly. |

### 17.6 Technical constraints

- **URLs:** Keep canonical paths (`/u/...`, `/my/preferences/...`, etc.); no parallel routes for the same content.
- **No DOM reparenting in H1:** Do not move `#main-outlet` children or form roots in the first pass; attachment is **CSS-only** (wrappers already implied by Discourse structure may receive classes only if a safe outlet/transformer exists — prefer SCSS on known selectors).
- **Native transitions:** Do not intercept `link-to` / router in ways that break back button, scroll restoration, or loading substates.
- **Mobile-only:** Scope experimental layout under Discourse’s mobile stylesheet and/or `max-width` media queries so desktop shell assumptions stay intact.
- **Active detection:** Match **href path segments** to `router.currentURL` (normalized, no query), consistent with existing `fomio-*-section-menu` components.

### 17.7 Safest CSS hooks (initial)

Use only **scoped** theme selectors (`fomio-` classes on Fomio-owned nodes; body/page classes for context). Starting points already in use or documented:

| Concern | Hook |
|---------|------|
| **Page context** | `body.user-activity-page`, `body.user-notifications-page`, `body.user-preferences-page`, `body.user-invites-page`, `body.user-messages-page` |
| **Fomio Level 2 root** | `.fomio-activity-section-menu`, `.fomio-notifications-section-menu`, `.fomio-preferences-section-menu`, `.fomio-invites-section-menu`, `.fomio-messages-section-menu` |
| **Active row** | `.fomio-*-section-menu__link.is-active` (or equivalent `aria-current="page"` styling) — derive from same URL logic as today |
| **Secondary nav stack** | `#main-outlet .user-main .user-navigation.user-navigation-secondary` (Fomio `in-element` parent + native overflow nav) |
| **Native content / spacing collapse** | `.user-main` / `.user-content` / outlet children under `#main-outlet` — **verify per template** in `discourse/` before negative margins; avoid clipping `position: sticky` bars |
| **Panel background** | Shared `--fomio-*` / `--d-*` tokens on Fomio nav + adjacent native wrapper (specific selector TBD per page after visual audit) |
| **Mobile-only** | `mobile/mobile.scss` or `@media (max-width: …)` aligned with theme breakpoints |

### 17.8 Risks

| Risk | Notes |
|------|------|
| **Forms (Preferences)** | Save bars, in-form errors, and multi-section scroll; aggressive accordion can confuse **focus** or hide **unsaved** affordances. |
| **Message dropdowns** | Group PMs, tags, custom rows; expansion must not **cover** or **disable** `MessagesDropdown` / `navigation-controls`. |
| **Plugin rows** | Activity, Notifications, Preferences rely on outlets; mirrored rows can **lag**; hiding native rows without a mirror **breaks** access. |
| **Late-rendered content** | `requestAnimationFrame` insertion already races; expansion CSS must not assume synchronous DOM for counts or plugin pills. |
| **Pagination / infinite scroll** | Negative margins or overflow on list containers can clip **sentinels** or sticky headers — test long Activity / notification lists. |
| **Route transition flashes** | Outlet re-render may briefly show **unstyled** gap between menu and content; may need transition-delayed background or **min-height** guard — validate on real devices. |
| **Dismiss / bulk actions (Notifications)** | Secondary controls share the nav region; spacing collapse must not **obscure** dismiss UI. |
| **Invites** | Low complexity but list empty states must remain **visible** when panel background wraps content. |

### 17.9 Recommended implementation path

| Phase | Scope |
|-------|--------|
| **H1** | **Visual expansion only:** active row styling + panel background / spacing attachment; native Level 3 DOM unchanged; prove illusion on one pilot area (e.g. Notifications or Invites) then roll forward. |
| **H2** | **Compact inactive rows** after route load (density), still URL-driven; guard plugin and dropdown parity. |
| **H3** | **Optional content-slot experiment** only if H1–H2 are stable — e.g. decorative wrapper via **safe** outlet — **not** moving forms or streams; abort if any save or scroll regression appears. |

### 17.10 Do-not list (M2-H)

- Do not fetch replacement API data or invent parallel Level 3 screens.
- Do not reparent forms or streams in the first pass.
- Do not hide native content before the attachment treatment is **proven** (no blank flash, no lost controls).
- Do not break canonical URLs or native route transitions.
- Do not break plugin rows or message dropdowns.
- Do not break preference **save** behavior or validation UX.
- Do not apply the **same** accordion expansion language to **Preferences** as to list-first areas without a softer panel variant.

### 17.11 No-go areas (until explicitly re-scoped)

- Replacing notification / activity / message / invite **streams** with theme-fetched data.
- Inlining **preference forms** in custom components.
- Removing or **visually masking** Messages **dropdown** or dismiss controls for the sake of a cleaner stack.
- **Globally** hiding `.user-navigation-secondary` without `:has(.fomio-*-section-menu)` or equivalent safe guard (existing M2 pattern).

---

## 18. M2-H1 QA — Preview theme validation

Tested on `meta.fomio.app` at mobile width **390×844** as user **Soma** using:

`?preview_theme_id=33`

This query string **must be present** while judging the preview theme. SPA transitions **retained** the query string during this QA pass, but **server redirects may drop it**. In particular, `/my/preferences/account?preview_theme_id=33` redirected to `/u/Soma/preferences/account` **without** the preview parameter, so QA should prefer canonical **`/u/:username/preferences/...?preview_theme_id=33`** paths or **manually re-append** the parameter after redirects. (See also [Redirects on load remove URL parameters](https://meta.discourse.org/t/redirects-on-load-remove-url-parameters/282136) on Meta.)

### 18.1 Validated priority areas

- `/u/soma/notifications?preview_theme_id=33`
- `/u/soma/activity?preview_theme_id=33`
- `/u/soma/messages?preview_theme_id=33`
- `/u/soma/preferences/account?preview_theme_id=33`
- `/u/soma/invited/pending?preview_theme_id=33`

### 18.2 Validated subroutes

- `/u/soma/notifications/responses?preview_theme_id=33`
- `/u/soma/activity/topics?preview_theme_id=33`
- `/u/soma/activity/replies?preview_theme_id=33`
- `/u/soma/messages/sent?preview_theme_id=33`
- `/u/soma/preferences/security?preview_theme_id=33`
- `/u/soma/preferences/profile?preview_theme_id=33`

### 18.3 Observed result

- Fomio **vertical section menus** rendered across all tested Me sub-areas.
- **Active rows** matched the current route.
- Native **core horizontal pills** were suppressed.
- **Plugin rows** such as Votes / Calendar remained exposed where expected.
- **Native content** remained usable.
- **Bottom dock** remained present.
- **Notifications** dismiss control, **Messages** inbox / new-message controls, **Invites** create action, and **Preferences** form actions remained available.
- No obvious **horizontal overflow** was observed.
- **Theme preview banner** was the only expected extra chrome.

### 18.4 Recommendation

**Keep M2-H1.** Do not proceed to **H2** until the same preview is reviewed visually by design. Tune only panel contrast, padding, active-row emphasis, and spacing if needed.

---

## 19. Phase M2-H3-Audit — In-place expansion feasibility

**Nature:** Architecture audit only (no implementation in this phase). Goal: assess whether **native Level 3** can appear **inside** the active Level 2 “card” (Option 3) while Discourse still owns routes, controllers, data, and leaf templates.

**Evidence:** Discourse templates under `discourse/frontend/discourse/app/templates/` as cited below (read-only).

### 19.1 Wrapper outlets around the Me shell

| Location | Outlets / structure | Wraps nav + `#user-content` together? |
|----------|---------------------|----------------------------------------|
| **`user.gjs`** | Many profile outlets (`above-user-profile`, `before-user-profile-avatar`, …); **`div.new-user-content-wrapper`** contains only `{{outlet}}` — **no** `PluginOutlet` around that wrapper or around the profile outlet stack + content. | **No** |
| **`user-activity.gjs`** | `PluginOutlet @name="user-activity-navigation-wrapper"` wraps **only** `div.user-navigation.user-navigation-secondary` (default block). `section#user-content` is a **sibling after** the outlet closes. | **No** (nav-only wrapper) |
| **`user-notifications.gjs`** | `PluginOutlet @name="user-notifications-bottom"` is **inside** the horizontal nav (`li` connectors). `section#user-content` is **outside** the nav `div`. `navigation-controls` (dismiss) sits **inside** `.user-navigation-secondary` between pills and content. | **No** |
| **`user-invited.gjs`** | No `PluginOutlet`. Structure: optional `div.user-navigation-secondary` + **`{{outlet}}`** (child route renders invite UI). | **No** |
| **`user-invited/show.gjs`** | Leaf: root is **`LoadMore`** with `@id="user-content"` and class `user-content`; holds controls, tables, empty states, pagination. | **No** theme outlet; content is one component root |
| **`preferences.gjs`** | `PluginOutlet` names `user-preferences-nav-under-interface`, `user-preferences-nav`, `above-user-preferences` — all **inside** nav or **inside** `section#user-content`, not wrapping both. | **No** |
| **`user/messages.gjs`** | `PluginOutlet @name="user-messages-above-navigation"` is **above** `.user-navigation-secondary` only. `section#user-content` follows the nav block (dropdown + pills + controls). | **No** |
| **`user-private-messages/user.gjs`** | `MessagesSecondaryNav` + `{{outlet}}` (no shell outlet). Parent **`user/messages.gjs`** owns dropdown + layout. | **No** |
| **`user-private-messages/group.gjs`** | `MessagesSecondaryNav` + `div.group-messages` + `{{outlet}}`. | **No** |

**Conclusion:** Discourse core does **not** expose a **single supported outlet** that wraps `.new-user-content-wrapper`, `.user-navigation.user-navigation-secondary`, and `#user-content` in one composable boundary. The only nearby outlet, **`user-activity-navigation-wrapper`**, is explicitly **navigation-only**; content is intentionally **outside** it.

### 19.2 True in-place expansion without reparenting?

**Not with theme-only markup today.** Option 3 requires Level 3 DOM **inside** the active Level 2 row/card. Core templates keep **`#user-content` (or the invite `LoadMore` root)** as a **sibling** of `.user-navigation-secondary` (or as the outlet child of `user-invited`), not nested under a row.

- **CSS-only “fake” nesting** (H1-style): already possible — sibling content visually attached; **not** true DOM containment.
- **Theme `in-element`**: can inject **parallel** UI into an existing parent; it does **not** move Discourse’s `{{outlet}}` output into a Fomio row without **moving existing DOM nodes**.
- **Without core/plugin template changes:** achieving **real** containment implies **manual DOM reparenting** (`appendChild` / `insertBefore`) of the live `#user-content` (or invite `LoadMore`) node into a Fomio card container.

### 19.3 Manual reparenting — is it required for Option 3?

**Yes**, for true in-place expansion as defined (L3 **inside** the active card), **unless** Discourse adds a wrapping outlet or restructures templates (plugin or core).

### 19.4 Safest prototype section (ranked)

| Rank | Section | Rationale |
|------|---------|-----------|
| **1** | **Invites** | No secondary dropdown; parent template is **nav + outlet**; leaf content is a **single `LoadMore`** root with `id="user-content"`. Fewer interaction surfaces than Messages/Notifications. |
| **2** | **Notifications** | Clear nav/content split, but **dismiss** lives inside `.user-navigation-secondary`; reparenting only `#user-content` leaves dismiss **above** the “card” unless the whole nav column is restructured — higher UX/layout risk. |
| **3** | **Activity** | `user-activity-navigation-wrapper` does not include content; infinite scroll + plugin pills; more moving parts. |
| **4** | **Messages** | **MessagesDropdown**, group/tag contexts, controls — **do not** prototype reparenting here first (per product guardrails). |
| **5** | **Preferences** | **Forms**, validation, save bars — **out of scope** for reparenting prototype (explicit do-not). |

### 19.5 Reparenting risks (by section)

| Section | Risks |
|---------|--------|
| **Invites** | Ember may **re-render** and **replace** the `LoadMore` root on route/filter change — reparented node may be **destroyed** or **duplicated**; **scroll / load-more sentinel** and observers may assume original parent geometry; **empty states** must remain inside the moved subtree; **focus** and **table** layout may reflow oddly inside a card. |
| **Notifications** | Splitting dismiss from stream if only `#user-content` moves; route transitions and **dismiss** visibility; plugin `user-notifications-bottom` rows. |
| **Activity** | Long lists, **LoadMore**, sticky headers, plugin rows; higher chance of **jank** or broken infinite scroll. |
| **Messages** | Dropdown portals, **bulk select**, group tracking — high breakage probability. |
| **Preferences** | Form lifecycle, rich editor, plugin tabs — **unacceptable** risk for first prototype. |

### 19.6 Rollback rules (if a reparenting spike is attempted)

1. If **source node** (`#user-content` / invite `LoadMore` root) is missing, **do nothing**.
2. If **target** Fomio card body is missing, **do nothing**.
3. On **route change** or **component teardown**, **restore** the node to its **documented original parent** or rely on full route re-render — **never** leave `#user-content` detached in the DOM.
4. **Never** hide native content to mask a failed move.
5. Prefer **idempotent** setup/teardown (e.g. `willDestroy` / router event) so navigation **always** returns to a valid state.

### 19.7 Go / no-go recommendation

| Question | Verdict |
|----------|---------|
| **Theme-only true in-place expansion (DOM inside active row) without reparenting or core change?** | **No-go** — no wrapper outlet spans nav + leaf content. |
| **Optional R&D spike: manual reparent on one low-risk section behind a flag?** | **Conditional go** — **Invites only**, non-production, with rollback rules in §19.6 and acceptance tests for LoadMore, empty states, and route transitions. |
| **Production Option 3 without hacks?** | **Go** only via **Discourse extension** (new `PluginOutlet` or template restructuring) so Glimmer owns the hierarchy — recommend **ADR + plugin or upstream** path rather than permanent theme `appendChild`. |

### 19.8 Prototype scope (if conditional go)

- **Single area:** **Invites** (`user-invited` + `user-invited/show`), mobile-only, feature-flagged.
- **Move target:** the **invite `LoadMore` element** (`#user-content`) into a dedicated **Fomio card body** that is **not** recreated by Ember on every paint (stable wrapper).
- **Out of scope:** Preferences, Messages, generic multi-section reparenting engine, hiding native UI, API duplication.

### 19.9 Do-not list (M2-H3)

- Do not fetch Discourse APIs for replacement data or duplicate leaf streams.
- Do not start with **Preferences** or **Messages**.
- Do not reparent **form** screens.
- Do not ship a **generic** reparenting engine across all Me sections without per-section audits.
- Do not hide native content as a fallback for failed moves.
- Do not break canonical URLs or router-owned transitions.
