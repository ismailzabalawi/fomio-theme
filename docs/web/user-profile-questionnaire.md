# Fomio Web — User Profile: Technical Questionnaire

**Status:** ✅ Resolved — all blocking questions answered (2026-06-21). Ready for implementation planning.
**Source design:** `claude.ai/design` project `Fomio User Profile.html` (heroes + Summary, Activity,
Notifications, Messages, Bookmarks, Preferences; nav patterns: detached / master-pane / tabs; surface
modes: expanded / compact-desktop / rail / touch; self/other; dark mode).
**Backend reference:** [`discourse-user-route-api-map.md`](./discourse-user-route-api-map.md).
**Existing infra this must reconcile with:** [`me-navigation.md`](./me-navigation.md),
[`fomio-user-shell-plugin-plan.md`](./fomio-user-shell-plugin-plan.md),
[`preferences-integration-guide.md`](./preferences-integration-guide.md),
[`touch-preferences-redesign-pattern.md`](./touch-preferences-redesign-pattern.md).

---

## 0. Why this questionnaire exists

The imported prototype is a **standalone React SPA** that renders profile data from a static fixture
(`user-profile-data.js`) inside a self-contained shell. The Fomio web theme is **not** an SPA — it is a
Discourse theme whose constitutional rule is *reshape the native experience, never rebuild Discourse
logic* (`apps/web/CLAUDE.md`). Most of what the prototype draws (Activity, Notifications, Messages,
Preferences) already exists as **native Discourse `/u/:username/*` routes** that the theme currently
restyles additively, and a **`discourse-fomio-user-shell` plugin** already exposes a structural contract
for them.

So the prototype is a **design target**, not an implementation blueprint. Every decision below is about
mapping prototype intent onto the additive-theme reality without forking Discourse. Nothing ships until
the **blocking** questions (§1) are answered.

Legend: 🔴 blocking · 🟡 shapes scope · 🟢 detail / can default.

---

## 1. Architecture & scope — 🔴 BLOCKING

These change the entire shape of the work. No code until these are settled.

1.1 🔴 **Build model.** Which of these is the real target?
  - **(A) Additive restyle** of native `/u/:username/*` routes via connectors + SCSS + the existing
    `fomio-user-shell` plugin contract (repo-canonical; what `me-navigation.md` already does).
  - **(B) Fomio-owned shell** that wraps native content roots (master-pane / detached card) while still
    letting Discourse own data, forms, and routing inside.
  - **(C) Custom route body** rendering our own components against the JSON APIs.
  > Repo rules forbid (C) for Preferences and discourage it generally. Recommendation: **A** as the
  > baseline, **B** only for the desktop summary/landing chrome. **Confirm.**

1.2 🔴 **Relationship to the existing "Me" surface.** `me-navigation.md` already defines a Me hub
  (self) over native child routes. Is this profile work:
  - the **public profile** (`other` user) only,
  - a **redesign of the self/Me** surface,
  - or a **unified** surface that serves both `self` and `other` from one shell?
  > The prototype does all three via a `viewMode` tweak. We must pick the production scope.

1.3 🔴 **Which sections are in scope for v1?** Prototype ships six: Summary, Activity, Notifications,
  Messages, Bookmarks, Preferences. Notifications/Messages/Preferences are **self-only** and have the
  most backend nuance. Proposed v1: **Summary + Activity + Bookmarks** (public-safe, lowest risk);
  Notifications/Messages/Preferences as v2 over their existing native treatments. **Confirm or re-cut.**

1.4 🔴 **Plugin dependency.** Does the canonical nav pattern (§2) require the
  `discourse-fomio-user-shell` plugin contract (`.fomio-user-shell`, `data-fomio-user-section`), or must
  v1 work **theme-only** (no plugin install) so it runs on stock Discourse? This gates whether master-
  pane/detached is even available for v1.

1.5 🟡 **Target track.** `apps/web` only, or mirror into `apps/web-beta` (currently no live tree)?

---

## 2. Navigation pattern — 🔴 BLOCKING (one must be canonical)

The prototype exposes three desktop patterns via a tweak; production needs **one** canonical choice per
surface mode. (Touch is already decided: stack header + bottom nav + summary tabs.)

