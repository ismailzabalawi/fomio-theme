# Fomio Preferences — Information Architecture Map

Canonical IA for every preferences surface: the `apps/web` theme, the Expo app
(`apps/mobile`), and the CLI (`apps/cli`).

Discourse is the source of truth. This map does **not** invent an IA — it
records the one Discourse already enforces, assigns each field a single owning
section, and marks which surfaces may render it.

**Source of record**

| Fact | Derived from |
|---|---|
| Section list + routes | `apps/web/javascripts/discourse/lib/fomio-preferences-sections.js` |
| Fields per section | `discourse/frontend/discourse/app/controllers/preferences/*.js` → `saveAttrNames` |
| Persisted field set | `discourse/app/serializers/user_option_serializer.rb` |
| Security surface | `discourse/frontend/discourse/app/templates/preferences/security.gjs` |
| Product nouns | `apps/mobile/docs/00-product/terminology.md` |

---

## 1. Ownership tiers

Parity does not mean identical. Every field sits in exactly one tier, and the
tier decides which surfaces render it.

| Tier | Meaning | Storage | Web | Mobile | CLI |
|---|---|---|---|---|---|
| **S** — Shared | Server-owned, cross-client meaning. Same DB row everywhere. | Discourse `User` / `UserOption` | ✓ | ✓ | ✓ |
| **W** — Web-surface | Server-owned but only meaningful in a browser. | Discourse `UserOption` | ✓ | ✗ | ✗ |
| **D** — Device | Client-local. No server row, no cross-client meaning. | AsyncStorage / config file | ✓ (own set) | ✓ (own set) | ✓ (own set) |

**Rule:** a tier-S field must never be mirrored into device storage. A tier-W
field must never be ported to mobile "for consistency" — it has no meaning
there. A tier-D setting must never be presented inside a tier-S section.

---

## 2. Section tree

Order is the canonical presentation order for all surfaces.

```
Preferences
├── 1. Account ................ identity, email, connected accounts        [S]
├── 2. Security ............... password, passkeys, 2FA, active sessions   [S]
├── 3. Profile ................ bio, links, birthday, timezone            [S]
├── 4. Emails ................. delivery levels, digests, mailing list    [S]
├── 5. Notifications .......... what pings you, and how often             [S]
├── 6. Terets & Hubs .......... per-space notification levels             [S]
├── 7. Tags ................... per-tag notification levels               [S]  ⚠ missing
├── 8. People ................. muted people, who may message you         [S]
├── 9. Interface .............. locale, text size, reading behaviour      [S/W]
├── 10. Navigation menu ....... sidebar behaviour                         [W]
└── 11. Connected apps ........ user API keys, revoke access              [S]  ⚠ missing
─────────────────────────────────────────────────────────────────────────────
App (device tier — not part of the Discourse tree)
├── Appearance ................ theme mode                                [D]
├── Reading ................... feed layout                               [D]
├── Storage ................... cache size, offline mode                  [D]
└── About ..................... version, support, rate, legal             [D]
```

`⚠ missing` = the section exists in Discourse and carries tier-S fields, but is
absent from `FOMIO_PREFERENCES_SECTIONS`, so no Fomio surface currently reaches
it. See §5.

---

## 3. Field map

`Own` marks the single section responsible for writing the field. Fields
appearing in more than one Discourse controller are resolved in §4.

### 1. Account — `/my/preferences/account`

| Field | Tier | Control | Own |
|---|---|---|---|
| `username` | S | text + confirm | ✓ |
| `name` | S | text | ✓ |
| `title` | S | picker (earned titles) | ✓ |
| `status` | S | emoji + text | ✓ |
| `primary_group_id` | S | picker | ✓ |
| `flair_group_id` | S | picker | ✓ |
| primary email | S | `/my/preferences/email` | ✓ |
| secondary emails | S | list + add | ✓ |
| `associated_accounts` | S | list + connect/disconnect | ✓ |
| delete account | S | destructive action | ✓ |

Saved via `saveAttrNames`: `name`, `title`, `primary_group_id`,
`flair_group_id`, `status`. Username, email, and deletion use dedicated
endpoints.

### 2. Security — `/my/preferences/security`

No `saveAttrNames` — every row is a dedicated endpoint or sub-route.

