# Discourse `/u/:username/*` API map for `apps/web`

Status: active reference for building Fomio's web "Me" and profile UI against
native Discourse routes and payloads.

Scope: user profile, summary, activity, bookmarks, notifications, private
messages, preferences, and adjacent `/u/:username/*` endpoints in
`discourse/`.

## Working rule

`/u/:username/*` contains both:

- HTML route shells that Ember uses for navigation
- real JSON APIs that the route models, controllers, and components fetch

Do not assume every visible `/u/:username/...` path has a matching standalone
JSON contract. Several important screens do not.

## Route inventory

| UI path | Route target | Data source actually used by Discourse |
|---|---|---|
| `/u/:username` | `users#show` | `GET /u/:username.json` |
| `/u/:username/summary` | `users#summary` for JSON, `users#show` for HTML shell | `GET /u/:username/summary.json` |
| `/u/:username/activity` | `users#show` HTML shell | `GET /user_actions.json?username=:username&filter=...` |
| `/u/:username/activity/topics` | HTML shell | `GET /posts/:username/topics?offset=...` |
| `/u/:username/activity/replies` | HTML shell | `GET /user_actions.json?username=:username&filter=<reply types>` |
| `/u/:username/activity/likes-given` | HTML shell | `GET /user_actions.json?username=:username&filter=5` |
| `/u/:username/activity/bookmarks` | `users#bookmarks` | `GET /u/:username/bookmarks.json` |
| `/u/:username/notifications` | `users#show` HTML shell | `GET /notifications?username=:username&filter=...&limit=...` |
| `/u/:username/messages...` | `users#show` or `list#private_messages_tag` HTML shell | `GET /topics/private-messages.../*.json` topic-list endpoints |
| `/u/:username/preferences/*` | `users#preferences` or `users_email#index` HTML shell | mostly `GET /u/:username.json` plus targeted mutation endpoints |
| `/u/:username/card` | `users#show_card` | `GET /u/:username/card.json` |
| `/u/:username/staff-info` | `users#staff_info` | `GET /u/:username/staff-info.json` |
| `/u/:username/user-menu-bookmarks` | `users#user_menu_bookmarks` | `GET /u/:username/user-menu-bookmarks` |
| `/u/:username/user-menu-private-messages` | `users#user_menu_messages` | `GET /u/:username/user-menu-private-messages` |

## Feature packets

**Goal:** Load the base user profile model used by profile, preferences, and most child routes.
**Entry Point:** `GET /u/:username.json` → [`discourse/config/routes.rb`](../../../discourse/config/routes.rb) → `UsersController#show` in [`discourse/app/controllers/users_controller.rb`](../../../discourse/app/controllers/users_controller.rb)
**Client Trigger:** `UserRoute.afterModel()` calls `user.findDetails()` in [`discourse/frontend/discourse/app/routes/user.js`](../../../discourse/frontend/discourse/app/routes/user.js); `User.findDetails()` fetches `/u/:username.json` in [`discourse/frontend/discourse/app/models/user.js`](../../../discourse/frontend/discourse/app/models/user.js)
**Server Path:** `UsersController#show` → `fetch_user_from_params` → `UserSerializer` or `UserCardSerializer` / `HiddenProfileSerializer` / `InactiveUserSerializer`
**Data Map:** `users`, `user_profiles`, `user_stats`, `user_options`, `group_users`, `user_emails`, plus custom/profile fields exposed through serializers
**Permissions:** `guardian.ensure_public_can_see_profiles!`; `guardian.can_see_profile?(@user)` controls hidden-profile fallback; `requires_login` does not apply to `show`
**Async Side Effects:** `track_visit_to_user_profile` defers a `UserProfileView.add` write
**Realtime Side Effects:** Ember subscribes to `/u/:username_lower` and `/u/:username_lower/counters` in [`discourse/frontend/discourse/app/routes/user.js`](../../../discourse/frontend/discourse/app/routes/user.js)
**Serializer/JSON Contract:** [`discourse/app/serializers/user_serializer.rb`](../../../discourse/app/serializers/user_serializer.rb) extends [`discourse/app/serializers/user_card_serializer.rb`](../../../discourse/app/serializers/user_card_serializer.rb); key fields include `bio_raw`, `bio_cooked`, `user_option`, `groups`, `associated_accounts`, `profile_background_upload_url`, `can_edit_*`, `second_factor_*`
**Tests:** frontend fixtures in [`discourse/frontend/discourse/tests/fixtures/user-fixtures.js`](../../../discourse/frontend/discourse/tests/fixtures/user-fixtures.js); acceptance coverage in [`discourse/frontend/discourse/tests/acceptance/user-profile-summary-test.js`](../../../discourse/frontend/discourse/tests/acceptance/user-profile-summary-test.js)
**Safest Extension Plan:** Theme for UI only. Plugin only if `UserSerializer` must expose additional fields. Core patch is not justified from current evidence.
**Verification Steps:**
  1. `rg -n 'get "#{root_path}/:username"|def show|class UserSerializer' discourse/config/routes.rb discourse/app/controllers/users_controller.rb discourse/app/serializers/user_serializer.rb`
  2. `rg -n 'findDetails\\(|/u/:username\\.json|user_' discourse/frontend/discourse/app/routes/user.js discourse/frontend/discourse/app/models/user.js`
  3. `cd discourse && bin/rails routes | grep '/u/:username' | head`

