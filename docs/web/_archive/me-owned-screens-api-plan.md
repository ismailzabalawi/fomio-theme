# M3-A — API-driven Fomio-owned Me screens (plan)

**Status:** Planning only — no implementation in this phase.  
**Authority:** Supersedes theme-only “presentation only” for **Me leaf surfaces** listed below; all other product surfaces unchanged.  
**Companion doc:** `apps/web/docs/web/me-second-level-navigation.md` (routes, native nav, plugin outlets).

---

## 1. Architecture decision

**Decision:** Fomio-owned **Me** leaf UIs load their data from **Discourse JSON endpoints** using the **logged-in browser session** (same-origin, cookie-authenticated requests). Discourse remains the only source of truth for auth, permissions, and mutations.

**Rationale:**

- Me screens are inherently private; they must use the **current user’s session**, never admin API keys or third-party tokens in frontend code.
- The mobile app already documents canonical notification (and related) endpoints in `apps/mobile/src/api/`; web can align on the **same URL shapes** while using the browser session instead of `user_api_key`.
- **HTTP from the theme:** Workspace rule discourages ad-hoc `fetch()` in themes. For M3+, use Discourse’s supported client patterns — **`ajax` from `discourse/lib/ajax`** (CSRF-aware, same-origin) or, where appropriate, existing Ember **`Store`** / model hooks already used by core routes — so requests stay equivalent to core frontend calls. Any exception should be documented in theme docs and gated by feature flags.

**Ownership split (unchanged at the system level):**

| Concern | Owner |
|--------|--------|
| Session, Guardian, permissions, serializers | Discourse |
| JSON routes, rate limits, error semantics | Discourse |
| Me area layout, grouping, cards, empty/loading/error UI | Fomio |
| When to show Fomio UI vs native | Fomio (feature flags + success gating) |

---

## 2. Scope boundaries

**In scope (Me only):**

- Notifications (full Fomio-owned list experience when flagged).
- Activity (per-tab lists when flagged; plugin rows Votes/Solved called out in risk map).
- Invites (list + create when flagged; discovery for list endpoints in §5).
- Messages (**plan only** in M3-A; **not** first implementation).
- Preferences (**grouped navigation / entry shell only** — no form replacement).
- Me landing / summary **as needed** to tie navigation and empty states.

**Explicitly out of scope:**

- Latest, Hot, Hubs/categories index, Byte (topic) detail, Composer, Search, Auth, Admin, general Discourse screens.
- H6-B Activity grouped-disclosure implementation (paused).
- Replacing Preferences forms.
- Owning Messages inbox first.

---

## 3. Native fallback strategy

**Principle:** Users must never be left with a blank Me surface if Fomio UI fails.

**Rules:**

1. **Default:** Feature flag **off** → native Discourse templates and lists render unchanged.
2. **Flag on:** Native content stays in the DOM until the Fomio-owned layer has **successfully** loaded and rendered its first meaningful state (non-error UI with data or intentional empty state).
3. **API or render failure:** Do **not** hide native content; show a Fomio error affordance **or** rely entirely on native UI (product choice per screen — minimum bar: native remains visible).
4. **Navigation:** Fomio rows must continue to use **canonical Discourse routes** (`/u/:username/...`, `/notifications`, etc.) so links stay shareable and consistent with core.
5. **No breaking deep links:** Bookmarked URLs must still resolve; Fomio shell is additive.

**Implementation sketch (for later phases):**

- Wrapper connector or controlled outlet above the native list: `native` visible → `data loaded` → apply class to hide native list (scoped CSS under `.fomio-*`), with timeout/error path that never removes native visibility.

---

## 4. Feature flag strategy

**Transport:** Theme settings in `settings.yml`, keys prefixed `fomio_`, consumed via `import { settings } from "virtual:theme"`.

**Proposed flags (booleans, default `false`):**

| Setting | Purpose |
|---------|---------|
| `fomio_owned_me_notifications_enabled` | Fomio-owned Notifications screen |
| `fomio_owned_me_activity_enabled` | Fomio-owned Activity lists |
| `fomio_owned_me_invites_enabled` | Fomio-owned Invites |
| `fomio_owned_me_preferences_shell_enabled` | Preferences **navigation shell only** (optional fourth flag, or roll into a single “me shell” flag — prefer **separate** for safer rollout) |