| Field | Tier | Control | Own |
|---|---|---|---|
| password | S | set / change / remove | ✓ |
| passkeys | S | list + add/remove | ✓ |
| two-factor | S | `/my/preferences/second-factor` | ✓ |
| auth tokens | S | session list (browser, last seen, location) | ✓ |
| log out all | S | destructive action | ✓ |

### 3. Profile — `/my/preferences/profile`

| Field | Tier | Control | Own |
|---|---|---|---|
| `bio_raw` | S | textarea | ✓ |
| `website` | S | url | ✓ |
| `location` | S | text | ✓ |
| `date_of_birth` | S | date | ✓ |
| `timezone` | S | picker | ✓ |
| `default_calendar` | S | picker | ✓ |
| `profile_background_upload_url` | S | image upload | ✓ |
| `card_background_upload_url` | S | image upload | ✓ |
| `user_fields` | S | site-defined | ✓ |
| `custom_fields` | S | site-defined | ✓ |
| `hide_profile` | S | toggle | ✓ |

### 4. Emails — `/my/preferences/emails`

| Field | Tier | Control | Own |
|---|---|---|---|
| `email_level` | S | picker | ✓ |
| `email_messages_level` | S | picker | ✓ |
| `email_digests` | S | toggle | ✓ |
| `digest_after_minutes` | S | picker | ✓ |
| `include_tl0_in_digests` | S | toggle | ✓ |
| `mailing_list_mode` | S | toggle | ✓ |
| `mailing_list_mode_frequency` | S | picker | ✓ |
| `email_in_reply_to` | S | toggle | ✓ |
| `email_previous_replies` | S | picker | ✓ |

### 5. Notifications — `/my/preferences/notifications`

| Field | Tier | Control | Own |
|---|---|---|---|
| `like_notification_frequency` | S | picker | ✓ |
| `notify_on_linked_posts` | S | toggle | ✓ |
| `user_notification_schedule` | S | weekly schedule | ✓ |
| `allow_private_messages` | S | toggle | → §8 |
| `enable_allowed_pm_users` | S | toggle | → §8 |
| `muted_usernames` | S | user picker | → §8 |
| `auto_track_topics_after_msecs` | S | picker | → §6 |
| `new_topic_duration_minutes` | S | picker | → §6 |
| `notification_level_when_replying` | S | picker | → §6 |

### 6. Terets & Hubs — `/my/preferences/tracking`

Discourse calls this *tracking* over *categories*. Fomio labels it with product
nouns: a Hub is a parent category, a Teret a child category, a Byte a topic.

| Field | Tier | Control | Own |
|---|---|---|---|
| `watched_category_ids` | S | Teret/Hub picker | ✓ |
| `tracked_category_ids` | S | Teret/Hub picker | ✓ |
| `watched_first_post_category_ids` | S | Teret/Hub picker | ✓ |
| `muted_category_ids` | S | Teret/Hub picker | ✓ |
| `regular_category_ids` | S | replaces `muted_category_ids` when `mute_all_categories_by_default` | ✓ |
| `watched_precedence_over_muted` | S | toggle | ✓ |
| `topics_unread_when_closed` | S | toggle | ✓ |
| `new_topic_duration_minutes` | S | picker | ✓ |
| `auto_track_topics_after_msecs` | S | picker | ✓ |
| `notification_level_when_replying` | S | picker | ✓ |

### 7. Tags — `/my/preferences/tags` ⚠

| Field | Tier | Control | Own |
|---|---|---|---|
| `watched_tags` | S | tag picker | ✓ |
| `watching_first_post_tags` | S | tag picker | ✓ |
| `tracked_tags` | S | tag picker | ✓ |
| `muted_tags` | S | tag picker | ✓ |

### 8. People — `/my/preferences/users`

| Field | Tier | Control | Own |
|---|---|---|---|
| `muted_usernames` | S | user picker | ✓ |
| `allowed_pm_usernames` | S | user picker | ✓ |
| `allow_private_messages` | S | toggle | ✓ |
| `enable_allowed_pm_users` | S | toggle | ✓ |

### 9. Interface — `/my/preferences/interface`

The only mixed-tier section. Split it explicitly rather than rendering one list.