**Goal:** Load the profile summary screen for `/u/:username/summary`.
**Entry Point:** `GET /u/:username/summary.json` → `UsersController#summary` in [`discourse/app/controllers/users_controller.rb`](../../../discourse/app/controllers/users_controller.rb)
**Client Trigger:** `UserSummaryRoute.model()` calls `user.summary()` in [`discourse/frontend/discourse/app/routes/user/summary.js`](../../../discourse/frontend/discourse/app/routes/user/summary.js)
**Server Path:** `UsersController#summary` → `UserSummary.new(@user, guardian)` → `UserSummarySerializer`
**Data Map:** user aggregate stats from `user_stats` and related query objects; summary topics, replies, links, badges, and top categories
**Permissions:** `guardian.ensure_public_can_see_profiles!`; `guardian.can_see_profile?(@user)`; serializer gates stats with `can_see_summary_stats` and actions with `can_see_user_actions`
**Async Side Effects:** cached for one hour via `Discourse.cache.fetch(summary_cache_key(...))`
**Realtime Side Effects:** none in the controller; profile-level MessageBus subscriptions still exist from the parent user route
**Serializer/JSON Contract:** [`discourse/app/serializers/user_summary_serializer.rb`](../../../discourse/app/serializers/user_summary_serializer.rb); payload root is `user_summary` with linked top-level `topics` and badge/user objects
**Tests:** fixtures in [`discourse/frontend/discourse/tests/fixtures/user-fixtures.js`](../../../discourse/frontend/discourse/tests/fixtures/user-fixtures.js); acceptance test in [`discourse/frontend/discourse/tests/acceptance/user-profile-summary-test.js`](../../../discourse/frontend/discourse/tests/acceptance/user-profile-summary-test.js)
**Safest Extension Plan:** Theme can rearrange summary presentation. Plugin if summary needs more JSON fields. Core patch not needed.
**Verification Steps:**
  1. `rg -n 'def summary|summary_cache_key|class UserSummarySerializer' discourse/app/controllers/users_controller.rb discourse/app/serializers/user_summary_serializer.rb`
  2. `rg -n 'summary\\(\\)|/summary\\.json|route:user-summary' discourse/frontend/discourse/app/routes discourse/frontend/discourse/app/models/user.js discourse/frontend/discourse/app/resolver-shims.js`
  3. `cd discourse && bin/rails routes | grep 'summary'`

