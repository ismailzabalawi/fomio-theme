# Fomio Web Theme Docs

Documentation for `apps/web` (stable) and `apps/web-beta` (beta) Discourse themes.

> **Product Constitution:** All UI and copy decisions defer to
> `apps/mobile/docs/00-product/product-ui-rules.md`.
> Terminology (Hub, Teret, Byte) is non-negotiable across all surfaces.

## Agent Rules & Skills

- **Rules:** `.cursor/rules/themerule.mdc` (tech standards) + `.cursor/rules/studio.mdc` (protocols)
- **Skill:** `.cursor/skills/discourse-theme-developer/` — use `/outlet`, `/transformer`, `/connector`, `/scss`, `/theme`
- **Discourse backend reference:** `.cursor/skills/discourse-archeologist/` — use when you need to understand what the API returns

## Two-Theme Workflow

| Theme | Path | Purpose |
|-------|------|---------|
| Beta | `apps/web-beta/` | New features land here first |
| Stable | `apps/web/` | Promoted from beta when validated |

Always develop in `web-beta` first. Promote to `web` only after critique and quality audit pass.

## Studio Protocols (Web-Adapted)

All four studio protocols apply to theme work — see the "Web Theme Adaptations" section in `.cursor/rules/studio.mdc`:

- **Design Critique** — 3 passes before any connector or component ships
- **Exploration Mode** — 3 directions when no existing pattern fits
- **Quality Audit** — 6-pass audit pre-release (compliance, state, a11y, perf, resilience, brand coherence)
- **DS Evolution** — DSP required before any new reusable theme component

## Theme File Structure

```
apps/web/
├── about.json              # Theme metadata + color schemes (Ink & Paper)
├── settings.yml            # Theme settings — all keys prefixed fomio_
├── locales/en.yml          # i18n strings — all keys via themePrefix()
├── common/
│   ├── common.scss         # Design tokens (:root --fomio-*) + shared styles
│   ├── head_tag.html       # <head> injections (Google Fonts, meta)
│   └── after_header.html   # After-header HTML
├── desktop/desktop.scss    # Desktop-only overrides
├── mobile/mobile.scss      # Mobile browser overrides
└── javascripts/discourse/
    ├── api-initializers/   # Theme entry points (apiInitializer)
    ├── components/         # Glimmer GJS components
    └── connectors/         # Outlet connectors
        └── <outlet-name>/<fomio-name>.gjs
```

## Design Token Sync

The `--fomio-*` CSS custom properties in `common/common.scss` must stay aligned with the mobile token values in `apps/mobile/src/theme/tokens.ts`. When mobile tokens change, update the theme SCSS variables to match.

| Token category | Mobile source | Theme equivalent |
|---------------|---------------|-----------------|
| Typography | `tokens.ts` → `fontFamily`, `fontSize` | `--fomio-font-serif`, `--fomio-text-*` |
| Color palette | `tokens.ts` → color values | `about.json` color_schemes + `--d-*` via Discourse |
| Spacing | `tokens.ts` → spacing scale | `--fomio-*` spacing (define as needed) |

## Deployment

CI syncs both themes to Discourse on push to `main`:
- `apps/web` → production Fomio theme
- `apps/web-beta` → beta Fomio theme

To test locally, use the [Discourse Theme CLI](https://meta.discourse.org/t/discourse-theme-cli/148421) or sync to a local Discourse dev instance.

## Templates

- `docs/_templates/theme-feature-template.md` — Theme feature kickoff checklist (9 sections: problem, API data available, approach, files, DS, critique, verification, promotion, DoD)

## Mobile App Handoff — Auth Flow

The theme handles redirecting mobile users from the Discourse web into the Fomio app. This is the primary bridge between email-based auth flows and the native app.

### How it works

All logic lives in `api-initializers/theme-initializer.gjs`. It runs on every page change via `api.onPageChange` and only activates for mobile browsers outside the app webview (detected via `User-Agent`).

**Deep link base URL:** Read from `settings.fomio_app_url` (configured in Discourse admin). Falls back to `fomio://` if unset.

### Active cases

| Trigger | Deep link | Purpose |
|---------|-----------|---------|
| URL = `/login` | `{appUrl}signin?autoAuth=true` | Redirect web login to in-app OAuth |
| URL matches `/u/activate-account/{token}` | `{appUrl}activate?token={token}` | Hand activation token to app immediately |

### Activation flow detail

When a user taps the activation link in their email, the system browser opens `/u/activate-account/{token}`. The theme intercepts this URL on `onPageChange` (which fires on URL change, before any user interaction) and immediately redirects to `fomio://activate?token={token}`.

The app receives the token via deep link, calls `GET /session/hp.json` to get a honeypot challenge, then `PUT /u/activate-account/{token}.json` with the challenge response. Discourse confirms the email token and activates the account.

This replaces the previous approach of waiting for Discourse's 3-screen browser activation flow to complete and trying to detect success via DOM inspection (which was unreliable because `onPageChange` only fires on URL changes, not DOM mutations).

### What the theme does NOT handle

- Signup form → the user completes signup in the system browser natively. The theme does not intercept `/signup` or `/u/account-created`. Discourse's own session handles resend.
- Approval waiting → `pending-approval` is handled entirely in the app.

### Configuration

Set `fomio_app_url` in Discourse admin → Customize → Themes → Fomio → Settings:
- Production: `fomio://`
- If using a custom scheme, update accordingly

---

## Documents to Add Here

As theme development matures, add docs to this folder:
- `connectors.md` — catalog of all active connectors and their outlet slots
- `design-tokens.md` — full `--fomio-*` token reference for the web
- `color-scheme.md` — Ink & Paper color decisions and rationale
- `adr/` — theme-specific architectural decisions