| Field | Tier | Control | Own |
|---|---|---|---|
| `locale` | S | picker | ✓ |
| `text_size` | S | picker | ✓ |
| `interface_color_mode` | S | picker | ✓ |
| `color_scheme_id` | S | picker | ✓ |
| `dark_scheme_id` | S | picker | ✓ |
| `homepage_id` | S | picker | ✓ |
| `hide_presence` | S | toggle | ✓ |
| `enable_quoting` | S | toggle | ✓ |
| `enable_smart_lists` | S | toggle | ✓ |
| `enable_defer` | S | toggle | ✓ |
| `enable_markdown_monospace_font` | S | toggle | ✓ |
| `automatically_unpin_topics` | S | toggle | ✓ |
| `bookmark_auto_delete_preference` | S | picker | ✓ |
| `skip_new_user_tips` | S | toggle | ✓ |
| `seen_popups` | S | internal | ✓ |
| `external_links_in_new_tab` | **W** | toggle | ✓ |
| `dynamic_favicon` | **W** | toggle | ✓ |
| `title_count_mode` | **W** | picker | ✓ |
| `allow_private_messages` | S | toggle | → §8 |
| `enable_allowed_pm_users` | S | toggle | → §8 |

### 10. Navigation menu — `/my/preferences/navigation-menu`

| Field | Tier | Control | Own |
|---|---|---|---|
| `sidebar_link_to_filtered_list` | **W** | toggle | ✓ |
| `sidebar_show_count_of_new_items` | **W** | toggle | ✓ |

Entirely tier-W. Mobile and CLI omit this section — they have no sidebar, so
there is nothing to keep in parity.

### 11. Connected apps — `/my/preferences/apps` ⚠

| Field | Tier | Control | Own |
|---|---|---|---|
| user API keys | S | list: app name, scopes, last used | ✓ |
| revoke key | S | destructive, per row | ✓ |
| revoke all | S | destructive | ✓ |

This is the surface that lists and revokes the `user_api_key` credentials every
Fomio client holds. It is the terminal point of the auth flow described in the
root `CLAUDE.md`.

---

## 4. Fields claimed by more than one section

Six tier-S fields are writable from two or three Discourse controllers. Each
controller `save()` sends only its own `saveAttrNames`, so two sections editing
one field is last-writer-wins, and a stale form silently reverts the other.

| Field | Discourse controllers | Owning section |
|---|---|---|
| `allow_private_messages` | notifications, users, interface | **People** |
| `enable_allowed_pm_users` | notifications, users, interface | **People** |
| `muted_usernames` | notifications, users | **People** |
| `auto_track_topics_after_msecs` | notifications, tracking | **Terets & Hubs** |
| `new_topic_duration_minutes` | notifications, tracking | **Terets & Hubs** |
| `notification_level_when_replying` | notifications, tracking | **Terets & Hubs** |

**Rule:** exactly one Fomio section renders an editable control for each field.
Other sections may show it read-only with a link to the owner, or omit it. This
is an IA decision, not a Discourse change — native web keeps its duplicates.

---

## 5. Gaps against the current theme

`FOMIO_PREFERENCES_SECTIONS` lists nine sections. Discourse serves fourteen
preference templates. The difference:

| Discourse route | In theme list? | Disposition |
|---|---|---|
| `account` | ✓ | — |
| `security` | ✓ | — |
| `profile` | ✓ | — |
| `emails` | ✓ | — |
| `notifications` | ✓ | — |
| `tracking` | ✓ | — |
| `users` | ✓ | — |
| `interface` | ✓ | — |
| `navigation-menu` | ✓ | — |
| `tags` | ✗ | **Add.** Four tier-S fields unreachable. |
| `apps` | ✗ | **Add.** Fomio's own API-key revoke surface. |
| `email` | ✗ | Sub-route of Account — correct to omit as a peer. |
| `second-factor` | ✗ | Sub-route of Security — correct to omit as a peer. |
| `categories` | ✗ | Superseded by `tracking` — correct to omit. |

Note the theme's `tracking` entry uses `icon: "plus"`, which carries no meaning
for per-space notification levels. A bell or stack icon matches the section.

---

## 6. Route map per surface