**Goal:** Load the activity stream and child tabs under `/u/:username/activity`.
**Entry Point:** HTML shell `GET /u/:username/activity(/:filter)` → `UsersController#show`; JSON `GET /user_actions.json?username=:username&filter=...`
**Client Trigger:** parent route in [`discourse/frontend/discourse/app/routes/user-activity.js`](../../../discourse/frontend/discourse/app/routes/user-activity.js); stream loading via [`discourse/frontend/discourse/app/models/user-stream.js`](../../../discourse/frontend/discourse/app/models/user-stream.js)
**Server Path:** `UserActionsController#index` in [`discourse/app/controllers/user_actions_controller.rb`](../../../discourse/app/controllers/user_actions_controller.rb) → `UserAction.stream(opts)` → `UserActionSerializer`
**Data Map:** `user_actions` rows backed by `user_actions`, plus category lookups serialized with `CategoryBadgeSerializer` when lazy loading is enabled
**Permissions:** `guardian.can_see_profile?(user)` and `guardian.can_see_user_actions?(user, action_types)`
**Async Side Effects:** none
**Realtime Side Effects:** the parent `/u/:username_lower` MessageBus subscription can prepend a single action via `user.loadUserAction(id)`
**Serializer/JSON Contract:** [`discourse/app/serializers/user_action_serializer.rb`](../../../discourse/app/serializers/user_action_serializer.rb); key fields include `action_type`, `created_at`, `title`, `topic_id`, `post_id`, `post_number`, `slug`, `category_id`, `acting_username`, `action_code`
**Tests:** route/body-class behavior in [`discourse/frontend/discourse/tests/acceptance/user-anonymous-test.js`](../../../discourse/frontend/discourse/tests/acceptance/user-anonymous-test.js); fixtures in [`discourse/frontend/discourse/tests/helpers/create-pretender.js`](../../../discourse/frontend/discourse/tests/helpers/create-pretender.js)
**Safest Extension Plan:** Theme for presentational changes only. Plugin for new action filters or serializer fields. Core patch not required.
**Verification Steps:**
  1. `rg -n 'resources :user_actions|def index|class UserActionSerializer' discourse/config/routes.rb discourse/app/controllers/user_actions_controller.rb discourse/app/serializers/user_action_serializer.rb`
  2. `rg -n 'UserStream|/user_actions\\.json|user-activity' discourse/frontend/discourse/app/models/user-stream.js discourse/frontend/discourse/app/routes/user-activity*`
  3. `cd discourse && bin/rails routes | grep user_actions`

**Goal:** Load activity topic lists and post feeds that look like `/u/:username/activity/topics` and adjacent feed routes.
**Entry Point:** `GET /posts/:username/:filter?offset=...` and `GET /u/:username/activity.json`
**Client Trigger:** topic-style activity routes use `UserPostsStream` in [`discourse/frontend/discourse/app/models/user-posts-stream.js`](../../../discourse/frontend/discourse/app/models/user-posts-stream.js); posts feed comes from `PostsController#user_posts_feed`
**Server Path:** `PostsController#user_posts_feed` in [`discourse/app/controllers/posts_controller.rb`](../../../discourse/app/controllers/posts_controller.rb) for `/u/:username/activity.json`; topic list routes use list-generation under `ListController`
**Data Map:** `posts` joined with `topics`, `categories`, and `users`
**Permissions:** `guardian.can_see_profile?(user)` plus per-post `guardian.can_see?(post)`
**Async Side Effects:** none
**Realtime Side Effects:** none specific to this endpoint
**Serializer/JSON Contract:** `PostSerializer` in [`discourse/app/serializers/post_serializer.rb`](../../../discourse/app/serializers/post_serializer.rb); includes `topic_title` and excerpt when requested
**Tests:** pretender hooks for user activity feeds in [`discourse/frontend/discourse/tests/helpers/create-pretender.js`](../../../discourse/frontend/discourse/tests/helpers/create-pretender.js)
**Safest Extension Plan:** Theme for UI treatment only. Plugin if the stream needs a different server-side grouping or fields.
**Verification Steps:**
  1. `rg -n 'user_posts_feed|/posts/%@/%@|UserPostsStream' discourse/app/controllers/posts_controller.rb discourse/frontend/discourse/app/models/user-posts-stream.js`
  2. `rg -n 'activity\\.json|topics\\.rss|activity\\.rss' discourse/config/routes.rb`
  3. `cd discourse && bin/rails routes | grep 'activity' | grep '/u/'`

