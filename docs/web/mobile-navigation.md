# Fomio mobile web — navigation model

## Me hub (touch shell)

On **landing surfaces only**, the Me hub mirrors Discourse’s canonical **primary** user navigation (Summary, Activity, Notifications, Messages, Invites, Badges, Preferences, staff “Manage user”, plus footer About and Sign out).

**Discourse owns** secondary navigation (e.g. Activity / Messages / Preferences pill rows) and **all leaf screens**.

The hub **does not render** on those leaf routes: native Discourse content owns the full viewport below the global chrome, while the Fomio bottom dock stays available per route rules.

### Activity (and other leaves)

**Activity** is a native Discourse leaf under Me (e.g. `/u/:username/activity`, `/activity/topics`, …). Fomio does **not** replace the Activity screen or its secondary pills. On touch, polish lives in **`common/common.scss`** (bundled with theme preview), scoped with Discourse’s native `body.user-activity-page` and `.user-navigation.user-navigation-secondary` + `ul.nav-pills` — not only `mobile/mobile.scss`. **Bookmarks** under the activity route still use `user-activity-page`; styling stays harmless for Saved-tab semantics (dock active state unchanged in JS).

**Messages** (private messages) is a native Discourse leaf under Me (`/u/:username/messages`, `/my/messages`, sent/new/unread/archive, etc.). Fomio does **not** replace the Messages screen or its tabs. On touch, polish in **`common/common.scss`** is scoped with `body.user-messages-page` (from Discourse `user/messages.gjs`): native `MessagesSecondaryNav` pills inside `HorizontalOverflowNav`, plus the messages topic list surface — same pill language as Activity where applicable.

**Preferences** is a native Discourse leaf under Me (`/my/preferences` and sub-routes such as account, security, profile, emails, notifications, tracking, interface, etc.; some builds may also show `/u/:username/preferences/*`). Fomio does **not** replace the Preferences UI or form logic. On touch, polish in **`common/common.scss`** uses `body.user-preferences-page` (Discourse `preferences.gjs`): native secondary `HorizontalOverflowNav` pills plus calmer typography and spacing for `#user-content.user-preferences` forms — inputs, select-kit, and save actions stay fully usable.

**Notifications**, **Invites**, and **Badges** are native Discourse leaves under Me (e.g. `/u/:username/notifications` and notification filter sub-routes; `/u/:username/invited` with pending/expired/redeemed; `/u/:username/badges`). Fomio path helpers also treat `/notifications` as Me-tab territory if that URL is hit. Fomio does **not** replace these screens or their logic. On touch, light polish in **`common/common.scss`** uses Discourse body classes `user-notifications-page` (`user-notifications.gjs`), `user-invites-page` (`user-invited.gjs` / `user-invited/show.gjs`), and `user-badges-page` (`user/badges.gjs`): ambient shell, rounded content wrapper, contextual pills where Discourse renders them, readable lists/tables/cards — actions, invite buttons, and badge links stay visible and usable.

### Landing surfaces

- `/my`, `/my/summary`
- `/u/:username`, `/u/:username/summary` (only when `:username` is the signed-in user)

### Implementation notes

- Path classification and tab/pill helpers live in `javascripts/discourse/lib/fomio-mobile-nav-paths.js`.
- The hub connector is `javascripts/discourse/connectors/below-site-header/fomio-me-hub.gjs`.
- There is no query-parameter Me menu, no body-class sync from the hub, and no Ember `afterRender` scheduling from hub getters for navigation state.