| Section | Web (theme) | Mobile (Expo Router) | CLI |
|---|---|---|---|
| Account | `/my/preferences/account` | `(profile)/settings/account` | `fomio prefs account` |
| Security | `/my/preferences/security` | `(profile)/settings/security` | `fomio prefs security` |
| Profile | `/my/preferences/profile` | `(profile)/settings/profile` | `fomio prefs profile` |
| Emails | `/my/preferences/emails` | `(profile)/settings/emails` | `fomio prefs emails` |
| Notifications | `/my/preferences/notifications` | `(profile)/settings/notifications` | `fomio prefs notifications` |
| Terets & Hubs | `/my/preferences/tracking` | `(profile)/settings/terets` | `fomio prefs terets` |
| Tags | `/my/preferences/tags` | `(profile)/settings/tags` | `fomio prefs tags` |
| People | `/my/preferences/users` | `(profile)/settings/people` | `fomio prefs people` |
| Interface | `/my/preferences/interface` | `(profile)/settings/interface` | `fomio prefs interface` |
| Navigation menu | `/my/preferences/navigation-menu` | — | — |
| Connected apps | `/my/preferences/apps` | `(profile)/settings/apps` | `fomio prefs apps` |
| App (device) | — | `(profile)/settings` root | `fomio config` |

Existing mobile routes `(profile)/notification-settings` and
`(profile)/blocked-users` are pre-IA placeholders. They map onto
`settings/notifications` and `settings/people` respectively.

---

## 7. Surface rendering contract

**Web (`apps/web`).** Keeps native Discourse route bodies and save flows. The
`above-user-preferences` connector stays empty by design; styling is applied in
place by `stylesheets/preferences.scss`. The theme owns section *navigation*
(sidebar gear + floating menu), not section *content*.

**Mobile (`apps/mobile`).** Renders its own controls against the same fields
through `src/api/`. Section index reuses the existing
`SettingsForm` / `SettingsRow` primitives; each section is a child route.
Tier-S reads and writes go through `usersApi.getUserSettings` /
`usersApi.updateUserSettings` — never AsyncStorage.

**CLI (`apps/cli`).** Same field set, flat command surface, no tier-W sections.

---

## 8. Tier enforcement in the mobile client

`apps/mobile/shared/useNotificationPreferences.ts` now splits its two tiers
rather than storing them together.

`like_notification_frequency` is tier S. It is fetched and cached through
TanStack Query under `queryKeys.userSettings(username)`, written back through
`usersApi.updateUserProfile` as a flat top-level param, and invalidated on
sign-in and token refresh. It is no longer copied into AsyncStorage — the copy
was what went stale when the value changed on the web or the CLI. A rejected
write rolls the cached value back and reports the reason through `syncError`,
so the control returns to the server's value instead of silently keeping one
the server never accepted. Stored blobs from before v3 are read for their
device fields and their `likeFrequency` is discarded.

The category toggles (replies, mentions, likes, private messages, badges,
system, following) are **tier D, not stale tier-S mirrors**. They have no
Discourse counterpart: they filter the in-app notification list on this device
through `lib/utils/notifications.ts#filterNotificationsByPreferences`. The push
fields are likewise device-tier, stored ahead of push support. Both correctly
stay in AsyncStorage and must not be promoted to a shared section.

### Still open

`usersApi.getUserSettings()` calls `GET /users/:username/preferences.json`,
but Discourse's `UsersController#preferences` is an Ember route stub that
renders an empty body — there is no JSON there. The function is currently
unused; tier-S reads go through `getUserProfile` and its `user.user_option`
payload. Anything built on `getUserSettings` will silently receive nothing.

`apps/mobile/src/api/contracts/discourse-raw.ts` → `UserSettingsRaw` types 28
fields. Fields it does not yet cover, needed for tier-S parity across the rest
of the tree: category and tag id arrays, `muted_usernames`,
`allowed_pm_usernames`, `watched_precedence_over_muted`,
`topics_unread_when_closed`, `hide_profile`, `locale`, `homepage_id`,
`interface_color_mode`, `enable_smart_lists`, `enable_markdown_monospace_font`,
`bookmark_auto_delete_preference`, `user_notification_schedule`,
`notify_on_linked_posts`, `mailing_list_mode_frequency`.

---

## 9. State matrix

Per the root `docs/senior-product-ui-policy.md`, every section must define all
six states before visual polish.

| State | Treatment |
|---|---|
| Empty | Section with no configurable rows (site has no tags, no user fields) is hidden, not shown empty. |
| Loading | Skeleton rows at known section height. Never a bare spinner over a known shape. |
| Error | Per-section load failure keeps the section visible with a retry; save failure restores the prior value and states what failed. |
| Long content | Bio, muted lists, and category pickers wrap and scroll within the row; they do not truncate silently. |
| Permission | Staff-only and TL-gated fields are hidden, not disabled — except where the requirement itself is useful to state. |
| Moderation | Destructive rows (revoke, log out all, delete account) are visually subordinate and confirm before acting. |
