# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**`apps/web/`** is the Discourse theme for Fomio. All web theme work happens here and is synced directly to Discourse via GitHub.

## Product Constitution (Highest Authority)

`apps/mobile/docs/00-product/product-ui-rules.md` governs all UI and copy decisions across every surface.

Terminology is non-negotiable:

| Use | Never use |
|-----|-----------|
| Hub | Category, Section, Group |
| Teret | Subcategory, Channel, Thread |
| Byte | Post, Article, Topic, Entry |

## Dev Commands

All commands run from the **repo root** (`/fomio/`):

```bash
npm run tokens:check   # Verify common.scss tokens are in sync with packages/design-tokens
npm run tokens:fix     # Auto-sync tokens from packages/design-tokens into common.scss

# Terminology check (run from repo root)
node apps/mobile/scripts/check-terminology.js
```

There is no local build step — the theme is deployed by pushing to GitHub, which Discourse syncs automatically.

## Skills

| Skill | Triggers |
|-------|---------|
| `fomio-web-ds` | `/web-ds`, `/token`, `/layout`, `/auth-ui`, `/editorial`, `/sidebar`, `/breakpoint` |
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
├── about.json                        # Discourse color schemes (light + dark palette)
├── settings.yml                      # fomio_* settings (fomio_app_url)
├── locales/en.yml                    # themePrefix() strings
├── common/
│   ├── common.scss                   # --fomio-* tokens + all shared styles
│   ├── body_tag.html                 # Trust line injection into /user-api-key/new
│   ├── head_tag.html                 # Google Fonts preconnect + stylesheet link
│   └── after_header.html
├── desktop/desktop.scss
├── mobile/mobile.scss
├── docs/
│   ├── auth-ui-stitch-guide.md       # Design prompts for all 17 auth screens
│   └── manuscript-design-system.md  # Design system strategy reference
└── javascripts/discourse/
    ├── api-initializers/
    │   ├── theme-initializer.gjs     # Auth UI enhancements + mobile handoff (see below)
    │   ├── fomio-color-mode.gjs      # Dark mode: syncs html.fomio-color-dark
    │   ├── fomio-layout.gjs          # Sidebar layout: toggles body.fomio-sidebar-active
    │   └── my-theme.gjs             # Legacy placeholder — do not add to
    ├── components/
    │   └── homepage-shell.gjs        # Homepage editorial shell component
    └── connectors/
        ├── above-site-header/fomio-sidebar.gjs  # Persistent sidebar nav (desktop)
        ├── login-header-bottom/fomio-login-subheader.gjs
        ├── login-before-modal-body/  # Login modal body overrides
        ├── create-account-header-bottom/fomio-signup-subheader.gjs
        ├── create-account-before-modal-body/  # Signup modal body overrides
        ├── topic-list-main-link-bottom/fomio-topic-context.gjs
        ├── topic-title/fomio-topic-reading-meta.gjs
```

## `theme-initializer.gjs` — Scope

> **Do not modify this file without reading both this section and the Auth & Handoff Flow section.**
> The guards look like dead code but removing either breaks sign-in.

This initializer runs on every Ember page change and on initial page load. It handles:

1. **Mobile browser → app handoff** — detects mobile UA, shows overlay, deep-links to app
2. **Signup password strength bar** — terracotta meter injected under `#new-account-password`
3. **Forgot-password modal** — inline email validity hint, "Back to sign in" link, success-state reshape
4. **2FA TOTP** — OTP grid styling, eyebrow/heading/code-label injection, backup/passkey switch links
5. **2FA backup code** — key icon, warning pill, auto-formatting `xxxx-xxxx-xxxx`, switch links
6. **Passkey loading state** — spinner + label swap on button click while biometric dialog is open

All DOM manipulation is idempotent — each function checks for its own markers (`data-fomio-*`, class names) before injecting.

## `body_tag.html` — Trust Line

The `/user-api-key/new` authorization page is rendered by Rails with `no_ember: true` — the apiInitializer never runs there. The trust line ("You're authorizing the official Fomio app.") is injected via an inline `<script>` in `body_tag.html`, which Discourse injects into every page's `<body>`. The script finds `.authorize-api-key` and guards against double-injection.

## `fomio-color-mode.gjs` — Dark Mode

Discourse ships two color-scheme `<link>` tags (`link.light-scheme`, `link.dark-scheme`) and toggles their `media` attribute to switch modes. This initializer observes those attributes and toggles `html.fomio-color-dark`, letting `common.scss` target dark-mode overrides via `.fomio-color-dark .fomio-*` selectors.

## `about.json` — Discourse Color Schemes

Defines the `Fomio` (light) and `Fomio Dark` color schemes. Discourse maps these to `--d-*` CSS variables site-wide. When changing brand colors, update both `about.json` (for `--d-*` variables used in Discourse core UI) and `common.scss` Section 1 (for `--fomio-*` tokens used in theme SCSS). Run `npm run tokens:check` to verify the theme tokens are in sync with `packages/design-tokens`.

## Auth & Handoff Flow

> The guards below look like dead code but removing either one breaks sign-in.

### How the mobile app opens Discourse web

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