2.1 🔴 **Desktop/expanded pattern:**
  - **detached** — floating rounded card with an internal master list + content column (most "OS"-like,
    furthest from native DOM, most likely to need plugin (B)).
  - **master-pane** — persistent left section nav + content (matches `MasterPane`; closest to the
    Sidebar-OS doctrine in `apps/web/CLAUDE.md`).
  - **tabs** — horizontal tab bar above content (closest to native Discourse `user-navigation-secondary`;
    lowest implementation risk).
  > Recommendation: **master-pane** for expanded/compact-desktop, **tabs** fallback for rail.

2.2 🟡 **Rail + compact-desktop behavior.** Confirm the master pane collapses to an overlay on rail (per
  `fomio-master-pane-overlay-state.js`, which already exists) rather than to touch.

2.3 🟢 **Outer sidebar.** The prototype draws its own left app sidebar (Latest/Search/New/Bookmarks).
  In the theme this is the existing `above-site-header/fomio-sidebar.gjs`. Confirm we **reuse** it and do
  not introduce a second sidebar.

2.4 🟢 **Does the section nav live in the URL?** i.e. should switching to Activity navigate to
  `/u/:username/activity` (native route, deep-linkable, back-button correct) or swap content in-place
  (SPA-feel, breaks deep links)? Repo precedent strongly favors **real route transitions**.

---

## 3. Data sources per section — 🟡 (must be answered per in-scope section)

Each section's UI maps to a *different* real endpoint. Confirmed against the route map:

| Section | Real source | Notes / gotchas |
|---|---|---|
| Profile/Hero | `GET /u/:username.json` (`UserSerializer`) | Base model for everything. |
| Summary | `GET /u/:username/summary.json` (`UserSummarySerializer`) | Only child with a dedicated JSON contract. **1-hour server cache.** |
| Activity | `GET /user_actions.json?username&filter=…` | Route shell over `user_actions`; mixed row types, **no stable per-row type class for CSS-only filtering** (see §6.3). |
| Activity → Bytes | `GET /posts/:username/topics?offset=…` | Topic-style stream. |
| Bookmarks | `GET /u/:username/bookmarks.json` | **Self/staff only** (`ensure_can_edit!`). Not public. |
| Notifications | `GET /notifications?username&filter&limit` | **No** `/u/:username/notifications.json`. Self/admin only. |
| Messages | `GET /topics/private-messages…/*.json` | **No** `/u/:username/messages.json`. Different dataset per inbox. |
| Preferences | `GET /u/:username.json` + targeted mutation endpoints | **No** canonical `preferences.json`. Writes go to `PUT /u/:username.json`. |

3.1 🟡 **Fixture mismatch.** The prototype's `user-profile-data.js` invents fields (`bytesWritten`,
  `topReplies`, `topCategories`, glyph badges, etc.). Which map to real serializer fields, which need a
  **plugin** to expose, and which get **dropped** for v1? (e.g. "bytes written" ≈ `topic_count`, "received"
  ≈ likes received from `user_stats`.) Needs a field-by-field reconciliation pass before building Summary.

3.2 🔴 **Bookmarks is self-only.** It appears in the prototype's section nav unconditionally. On a public
  (`other`) profile it must be **hidden** (matches the prototype's `isSelf` gating — confirm we enforce
  server-truth, not just the tweak).

3.3 🟢 **Terminology mapping.** Prototype uses "bytes / terets / received / given" already (good). Confirm
  Summary labels pass `check-terminology.js` and come from `locales/en.yml`, never inline strings.

---

## 4. Preferences boundary — 🔴 BLOCKING

4.1 🔴 The prototype renders a **fake** read-only Preferences panel (`PreferencesSection`). Repo law:
  *"Preferences is a native Discourse leaf. Do not replace `/preferences/*` with a custom route body."*
  Confirm Preferences in production is **native Discourse, restyled only** (per
  `touch-preferences-redesign-pattern.md` + `preferences-integration-guide.md`), and the prototype's
  panel is **discarded**.

4.2 🟢 `fomio-preferences-api.js` is flagged in the route map as *suspicious where it assumes
  `/u/:username/preferences.json`*. Should this questionnaire's work include **auditing/removing** that
  assumption, or is that out of scope?

---

## 5. Surface modes, theming, identity — 🟡

5.1 🟡 **Surface modes.** Prototype defines its own `useSurfaceMode` with the same breakpoints as the
  repo's `fomio-surface-mode.js` (1280 / 1024 / 768). Confirm we **consume the existing lib** and the
  existing `body.fomio-surface-*` classes rather than re-deriving width.