**Goal:** Load bookmarks for `/u/:username/activity/bookmarks`.
**Entry Point:** `GET /u/:username/bookmarks.json` → `UsersController#bookmarks`
**Client Trigger:** [`discourse/frontend/discourse/app/routes/user-activity/bookmarks.js`](../../../discourse/frontend/discourse/app/routes/user-activity/bookmarks.js)
**Server Path:** `UsersController#bookmarks` → `UserBookmarkList.new(...).load` → `UserBookmarkListSerializer`
**Data Map:** bookmark records plus bookmarkable topic/post data; optional category objects
**Permissions:** `guardian.ensure_can_edit!(user)` so this is self/staff only
**Async Side Effects:** ICS variant renders reminder exports; JSON path has no async write
**Realtime Side Effects:** none
**Serializer/JSON Contract:** [`discourse/app/serializers/user_bookmark_list_serializer.rb`](../../../discourse/app/serializers/user_bookmark_list_serializer.rb); root `user_bookmark_list` with `bookmarks`, `more_bookmarks_url`, optional `categories`
**Tests:** fixtures in [`discourse/frontend/discourse/tests/fixtures/user-fixtures.js`](../../../discourse/frontend/discourse/tests/fixtures/user-fixtures.js)
**Safest Extension Plan:** Theme for layout. Plugin if bookmark card JSON needs extra fields.
**Verification Steps:**
  1. `rg -n 'def bookmarks|UserBookmarkListSerializer|/bookmarks\\.json' discourse/app/controllers/users_controller.rb discourse/app/serializers/user_bookmark_list_serializer.rb discourse/frontend/discourse/app/routes/user-activity/bookmarks.js`
  2. `cd discourse && bin/rails routes | grep 'bookmarks' | grep '/u/'`
  3. `rg -n 'user_bookmark_list|more_bookmarks_url' discourse/frontend/discourse discourse/app`

**Goal:** Load notifications for `/u/:username/notifications`.
**Entry Point:** HTML shell `GET /u/:username/notifications(/:filter)` → `UsersController#show`; JSON comes from `GET /notifications`
**Client Trigger:** [`discourse/frontend/discourse/app/routes/user-notifications.js`](../../../discourse/frontend/discourse/app/routes/user-notifications.js)
**Server Path:** route asks the Ember store for `notification` records; this is not a dedicated `/u/:username/notifications.json` controller action
**Data Map:** notifications plus linked topic/user data from the notifications stack
**Permissions:** route only loads for current user or admin: `currentUser.username === username || currentUser.admin`
**Async Side Effects:** mark-read operations happen elsewhere via `PUT /notifications/mark-read`
**Realtime Side Effects:** notification counters update through the parent `/u/:username_lower/counters` subscription
**Serializer/JSON Contract:** outside this document's main controller set; important fact is that the screen is backed by `/notifications`, not a `/u/:username/...json` endpoint
**Tests:** route and filter behavior under `discourse/frontend/discourse/app/routes/user-notifications.js`; fixture coverage in frontend notification tests
**Safest Extension Plan:** Theme only for UI. Plugin only if notifications JSON or server filtering must change.
**Verification Steps:**
  1. `rg -n 'user-notifications|store\\.find\\(\"notification\"|/notifications/mark-read' discourse/frontend/discourse/app/routes discourse/frontend/discourse/app/controllers`
  2. `rg -n 'get \"notifications\" => \"users#show\"' discourse/config/routes.rb`
  3. `cd discourse && bin/rails routes | grep notifications | head -20`

**Goal:** Load private message inboxes shown under `/u/:username/messages...`.
**Entry Point:** HTML shell `GET /u/:username/messages...` → `UsersController#show`; JSON topic lists come from `/topics/private-messages*/*.json`
**Client Trigger:** [`discourse/frontend/discourse/app/routes/build-private-messages-route.js`](../../../discourse/frontend/discourse/app/routes/build-private-messages-route.js) and related group/tag variants
**Server Path:** `ListController#message_route` in [`discourse/app/controllers/list_controller.rb`](../../../discourse/app/controllers/list_controller.rb) → `generate_list_for(action.to_s, target_user, list_opts)` → topic list serializers
**Data Map:** PM topics, posters, tags, notification levels, unread state
**Permissions:** route-specific checks in `message_route`, including self-only inboxes, group PM visibility, and tag permissions
**Async Side Effects:** dismiss-read actions use topic-list bulk flows, not these GETs directly
**Realtime Side Effects:** PM topic tracking uses `/u/:username/private-message-topic-tracking-state`
**Serializer/JSON Contract:** topic-list JSON from `TopicListSerializer`; current-user mini menu additionally uses `/u/:username/user-menu-private-messages`
**Tests:** PM route parsing already exists in [`apps/web/tests/fomio-messages-routes.test.js`](../../tests/fomio-messages-routes.test.js); Discourse frontend route code in the files above
**Safest Extension Plan:** Theme for shell/layout and native route linking. Plugin only if PM list data must be reshaped.
**Verification Steps:**
  1. `rg -n 'private-messages|message_route|findFiltered\\(\"topicList\"' discourse/config/routes.rb discourse/app/controllers/list_controller.rb discourse/frontend/discourse/app/routes`
  2. `cd discourse && bin/rails routes | grep 'private-messages'`
  3. `rg -n 'private-message-topic-tracking-state|user-menu-private-messages' discourse/app discourse/frontend/discourse`

