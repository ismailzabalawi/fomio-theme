# Fomio Web Theme — Claude Guide

**`apps/web/`** is the Discourse theme for Fomio. All web theme work happens here and is synced directly to Discourse via GitHub.

## Product Constitution (Highest Authority)

`apps/mobile/docs/00-product/product-ui-rules.md` governs all UI and copy decisions across every surface.

Terminology is non-negotiable:

| Use | Never use |
|-----|-----------|
| Hub | Category, Section, Group |
| Teret | Subcategory, Channel, Thread |
| Byte | Post, Article, Topic, Entry |

## Skills

| Skill | Triggers |
|-------|---------|
| `discourse-theme-developer` | `/outlet`, `/transformer`, `/connector`, `/scss`, `/theme` |
| `discourse-archeologist` | `/trace`, `/schema`, `/serialize` — when tracing what Discourse API returns |

## Stack

- **Components:** GJS (`.gjs`) only — no legacy widgets, no `.hbs`
- **Entry points:** `apiInitializer` from `discourse/lib/api`
- **Settings:** `settings.yml` → `import { settings } from "virtual:theme"` (all keys prefixed `fomio_`)
- **i18n:** `locales/en.yml` → `i18n(themePrefix("key"))` — never inline strings
- **Styling:** SCSS with `fomio-` class prefix, `--d-*` Discourse variables for color
- **Source of truth for Discourse internals:** `discourse/` at repo root — read-only

## Current File Structure

```
apps/web/
├── about.json
├── settings.yml                      # fomio_* settings
├── locales/en.yml                    # themePrefix() strings
├── common/
│   ├── common.scss                   # --fomio-* tokens + shared styles
│   └── after_header.html
├── desktop/desktop.scss
├── mobile/mobile.scss
└── javascripts/discourse/
    ├── api-initializers/             # apiInitializer entry points
    │   ├── theme-initializer.gjs     # Mobile web redirect + app handoff
    │   └── my-theme.gjs
    └── connectors/
        ├── topic-list-main-link-bottom/fomio-topic-context.gjs
        ├── topic-title/fomio-topic-reading-meta.gjs
```

## Auth & Handoff Flow

> **Do not modify `theme-initializer.gjs` without reading this section.**
> The guards below look like dead code but removing either one breaks sign-in.

### How the mobile app opens Discourse web

The app uses two different browser primitives, and the theme must behave differently for each:

| Flow | Browser primitive | Purpose |
|------|------------------|---------|
| Sign-in | `WebBrowser.openAuthSessionAsync` | Opens ASWebAuthenticationSession (iOS) / Chrome Custom Tab (Android). The session captures the first `fomio://` deep link it sees and returns it to the app. |
| Sign-up | `WebBrowser.openBrowserAsync` | Opens a plain browser. No deep link interception — the user must complete all Discourse web steps before the app gets control back. |

### Sign-in flow (User API Key auth)

```
App calls openAuthSessionAsync(/user-api-key/new)
  → Discourse 302s to /login        (user not logged in on web)
  → User fills login form
  → Discourse redirects to /        (post-login default)
  → Discourse redirects to /user-api-key/new
  → User taps "Authorize"
  → Discourse redirects to fomio://auth_redirect?payload=...
  → ASWebAuthenticationSession catches it, returns payload to app
  → lib/auth.ts decrypts payload, stores API key
```

**GUARD 1** (`theme-initializer.gjs` `/login` handler):
When the session opens `/user-api-key/new` and Discourse 302s to `/login`,
`performance.getEntriesByType('navigation')[0].redirectCount > 0` is true.
The theme must NOT fire the `fomio://signin?autoAuth=true` redirect here,
or the auth session intercepts that deep link (no `payload`) and throws "Authorization cancelled".
Instead the theme sets `sessionStorage['fomio_auth_flow'] = '1'`.

**GUARD 2** (`theme-initializer.gjs` home handler):
After the user logs in, Discourse redirects to `/` before proceeding to `/user-api-key/new`.
The home handler checks for the `fomio_auth_flow` flag and skips the redirect, then clears the flag.
Without this guard the home redirect fires, the auth session intercepts `fomio://signin?autoAuth=true`
(wrong — no `payload`), and sign-in fails silently.