5.2 🟢 **Dark mode.** Prototype toggles `data-theme="dark"` on a local fixture palette. Production dark is
  the **AMOLED** `Fomio Dark` color scheme via `html.fomio-color-dark` + `--fomio-*` tokens. Confirm no new
  hardcoded hex; all colors from tokens (the prototype hardcodes `#fff`, `#D6C9A8`, etc. — these must be
  tokenized).

5.3 🟢 **Self vs other detection.** Use existing `fomio-profile-identity-ownership.js` to decide `isSelf`
  from `currentUser`, not a tweak. Confirm.

5.4 🟢 **Avatars.** Prototype draws initials chips. Discourse serves real avatar uploads. Confirm we render
  the native avatar (`user.avatar_template`) with initials only as fallback.

---

## 6. Known hard problems (called out so they aren't discovered late) — 🟡

6.1 🟡 **Notifications/Messages aren't `/u/...json`.** Any "unread count" badge in the section nav
  (`unreadNotifs=2`, `unreadMsgs=1` in the prototype) must come from the real counters
  (`currentUser` tracking / `/u/:username_lower/counters` MessageBus), not invented numbers — and the
  theme does **no `fetch`**. Where does the count come from?

6.2 🟡 **Detached/master shells move live Ember nodes.** Per `fomio-user-shell-plugin-plan.md`, manual DOM
  reparenting of `#user-content` breaks `LoadMore`, focus, scroll restoration, and forms. If we choose a
  card/detached shell, it must use the **plugin contract**, not reparenting. Confirm the chosen pattern's
  containment strategy.

6.3 🟡 **Activity has no CSS-filterable rows.** The prototype's Activity tab filters (All / Bytes /
  Replies / Likes) can't be done with pure CSS over native rows (`me-navigation.md` §3). Either use native
  activity pills (route transitions) or accept this needs a DSP. Which?

6.4 🟢 **Messages "New message" / Notifications "Mark all read"** are real Discourse actions with their own
  controllers. The prototype draws inert buttons. Confirm we wire to native controls (or hide them in v1).

---

## 7. Delivery, quality, testing — 🟢

7.1 🟢 **Connectors to (re)use.** v1 should extend existing outlets, not invent: `user-profile-header-above`,
  `above-user-summary-stats`, `after-user-summary-badges`, `user-summary-top-category-row`,
  `before-user-profile-avatar`, `above-user-bookmarks`, `user-activity-navigation-wrapper`. Confirm the
  outlet list per in-scope section before building (all must be `rg`-verified in `discourse/`).

7.2 🟢 **Tests.** Pure helpers (field mapping, isSelf, section resolution, surface mode) get unit tests in
  `apps/web/tests/` (repo pattern). Confirm coverage expectation.

7.3 🟢 **Ship checklist.** Design critique (3 passes) · Quality audit (6 passes) ·
  `node apps/mobile/scripts/check-terminology.js` · `npm run tokens:check` · desktop + mobile preview.

7.4 🟢 **Plain-UX pass.** Run `fomio-user-plain-ux` on all new copy (empty states, section labels, button
  text) before implementation.

---

## 8. Decision log (fill in as answered)

| # | Question | Decision | Date |
|---|---|---|---|
| 1.1 | Build model (A/B/C) | **A baseline + B for live sections** — additive restyle, but the detached card frames live native content via the plugin contract (no logic rebuild, no DOM reparenting) | 2026-06-20 / 2026-06-21 |
| 1.2 | Me relationship | **Unified self + other**, self-only sections gated by ownership | 2026-06-20 |
| 1.3 | v1 sections | **Summary, Activity, Bookmarks** (§9 safe cut). Notifications/Messages → v2 on native treatments; Preferences excluded (stays native) | 2026-06-21 |
| 1.4 | Plugin dependency | **No plugin dependency** — plugin is read-only (`discourse/`), mobile-only, and doesn't mark Summary; detached card framed with pure theme CSS over native nodes instead (see §10) | 2026-06-21 |
| 2.1 | Canonical desktop nav | **Detached card** via CSS over native content, scoped to master-pane body classes (no DOM reparenting, no plugin) | 2026-06-20 / 2026-06-21 |
| 4.1 | Preferences = native restyle | **Yes — excluded from this work entirely; native, untouched** | 2026-06-20 |
| (hero) | Hero treatment | **Editorial** | 2026-06-21 |