**GUARD 1** (`theme-initializer.gjs` `/login` and `/session/*` handlers):
When the session opens `/user-api-key/new` and Discourse 302s to `/login` (or to `/session/*` for SSO, 2FA, OTP, or passkeys), `performance.getEntriesByType('navigation')[0].redirectCount > 0` is true.
The theme must NOT fire the `fomio://signin?autoAuth=true` redirect, or the auth session intercepts that deep link (no `payload`) and throws "Authorization cancelled".
- On `/login` with `redirectCount > 0`: sets `sessionStorage['fomio_auth_flow'] = '1'`
- On `/session/*` with `redirectCount > 0`: calls `markFomioAuthFlowIfRedirected()` which sets the same flag

**GUARD 2** (`theme-initializer.gjs` home handler):
After the user logs in, Discourse redirects to `/` before proceeding to `/user-api-key/new`.
The home handler checks for the `fomio_auth_flow` flag and skips the redirect, then clears the flag.
Without this guard the home redirect fires, the auth session intercepts `fomio://signin?autoAuth=true` (wrong — no `payload`), and sign-in fails silently.

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

No extra guards needed: the signup browser never visits `/login` with `redirectCount > 0`, so `sessionStorage['fomio_auth_flow']` is never set and the home redirect fires correctly.

**Do NOT add redirects at `/u/account-created` or `/u/activate-account/:token`.**
The user must complete those Discourse steps in the browser. The only correct trigger is `/`.

### Direct `/login` tap (email link, mobile browser)

A user taps `meta.fomio.app/login` directly in email or Safari.
`redirectCount = 0` → theme fires `fomio://signin?autoAuth=true` → app sign-in.

### Paths that bypass handoff entirely

`isDiscourseAuthSupportingPath()` blocks the handoff overlay for:
`/user-api-key`, `/session/`, `/password-reset`, `/u/activate-account`, `/u/account-created`, `/signup`, `/invites`, `/u/confirm`, `/auth/`

### Deep links used

| Deep link | Destination |
|-----------|-------------|
| `fomio://signin?autoAuth=true` | `app/(auth)/signin.tsx` — autoAuth triggers auth modal |
| `fomio://byte/:id` | Specific Byte — from topic footer handoff button |

All deep links are constructed from the `fomio_app_url` theme setting. Never hardcode `fomio://`.

### Sources verified against

- Discourse activation redirect: `discourse/frontend/discourse/app/templates/activate-account.gjs:84`
- Discourse login redirect on unauthenticated API key request: `app/controllers/user_api_keys_controller.rb:26-33`
- App auth session: `apps/mobile/lib/auth.ts signIn()`
- App deep link routing: `apps/mobile/lib/deep-linking.ts`

---

## Rules

- **Always verify outlets** before using: `rg '<PluginOutlet @name="name"' discourse/app`
- **Always verify transformers** before using: `rg 'applyValueTransformer.*"key"' discourse/app`
- **Transformers before workarounds:** transformer → connector → `onPageChange` → DOM (last resort)
- **All CSS scoped** under `fomio-` prefix — no bare Discourse class overrides
- **No fetch calls** in theme JS — themes are UI-only
- **No shared lib modules** — Discourse's theme build only processes `api-initializers/`, `connectors/`, and `components/`. Files in `lib/` are NOT compiled and cannot be imported. Duplicate shared constants instead.
- **No hardcoded deep links** — always use `fomio_app_url` setting
- **No hardcoded hex values** in SCSS — use `--fomio-*` tokens from `common.scss` Section 1
- **No forbidden terminology** in `locales/en.yml` or any component copy

## Design System Notes

### Color — Shared Token System

The web theme and mobile app share the same canonical palette from `packages/design-tokens/tokens.js`. `common.scss` Section 1 mirrors `toCssVariables('light')` — run `npm run tokens:check` after any token change to catch drift.

| Token | Value | Variable |
|-------|-------|----------|
| Primary | `#C44536` terracotta | `--fomio-primary` |
| Background | `#F8F7F3` cream | `--fomio-bg` |
| Text | `#1A1A1A` | `--fomio-text` |
| UI font | Raleway | `--fomio-font-ui` |
| Body font | Lora (serif) | `--fomio-font-serif` |

`common.scss` also has legacy alias variables (`--fomio-ink`, `--fomio-paper`, etc.) that map to the canonical names for backwards compatibility. Use canonical names (`--fomio-text`, `--fomio-bg`) in new code.

### Dark Mode

Dark palette is defined in `about.json` (`Fomio Dark` scheme) and Section **1B** of `common.scss`. The **web theme uses warm brown** (`#1a1917` background, terracotta accent `#e67458`) per the Fomio Design System Handoff — not AMOLED. The mobile app remains AMOLED via `packages/design-tokens`. `fomio-color-mode.gjs` toggles `html.fomio-color-dark` when the active Discourse color scheme is dark. Scope dark overrides under `html.fomio-color-dark` in SCSS.

### Responsive Breakpoints

| Range | Stylesheet applied |
|-------|--------------------|
| 0–767px | `mobile/mobile.scss` (Discourse applies automatically) |
| 768–899px | `desktop/desktop.scss` (tablet override) |
| 900px+ | `desktop/desktop.scss` (full desktop) |

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