### Sign-up flow

```
App calls openBrowserAsync(/signup?fomio=1)
  → User fills signup form
  → Discourse navigates to /u/account-created   ("check your email")
  → User opens email, taps activation link
  → Browser opens /u/activate-account/:token
  → Discourse renders page with "Activate Account" button
  → User taps button (PUT /u/activate-account/:token.json)
  → Discourse JS: window.location.href = "/"   (activate-account.gjs:84)
  → Browser lands on /
  → Theme fires → fomio://signin?autoAuth=true
  → App comes to foreground, autoAuth triggers sign-in modal
```

No extra guards needed: the signup browser never visits `/login` with `redirectCount > 0`,
so `sessionStorage['fomio_auth_flow']` is never set and the home redirect fires correctly.

**Do NOT add redirects at `/u/account-created` or `/u/activate-account/:token`.**
The user must complete those Discourse steps in the browser. The only correct trigger is `/`.

### Direct `/login` tap (email link, mobile browser)

A user taps `meta.fomio.app/login` directly in email or Safari.
`redirectCount = 0` → theme fires `fomio://signin?autoAuth=true` → app sign-in.

### Deep links used

| Deep link | Destination |
|-----------|-------------|
| `fomio://signin?autoAuth=true` | `app/(auth)/signin.tsx` — autoAuth triggers auth modal |
| `fomio://byte/:id` | Specific Byte — from topic footer handoff button |

All deep links are constructed from the `fomio_app_url` theme setting. Never hardcode `fomio://`.

### Sources verified against

- Discourse activation redirect: `discourse/frontend/discourse/app/templates/activate-account.gjs:84`
- Discourse login redirect on unauthenticated API key request: `app/controllers/user_api_keys_controller.rb:32`
- App auth session: `apps/mobile/lib/auth.ts signIn()`
- App deep link routing: `apps/mobile/lib/deep-linking.ts`

---

## Rules

- **Always verify outlets** before using: `rg '<PluginOutlet @name="name"' discourse/app`
- **Always verify transformers** before using: `rg 'applyValueTransformer.*"key"' discourse/app`
- **Transformers before workarounds:** transformer → connector → `onPageChange` → DOM (last resort)
- **All CSS scoped** under `fomio-` prefix — no bare Discourse class overrides
- **No fetch calls** in theme JS — themes are UI-only
- **No hardcoded deep links** — always use `fomio_app_url` setting
- **No forbidden terminology** in `locales/en.yml` or any component copy

## Design System Notes

### Color — Shared Token System

The web theme and mobile app share the same canonical palette from `packages/design-tokens/tokens.js`. The web theme mirrors `toCssVariables('light')` in `common/common.scss` Section 1 — run `npm run tokens:check` after any token change to catch drift.

| Token | Value | Variable |
|-------|-------|----------|
| Primary | `#C44536` terracotta | `--fomio-primary` |
| Background | `#F8F7F3` cream | `--fomio-bg` |
| Text | `#1A1A1A` | `--fomio-text` |
| UI font | Raleway | `--fomio-font-ui` |
| Body font | Lora (serif) | `--fomio-font-serif` |

### Responsive Breakpoints

| Range | Stylesheet applied |
|-------|--------------------|
| 0–767px | `mobile/mobile.scss` (Discourse applies automatically) |
| 768–899px | `desktop/desktop.scss` (tablet override) |
| 900px+ | `desktop/desktop.scss` (full desktop) |

No explicit 320px baseline — relies on browser defaults. Acceptable for current scope.

## Studio Protocols

All four protocols apply before any connector or component ships:

- **Design Critique** (3 passes, web-adapted)
- **Exploration Mode** (3 directions) when no existing pattern fits
- **Quality Audit** (6 passes) before merging to main
- **DS Evolution** (DSP required) before any new reusable component

See "Web Theme Adaptations" in `.cursor/rules/studio.mdc`.

## Ship Checklist

- [ ] Design critique passed (all 3 passes, web-adapted)
- [ ] Quality audit passed (all 6 passes)
- [ ] Terminology check: `node apps/mobile/scripts/check-terminology.js`
- [ ] Token sync check: `npm run tokens:check`
- [ ] Verified in both desktop and mobile Discourse preview