---

## 10. ✅ RESOLVED — detached card vs. additive-restyle

The two chosen answers are in tension and one sub-decision remains:

- **Detached card** = a single Fomio-owned floating card with an *internal* master list that swaps a
  *content column* between sections.
- **Additive restyle (A)** = leave native `/u/:username/*` route content where Discourse renders it; only
  restyle in place.

Notifications and Messages are **separate native routes** (`/notifications`, `/topics/private-messages…`),
not one page. To show their **real** content inside one card's content column, the card must host live
Ember route content. Doing that by **moving DOM nodes** breaks `LoadMore`, focus, scroll restoration, and
forms (documented in `fomio-user-shell-plugin-plan.md`). The safe way is the **`discourse-fomio-user-shell`
plugin contract** (`.fomio-user-shell` / `data-fomio-user-section` / `data-fomio-user-content`), which
decorates native nodes in place so the card can frame them without reparenting.

**Therefore the detached card is effectively build-model (B) for the live sections, even though we call the
styling approach "additive."** This is fine — but it means **§1.4 must be answered**:

- **(i)** Allow the `fomio-fomio-user-shell` plugin → detached card frames *real* native content per route,
  deep links + back button + forms all stay correct. **(Recommended.)**
- **(ii)** Theme-only, no plugin → the detached card can be the **Summary** landing chrome (one route,
  static-ish data), but Activity/Notifications/Messages/Bookmarks render as the **native route body** on
  their own URLs (detached visual applies to Summary; other sections are real route transitions, not
  inside the card). Lower fidelity to the prototype, zero plugin install.

> **DECISION (2026-06-21): CSS-over-native (refinement of option ii).** Although the
> `discourse-fomio-user-shell` plugin exists in-repo, it lives under the **read-only `discourse/` tree**
> (Claude may not modify it), it defaults to **off + mobile-only**, and its section resolver **does not mark
> the Summary route**. Rather than depend on an uneditable, partially-applicable plugin, the detached card
> is delivered with **pure theme CSS over native nodes** — and **most of it already exists**: Activity (and
> its Bookmarks child) is already framed as a detached **parent-child card** on desktop/rail by the
> `…user-activity-page:has(.fomio-me-activity-nav) .new-user-content-wrapper` block in `common.scss`, and
> Summary already has its **editorial canvas** (gradient + stat tiles), to which v1 adds the editorial hero.
> Result: **no DOM reparenting, no `discourse/` edits, no admin toggle.** Sections remain **real route
> transitions** under `/u/:username/*` (§2.4); desktop/rail carry the card chrome, touch flattens. Hero =
> **editorial**. The plugin's `data-fomio-user-section` attributes remain available as a future styling
> bonus if it is ever enabled, but v1 does not require it.
>
> **Repo-law reconciliation (required):** the detached card contradicts the "Me Leaf Screens — One Flat
> Surface (all modes)" law. That rule in `apps/web/CLAUDE.md` and
> `docs/web/touch-preferences-redesign-pattern.md` were updated to scope the flat law to
> **Notifications/Messages/Invites/Preferences/Badges** and document **Summary, Activity, Bookmarks** as the
> intentional Profile detached-card exceptions.
>
> **Implemented in:** `connectors/above-user-summary-stats/fomio-summary-hero.gjs` (editorial hero),
> `lib/fomio-profile-summary-fields.js` (+ test), `common/common.scss` + `mobile/mobile.scss` (hero styles
> + touch refinements), `locales/en.yml` (`profile_hero.*`). The desktop detached-card chrome is the
> **pre-existing** Activity parent-child / Summary editorial blocks in `common.scss` — no new global card
> block was added (an earlier attempt was removed for conflicting with them). Bookmarks self-gating already
> enforced by `lib/fomio-account-sections.js` (omits Bookmarks for non-self) — no new gating code needed.

---

## 9. Recommended default path (if you just want the safe answer)

> v1 = **(A) additive restyle**, **theme-only** (no plugin), **public profile + self**, sections
> **Summary + Activity + Bookmarks**, **master-pane** on expanded/compact, **tabs** on rail, **stack** on
> touch, **real route transitions** (deep-linkable), Preferences/Notifications/Messages left on their
> existing native treatments for v2. Hero = **editorial**. This ships the most prototype value with zero
> Discourse forks and no plugin install.
