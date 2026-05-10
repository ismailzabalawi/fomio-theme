# Fomio user shell plugin plan

## Purpose

`discourse-fomio-user-shell` is the smallest production-minded plugin that gives Fomio structural ownership over the native Discourse Me shell without rebuilding user pages.

It exists so future Option 3 work can target a Fomio-owned contract on top of the native user content stack instead of relying on manual DOM reparenting.

## Source layout

- Monorepo source of truth: `plugins/discourse/discourse-fomio-user-shell/`
- Local runtime/dev mirror: `discourse/plugins/discourse-fomio-user-shell/`

The plugin should be versioned from the monorepo path. The nested `discourse/` checkout is a local vendor workspace and may mirror the plugin for development or runtime testing.

## Why manual DOM reparenting is not the production path

- It moves live Ember-managed nodes after render.
- It risks breaking `LoadMore`, focus, scroll restoration, form lifecycle, and plugin-added rows.
- It creates a harder-to-debug fork between Discourse's expected hierarchy and the runtime hierarchy.

The plugin therefore stays additive and does not move or duplicate `#user-content`.

## Strategy chosen

1. Use the existing core `.new-user-content-wrapper` as the structural shell.
2. Add a Fomio-owned contract to that wrapper and its native children from a plugin initializer.
3. Gate the behavior with site settings and keep it mobile-only by default.
4. Leave all existing Fomio theme menus intact.

## Contract exposed to the theme

When enabled on supported routes, the plugin adds:

- `.fomio-user-shell`
- `[data-fomio-user-shell="true"]`
- `[data-fomio-user-section="activity|notifications|messages|preferences|invites"]`
- `[data-fomio-user-secondary-nav]`
- `[data-fomio-user-content]`

## What the plugin does not do

- It does not fetch replacement data.
- It does not build custom user pages.
- It does not hide native content.
- It does not remove or replace plugin outlets.
- It does not change desktop unless the mobile-only guard is disabled.

## Enable / disable

- Enable: turn on `fomio_user_shell_enabled`.
- Restrict to mobile: leave `fomio_user_shell_mobile_only` on.
- Debug outline: turn on `fomio_user_shell_debug`.
- Disable cleanly: turn `fomio_user_shell_enabled` back off.

## Known limitations

- The plugin depends on Discourse continuing to render `.new-user-content-wrapper` and `.user-navigation.user-navigation-secondary` on the supported user routes. Most sections use a direct-child `#user-content` root; Invites is the narrow exception and falls back to direct-child `.user-content`.
- It does not create a new wrapper outlet in core.
- True in-card Level 3 containment would still require a follow-up Discourse extension if the final Option 3 design needs a different Glimmer-owned hierarchy.

## Option 3 path from here

1. Keep the current M2 menus as-is.
2. Update the Fomio theme to target the plugin contract instead of raw core selectors where practical.
3. If the final card design still needs a new outlet or wrapper structure, implement that as a narrowly scoped Discourse extension after the theme contract has been validated.

---

## H4-B — Contract verification and theme readiness (staging checklist)

### Settings (staging / preview QA)

| Setting | Value for H4-B |
|--------|----------------|
| `fomio_user_shell_enabled` | `true` |
| `fomio_user_shell_mobile_only` | `true` |
| `fomio_user_shell_debug` | `true` first, then `false` after outline checks |

Theme preview: append `?preview_theme_id=33` (or the active Fomio theme id) to Me URLs.

### Code-verified contract (monorepo)

Implementation in `assets/javascripts/discourse/initializers/fomio-user-shell.js` matches the documented contract when `decorateShell` runs successfully:

| Target | Attributes / class |
|--------|---------------------|
| `#main-outlet .user-main .new-user-content-wrapper` | `class` includes `fomio-user-shell`; `data-fomio-user-shell="true"`; `data-fomio-user-section="<section>"`; if debug on, `data-fomio-user-shell-debug="true"` |
| Direct child `.user-navigation.user-navigation-secondary` | `data-fomio-user-secondary-nav="true"`; `data-fomio-user-section="<section>"` |
| Direct child `#user-content` | `data-fomio-user-content="true"`; `data-fomio-user-section="<section>"` |
| Invites-only fallback when `#user-content` is absent | direct child `.user-content` receives `data-fomio-user-content="true"`; `data-fomio-user-section="invites"` |

`<section>` is one of: `activity`, `notifications`, `messages`, `preferences`, `invites` (from `resolveFomioUserSection` in `lib/fomio-user-shell.js`).

`cleanupDecorations()` removes these dataset keys and the `fomio-user-shell` class when the shell should not apply (disabled, wrong route, or desktop when mobile-only).

### Native selectors the theme still expects

The plugin **does not replace** these; it decorates nodes that must remain present:

- `.new-user-content-wrapper`
- `.user-navigation.user-navigation-secondary`
- `#user-content` for Activity / Notifications / Messages / Preferences
- direct-child `.user-content` for Invites

If core ever stops using **direct** `nav` and content-root children of the wrapper, the plugin’s `:scope >` selectors must be updated — see **Risks**. The only content fallback allowed today is Invites-only `.user-content`.

### Mobile-only: `site.mobileView`, not just CSS width

`shouldApplyFomioUserShell` uses `site.mobileView` when `fomio_user_shell_mobile_only` is true. **Resizing a desktop browser to 390px does not by itself set `mobileView`.** For H4-B you must verify on a client Discourse treats as mobile, for example:

- Device toolbar with a mobile user agent, or
- A logged-in session where Discourse has switched to mobile view, or
- Temporarily set `fomio_user_shell_mobile_only` to `false` on a **non-production** environment to confirm attributes on desktop (then revert).

### DevTools: confirm the contract on a loaded Me page

Paste in the console:

```js
(() => {
  const w = document.querySelector(
    "#main-outlet .user-main .new-user-content-wrapper"
  );
  const n = w?.querySelector(
    ":scope > .user-navigation.user-navigation-secondary"
  );
  const section = w?.dataset.fomioUserSection;
  const c =
    w?.querySelector(":scope > #user-content") ||
    (section === "invites" ? w?.querySelector(":scope > .user-content") : null);
  return {
    structure: { wrapper: !!w, directNav: !!n, directContent: !!c },
    wrapper: w && {
      fomioUserShell: w.dataset.fomioUserShell,
      fomioUserSection: w.dataset.fomioUserSection,
      fomioUserShellDebug: w.dataset.fomioUserShellDebug,
      hasClass: w.classList.contains("fomio-user-shell"),
    },
    nav: n && {
      fomioUserSecondaryNav: n.dataset.fomioUserSecondaryNav,
      fomioUserSection: n.dataset.fomioUserSection,
    },
    content: c && {
      fomioUserContent: c.dataset.fomioUserContent,
      fomioUserSection: c.dataset.fomioUserSection,
    },
  };
})();
```

Expected when the plugin is active on a supported route and guards pass: `structure` all `true`, dataset values populated as above, `fomioUserShellDebug` present only when the debug setting is on. On Invites, `structure.directContent` may be satisfied by the direct-child `.user-content` fallback rather than `#user-content`.

### Debug mode

- With `fomio_user_shell_debug = true`, plugin SCSS outlines `[data-fomio-user-shell-debug="true"]` (the wrapper only).
- Spot-check **topic list**, **Byte**, and **auth** routes: wrapper should **not** carry the shell attributes.
- Set `fomio_user_shell_debug = false` and hard-refresh: dashed outline must disappear.

### Behavior checks (manual)

With plugin enabled and theme preview on:

- Fomio M2 section menus still render; active row logic unchanged by the plugin alone.
- Native core pills remain suppressed per existing theme rules when Fomio menus mount.
- Plugin rows: still mirrored or visible per M2 rules.
- Messages: inbox dropdown and New Message remain visible.
- Notifications: dismiss controls remain visible.
- Preferences: forms still save (no plugin mutation of forms).
- Invites: list/actions usable.
- No horizontal overflow regressions on the shell.
- With `fomio_user_shell_enabled = false`, attributes and `fomio-user-shell` class should be absent after navigation (initializer cleans up).

### Theme readiness (`apps/web/common/common.scss`)

No SCSS changes are required for H4-B. For **later** (e.g. H4-C Option 3), the following patterns can be **strengthened additively** by also requiring the data contract (keep existing selectors until fully migrated):

| Current gate (examples) | Future additive strengthener |
|------------------------|------------------------------|
| `body.user-activity-page:has(.fomio-activity-section-menu)` | …`[data-fomio-user-shell="true"][data-fomio-user-section="activity"]` on the same wrapper subtree, or an ancestor selector combining `body.user-activity-page` with `[data-fomio-user-section="activity"]` |
| Same pattern for `user-notifications-page`, `user-messages-page`, `user-invites-page`, `user-preferences-page` | Matching `data-fomio-user-section` value |
| `#main-outlet .user-main .new-user-content-wrapper` (M2-H1 blocks) | Same node will carry `data-fomio-user-shell` when the plugin ran; compound selectors reduce accidental matches if core adds another wrapper |

Prefer **additive** compound selectors (AND) over replacing body `:has(.fomio-*-section-menu)` until Option 3 is scoped, so M2 still works if the plugin is off.

### Known: `/my/preferences` and preview query

Discourse may redirect `/my/preferences/...` and drop `preview_theme_id`. For theme preview QA, prefer **`/u/:username/preferences/...`** with the preview param, consistent with M2-H2 QA notes in `me-second-level-navigation.md`.

### H4-B verification result (agent session)

- **Source / contract:** Verified against plugin initializer and `fomio-user-shell.js`; aligns with README contract list.
- **Invites correction:** Invites does not reliably expose direct-child `#user-content` in live preview DOM. The plugin now treats direct-child `.user-content` as an Invites-only fallback and still decorates it with `[data-fomio-user-content]`.
- **Live DOM on meta.fomio.app:** Not asserted here: automated browser tooling did not expose `data-*` on nodes; **complete H4-B sign-off requires running the DevTools snippet on staging with real `mobileView` (or temporarily disabling mobile-only on a safe environment).**

### Recommendation

**Proceed** to H4-C (small Invites Option 3 prototype) **only after** staging confirms the DevTools snippet returns populated attributes on all target URLs with settings as above, and debug off shows no outline. If `structure.directNav` or `structure.directContent` is false, **pause** and fix plugin selectors or core DOM assumptions first.

---

## Files touched by H4-B documentation

- `apps/web/docs/web/fomio-user-shell-plugin-plan.md` (this file)
- `apps/web/docs/web/me-second-level-navigation.md` (§20.7 cross-reference)