**Goal:** Support preferences screens under `/u/:username/preferences/*` without inventing fake APIs.
**Entry Point:** HTML shell `GET /u/:username/preferences...` → `UsersController#preferences` or `UsersEmailController#index`
**Client Trigger:** `PreferencesRoute.model()` returns `modelFor("user")` in [`discourse/frontend/discourse/app/routes/preferences.js`](../../../discourse/frontend/discourse/app/routes/preferences.js); subroutes mostly reuse the already-loaded user object
**Server Path:** initial data comes from `GET /u/:username.json`; writes fan out to `PUT /u/:username.json`, `PUT /u/:username/preferences/username`, `GET|POST|PUT /u/:username/preferences/email`, `PUT /u/:username/preferences/primary-email`, `PUT /u/:username/preferences/avatar/pick`, `PUT /u/:username/preferences/avatar/select`, `POST /u/:username/preferences/revoke-account`, `POST /u/:username/preferences/revoke-auth-token`, and several non-username-scoped `/u/...second_factor...` endpoints
**Data Map:** `users`, `user_options`, `user_profiles`, `user_emails`, `user_auth_tokens`, `user_api_keys`, `user_security_keys`
**Permissions:** preferences routes are login-only and effectively restricted to the current user via `RestrictedUserRoute`; mutation endpoints call `guardian.ensure_can_edit!`, `ensure_can_edit_email!`, or related checks
**Async Side Effects:** email changes, auth revocation, 2FA enrollment, and account changes can trigger mail/jobs/provider revocation
**Realtime Side Effects:** revoking auth tokens publishes `/file-change` refresh messages; counter subscription remains active through parent route
**Serializer/JSON Contract:** base contract is still `UserSerializer`; there is no authoritative `GET /u/:username/preferences.json` controller contract in current route code
**Tests:** current web-theme rule is documented in [`apps/web/docs/web/preferences-integration-guide.md`](./preferences-integration-guide.md); Discourse route/model implementations in the files above
**Safest Extension Plan:** Theme-only for layout/styling and small verified outlets. Plugin for new preference fields or server mutations. Do not replace the native preferences body.
**Verification Steps:**
  1. `rg -n 'def preferences|def update_primary_email|def destroy_email|def revoke_account|def revoke_auth_token' discourse/app/controllers/users_controller.rb discourse/app/controllers/users_email_controller.rb`
  2. `rg -n 'Preferences extends|findDetails\\(|\\.json\\`\\), \\{\\s*data,\\s*type: \"PUT\"|preferences/' discourse/frontend/discourse/app/routes/preferences* discourse/frontend/discourse/app/models/user.js`
  3. `cd discourse && bin/rails routes | grep 'preferences'`

## Implementation notes for `apps/web`

1. The safest read model for most user screens is still `GET /u/:username.json`.
2. Summary is the only major child page in this cluster with its own dedicated `/u/:username/...json` contract.
3. Activity, notifications, and messages are route shells over separate backend APIs. Build UI around the real fetches, not the visible URL alone.
4. Bookmarks is self-only and has a real `/u/:username/bookmarks.json` payload.
5. Preferences should use native Discourse routes and mutations. Treat [`apps/web/javascripts/discourse/lib/fomio-preferences-api.js`](../../javascripts/discourse/lib/fomio-preferences-api.js) as suspicious where it assumes `/u/:username/preferences.json`.

## Concrete mismatches to avoid

- `GET /u/:username/preferences.json` is not the canonical source for loading the preferences screen in current Discourse route code.
- `PUT /u/:username/preferences.json` is not what core `User#save` uses for general preference persistence; it uses `PUT /u/:username.json`.
- `/u/:username/notifications` does not imply `/u/:username/notifications.json`; the route loads from `/notifications`.
- `/u/:username/messages` does not imply `/u/:username/messages.json`; the route loads topic-list endpoints under `/topics/private-messages...`.