**Rollout:**

- Ship **one screen per flag**; enable on staging first.
- Operators can disable a flag instantly to restore native UI without redeploying logic (theme setting toggle).

**Guardrails:**

- Flags only affect **Me** surfaces; no global behavior change.
- Combine with “successful render before hide native” (§3).

---

## 5. API endpoint discovery

**Sources used for this plan:**

- Official API reference: [Discourse API docs — Notifications](https://docs.discourse.org/) (GET `notifications.json`, PUT `notifications/mark-read.json`).
- Official API reference: Invites (POST `invites.json`, etc.), Private messages (GET `topics/private-messages/{username}.json`, GET `topics/private-messages-sent/{username}.json`), User actions (GET `user_actions.json`).
- Fomio mobile boundary (endpoint shapes + evidence comments): `apps/mobile/src/api/endpoints/notifications.api.ts`, `apps/mobile/src/api/endpoints/users.api.ts`, `apps/mobile/src/api/contracts/discourse-raw.ts`.

**Note:** The checked-in `discourse/` core tree is **not present** in this workspace snapshot; route-to-controller claims in mobile files point to core paths for when the monorepo includes Discourse. **M3-B implementation** should still verify query parameters (filters, pagination) via browser Network tab on the target site or a local Discourse checkout.

### 5.1 Notifications — candidates

| Operation | Endpoint (candidate) | Notes |
|-----------|------------------------|--------|
| List | `GET /notifications.json` | Response: `notifications[]`, `total_rows_notifications`, `seen_notification_id`, `load_more_notifications` (pagination URL/string). |
| Recent / compact list | `GET /notifications.json?recent=true&limit=N` | Used by mobile helper; verify in Network for web parity. |
| Mark one read | `PUT /notifications/mark-read.json` with `{ id }` | Documented in API docs + mobile. |
| Mark all read | `PUT /notifications/mark-read.json` (no body) | Documented in API docs + mobile. |
| Totals / badges | `GET /notifications/totals.json` | Mobile comments reference `notifications#totals`; useful for header counts. |
| Sub-routes (Responses, Mentions, …) | **TBD — verify** | Core UI uses separate notification routes; likely additional **query params** or path variants on `notifications.json`. Capture from Network on `/u/:username/notifications/responses` etc. |
| Dismiss / delete notification | **TBD — verify** | Not listed in the OpenAPI slice reviewed; confirm whether core uses a dedicated route or mark-read only. |

**Target links:** Build from `topic_id`, `post_number`, `slug` (and `data`) as core does — reuse `DiscourseURL` / router helpers where possible to avoid broken permalinks.

### 5.2 Activity — candidates

Aligned with `getUserActivity` in `users.api.ts` (mobile):

| Tab / type | Endpoint (candidate) |
|------------|----------------------|
| All | `GET /user_actions.json?username=&filter=4,5&offset=&limit=` |
| Topics | `GET /topics/created-by/{username}.json?page=` |
| Replies | `GET /user_actions.json?username=&filter=5&offset=&limit=` |
| Read | `GET /read.json?offset=` |
| Likes (given) | `GET /user_actions.json?username=&filter=1&offset=&limit=` |
| Bookmarks | `GET /u/{username}/bookmarks.json?page=` |
| Solved (plugin) | `GET /solution/by_user.json?username=&offset=&limit=` |
| Votes (plugin) | `GET /topics/voted-by/{username}.json?offset=` |

**Drafts / Pending:** Not in the same mobile switch; **verify** core routes (`/u/.../activity/drafts`, pending posts) against Network and add rows only when site exposes them.

**Pagination:** Mix of `page`, `offset`, and `load_more` style fields — normalize per tab during implementation.

### 5.3 Invites — candidates

| Operation | Endpoint (candidate) | Notes |
|-----------|------------------------|--------|
| Create | `POST /invites.json` | Documented in OpenAPI; body for email vs link invites. |
| Create bulk | `POST /invites/create-multiple.json` | Documented. |
| List pending / expired / redeemed | **TBD — verify** | OpenAPI slice reviewed did not list a GET index; trace **native Invites** route in Discourse frontend (when repo available) or Network tab on `/u/:username/invited` (or site-specific path). |
| Delete / rescind | **TBD — verify** | Often `DELETE /invites/{id}` or similar — confirm before implementation. |

### 5.4 Messages — candidates (planning only; implement later)

| View | Endpoint (candidate) |
|------|----------------------|
| Inbox / latest | `GET /topics/private-messages/{username}.json` (+ pagination) |
| Sent | `GET /topics/private-messages-sent/{username}.json` |
| New / unread / archive / group / tags | **TBD — verify** | Core likely uses filtered topic list endpoints or search-based queries; Messages is **high complexity** — defer. |

### 5.5 Preferences — shell only

- **No** new write endpoints for forms.
- Navigation grouping can use **existing** Discourse routes under `/u/:username/preferences` and children; optional `GET /users/:username/preferences.json` for read-only labels/sections if needed for a sidebar (read-only, session-scoped).

---

## 6. Screen ownership priority

1. **Notifications** — simplest aggregate list; clear API; aligns with existing Fomio notification grouping nav; easiest fallback.
2. **Activity** — more endpoints and plugin variance; still read-heavy.
3. **Invites** — depends on confirming **list** API; moderate complexity.
4. **Preferences shell** — navigation-only; low risk if forms untouched.
5. **Messages** — last (inbox modes, groups, tags, unread semantics).

---

## 7. Data model per screen (logical)

### Notifications

- **Row:** id, notification_type, read, created_at, topic_id, post_number, slug, fancy_title (if present), data (badge, acting user, etc.), high_priority, acting_user_avatar_template / name.
- **List meta:** total_rows, seen_notification_id, load_more cursor/url.
- **UI state:** loading, empty, error, filter segment (mapped after Network verification).

### Activity

- **Row:** varies: `user_actions` entry vs `topic_list.topics[]` item vs solution row — normalize to a card model (title, excerpt, url, timestamp, icon type).
- **Pagination:** per-tab strategy.

### Invites

- **Row (TBD):** invite id, email/domain, link, redeemed/expired flags, created_at, expires_at, topics/groups — exact shape after list endpoint discovery.

### Messages (deferred)

- **Row:** topic list item for PM archetype + unread counters — from `topic_list.topics[]`.

### Preferences shell

- **Section:** label, href, optional icon, visibility from `currentUser` / site settings.

---

## 8. Actions per screen

| Screen | Actions |
|--------|---------|
| Notifications | Mark read (single/all); navigate to target Byte; optional dismiss if core supports; refresh / load more. |
| Activity | Navigate to Byte/user; load more; optional plugin-specific actions later. |
| Invites | Create invite; copy link; delete/rescind (if API exists); filter tabs. |
| Messages (later) | Open thread; mark read; archive; reply — **defer**. |
| Preferences shell | Navigate only (no form posts from Fomio-owned forms in M3). |

All writes go through **Discourse-documented** endpoints with session + CSRF (via `ajax`).

---

## 9. Risk map

| Risk | Mitigation |
|------|------------|
| Session / CSRF failures on `PUT` | Use `discourse/lib/ajax`; test mark-read in staging. |
| Hiding native UI too early | Gate on successful Fomio render; error → keep native. |
| Notification filter parity | Verify query params per sub-tab; add tests or manual matrix. |
| Activity plugin rows missing | Feature-detect or mirror `user-activity-bottom` / site settings; document gaps. |
| Invites list endpoint undocumented | Block invites implementation until Network + core trace confirm list + delete. |
| Messages complexity | Explicitly out of first milestones. |
| Terminology drift | All **new** user-facing strings: Hub / Teret / Byte only (`locales/en.yml`). |
| Exposing secrets | Never ship API keys or admin keys in theme; browser session only. |
| Breaking canonical URLs | Build links with Discourse helpers; no hard-coded site hostnames. |
| Performance | Paginate; avoid double-fetching when native and Fomio both load — consider flag-driven **single** source path when stable. |

---

## 10. Implementation order

1. **M3-A (this doc)** — alignment, flags defined in `settings.yml`, no user-facing behavior change yet.
2. **M3-B — Notifications (recommended first)** — see below.
3. **M3-C — Activity** — per-tab fetchers + cards + plugin matrix.
4. **M3-D — Invites** — after list endpoint verification.
5. **M3-E — Preferences navigation shell** — grouped entries only.
6. **M3-F — Messages** — only after dedicated design + spike.

**Sync rule:** If a feature ships in `apps/web-beta/` first per workflow, mirror to `apps/web/` when stable.

---

## First screen recommendation (M3-B)

**Ship Fomio-owned Notifications first** (`fomio_owned_me_notifications_enabled`):

- Single primary list endpoint family (`/notifications.json`).
- Read + mark-read mutations are documented and already mirrored in mobile.
- Existing Fomio second-level notification grouping (`fomio-notifications-section-menu`, connectors) provides navigation parity.
- Native fallback is a straight list — low risk if gated correctly.

---

## References

- `apps/mobile/src/api/endpoints/notifications.api.ts`
- `apps/mobile/src/api/endpoints/users.api.ts`
- `apps/mobile/src/api/contracts/discourse-raw.ts` (`NotificationRaw`, `NotificationsListRaw`)
- `apps/web/docs/web/me-second-level-navigation.md`
- Discourse API: https://docs.discourse.org/

---

## Appendix — M3-B implementation prompt (for next session)

Use this as the starting instruction for **M3-B**:

> Implement **Fomio-owned Notifications** behind `fomio_owned_me_notifications_enabled` (default off). Use session-authenticated `ajax` from `discourse/lib/ajax` (not raw `fetch` to arbitrary hosts; no API keys). Load `GET /notifications.json` (and pagination via `load_more_notifications` or documented params); support **mark read** via `PUT /notifications/mark-read.json`. Reuse existing notification grouping nav; add Fomio list/cards/empty/loading/error states. **Do not hide** native notification list until the Fomio layer has successfully rendered. On failure, keep native UI. Add i18n keys in `locales/en.yml` (Hub/Teret/Byte terminology only). Verify notification sub-filters (Responses, Mentions, …) against browser Network on the target site and match behavior or document MVP as “All only” if needed for first merge. Touch **only** Me/notifications surfaces; do not change Latest, topic, composer, or auth.

---

## M3-C — Activity API Discovery

This section outlines the API discovery findings for the Fomio-owned Activity screen. It verifies the endpoints, response models, and pagination strategies used natively by Discourse, and provides recommendations for building a unified mobile Activity experience.

### Endpoint Discovery

| Activity Filter | URL Route | Backend API Endpoint | Response Model | Pagination Shape |
| :--- | :--- | :--- | :--- | :--- |
| **All** | `/u/:username/activity` | `/user_actions.json` | `UserAction` | `offset` & `limit` |
| **Topics** | `/u/:username/activity/topics` | `/topics/created-by/:username.json` | `Topic` (via `TopicList`) | Standard `TopicList` pagination |
| **Replies** | `/u/:username/activity/responses` | `/user_actions.json?filter=5` | `UserAction` | `offset` & `limit` |
| **Read** | `/u/:username/activity/read` | `/read.json` | `Topic` (via `TopicList`) | Standard `TopicList` pagination |
| **Drafts** | `/u/:username/activity/drafts` | `/drafts.json` | `Draft` | `offset` & `limit` |
| **Pending** | `/u/:username/activity/pending` | `/posts/:username/pending.json` | `PendingPost` | Typically unpaginated or implicit |
| **Likes given** | `/u/:username/activity/likes-given` | `/user_actions.json?filter=1` | `UserAction` | `offset` & `limit` |
| **Bookmarks** | `/u/:username/activity/bookmarks` | `/u/:username/bookmarks.json` | `Bookmark` | `more_bookmarks_url` |
| **Votes** (plugin) | `/u/:username/activity/votes` | `/topics/voted-by/:username.json` | `Topic` (via `TopicList`) | Standard `TopicList` pagination |
| **Solved** (plugin) | `/u/:username/activity/solved` | `/solution/by_user.json` | `SolvedPost` (custom post) | `offset` & `limit` |

### Key Findings

1. **No Unified Model**: The Activity section relies on at least **6 distinct JSON models**: `UserAction`, `TopicList/Topic`, `Draft`, `PendingPost`, `Bookmark`, and `SolvedPost`.
2. **Missing Properties**: Unlike `Notification` models, these activity models do not universally contain `read/unread` tracking properties, and they lack a unified way to extract an actionable `URL` or `excerpt`.
3. **Fragmented Pagination**: Pagination strategies wildly differ across filters. Some use `offset/limit`, some rely on `more_urls`, and some use `page` parameters.
4. **Plugins**: The `discourse-topic-voting` and `discourse-solved` plugins add their own completely bespoke endpoints and response models, rather than hooking into a unified activity feed system.

### Can it fit one Fomio ActivityCard model natively?

**No.** Attempting to build a stable `FomioActivityCard` component using the native endpoints would require a massive abstraction layer in the frontend to fetch from 10 different endpoints, normalize 6 different JSON models into a shared card props interface, and juggle 3 different pagination techniques.

### Recommendation: Custom Plugin Endpoint

To implement the Activity screen natively in Fomio, **a custom Discourse Plugin endpoint is highly recommended.**

Creating an endpoint such as `GET /fomio/activity.json?filter={filter}` would allow the backend to:
- Act as a GraphQL-style resolver to fetch the correct underlying records.
- Map `Topics`, `UserActions`, `Bookmarks`, and `Drafts` into a single, highly-stable JSON contract (e.g. `FomioActivityItem` containing `id`, `type`, `title`, `excerpt`, `url`, `timestamp`).
- Implement a unified cursor or offset pagination system.
- Drastically simplify the client-side logic, allowing us to build exactly one `fomio-owned-activity.gjs` component.

### Next Implementation Phase

Given the complexity of the native endpoints, the recommended next phase is to build the custom Fomio Activity API via a Discourse Plugin (`discourse-fomio-user-shell` or similar), and then return to Fomio Web to build the UI safely consuming the normalized endpoint.

---

## M3-C1 — Normalized Activity Endpoint Contract

**Plugin Location**: `plugins/discourse-fomio-api`

### Endpoint

`GET /fomio/me/activity.json`

### Supported Filters (Phase One)
- `all`: Combines topics and replies (mapped from UserActions)
- `topics`: Mapped from TopicQuery / `created-by`
- `replies`: Mapped from UserActions
- `likes_given`: Mapped from UserActions
- `bookmarks`: Mapped from the Bookmark model (requires self permission)

### Deferred Filters
- `read`, `drafts`, `pending`, `votes`, `solved`

### Response Schema

```json
{
  "filter": "topics",
  "username": "soma",
  "items": [
    {
      "id": "topic-123",
      "kind": "topic",
      "title": "Example Byte title",
      "excerpt": "Plain text excerpt if available",
      "url": "/t/example/123",
      "created_at": "2026-05-10T10:00:00Z",
      "updated_at": "2026-05-10T11:00:00Z",
      "actor": {
        "username": "soma",
        "name": "Soma",
        "avatar_template": "/user_avatar/..."
      },
      "meta": {
        "reply_count": 3,
        "like_count": 10,
        "category_id": 1
      }
    }
  ],
  "next_cursor": "opaque-cursor-or-null"
}
```

### Pagination
- A unified base64-encoded `cursor` is passed from `next_cursor` in previous responses.
- Internally translates to `offset`.

### Security Rules
- Block unauthenticated requests.
- Prevent arbitrary users from fetching private bookmarks of other users.
- Rely natively on Guardian for checking topic and user_action permissions.

### Frontend Usage Plan
The Fomio Web client will now only need to hit `GET /fomio/me/activity.json` and consume the unified contract, entirely bypassing the complexity of multiple native routes and pagination schemes.
