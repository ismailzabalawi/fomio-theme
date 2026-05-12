# M3-B2 — Notifications route mapping and mark-read (verified against Discourse core)

Source of truth: `discourse/app/controllers/notifications_controller.rb`, `discourse/frontend/discourse/app/routes/user-notifications*.js`, `discourse/frontend/discourse/app/models/user-stream.js`, `discourse/config/routes.rb`.

## Full notification inbox (Fomio-owned outlet mounts here)

| URL pattern | Discourse route | API | Query / behavior |
|-------------|-----------------|-----|------------------|
| `/u/:username/notifications` | `user.userNotifications` + index → `user/notifications-index` | `GET /notifications.json` | `username`, `limit` (default 60 in Ember route), optional `filter` = `read` or `unread` only (from `?filter=` on the URL). Value `all` is a client label; server ignores unknown `filter` and returns all rows. |
| `/u/:username/notifications?filter=read` | same | same | `filter=read` |
| `/u/:username/notifications?filter=unread` | same | same | `filter=unread` |

Pagination: JSON includes `load_more_notifications` (path + query with `offset`, `limit`, `username`, `filter`). Theme continues to follow that URL via `ajax`.

## “Tab” sub-routes (responses, likes, mentions, edits, links)

These routes use **`user/stream`**, not `notifications-index`. The Fomio owned component is **not** rendered (no `user-notifications-above-filter` / empty-state outlets on that template).

| URL segment | Ember route file | Data source |
|-------------|------------------|-------------|
| `/u/:username/notifications/responses` | `user-notifications/responses.js` | `GET /user_actions.json?offset=&username=&filter=6,9` (replies + quotes) |
| `/u/:username/notifications/likes-received` | `user-notifications/likes-received.js` | `filter=2` (`UserAction.TYPES.likes_received`); optional `acting_username` query |
| `/u/:username/notifications/mentions` | `user-notifications/mentions.js` | `filter=7` |
| `/u/:username/notifications/edits` | `user-notifications/edits.js` | `filter=11` |
| `/u/:username/notifications/links` | `user-notifications/links.js` | `filter=17` |

These are **user actions**, not `Notification` rows. Mapping them to `GET /notifications.json?filter_by_types=...` would be incorrect: `filter_by_types` only applies when `recent=true` (user menu / prioritized list), not the full inbox.

## `recent` + `filter_by_types` (not used for full Me inbox)

`GET /notifications.json?recent=true&filter_by_types=liked,replied` returns a short prioritized list for the **current user** only (`NotificationsController#index` first branch). Not equivalent to profile sub-routes above.

## Global `/notifications` / `/notifications/...`

Core `app-route-map.js` does not define a top-level notifications inbox; primary surface is `/u/:username/notifications`. Some installs or links may use `/notifications` as an alias (e.g. section menu checks). Theme fetching uses **`username` parsed from `/u/.../notifications`** when on the inbox path.

## Mark-read (`PUT /notifications/mark-read`)

Verified in `NotificationsController#mark_read` and `Notification.read` / `Notification.read_types`:

| Case | Params | Server behavior |
|------|--------|-----------------|
| Single notification | `id` (integer) | Marks that notification read for `current_user` |
| Mark all unread | none (no `id`, no `dismiss_types`) | `read_types(current_user, nil)` → all unread for user |
| By type names | `dismiss_types` comma-separated Discourse type **names** | Marks unread of those types |

Core UI mark-all: `discourse/frontend/discourse/app/controllers/user-notifications.js` → `ajax("/notifications/mark-read", { type: "PUT" })` with **no body**; then optimistic `read` on client models.

**CSRF / session:** Theme code must use Discourse `ajax` from `discourse/lib/ajax` (not raw `fetch`) so the session and CSRF headers match core.

**M3-B2 decision:** Do **not** implement mark-read in the theme yet. A follow-up can add mark-all and/or per-card read using the same `ajax` + `PUT` pattern, with optimistic row updates or refetch after success; align with `success_json` response handling used elsewhere.
