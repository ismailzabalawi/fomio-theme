# Archived — Me embedded Level-2 / owned screens (2026-05)

This folder preserves the previous approach:

- Mirrored second-level nav injected into Discourse’s `.user-navigation-secondary` via `in-element` (`fomio-*-section-menu` components).
- Optional API-owned Activity / Notifications UIs (`fomio-owned-*`) behind theme settings.

**Superseded by:** native Discourse Me routes + touch `fomio-me-stack-header` + optional in-page filter chips (`fomio-me-filter-chips`). See [`apps/web/docs/web/me-navigation.md`](../docs/web/me-navigation.md).

**Location:** This tree lives under `apps/web/_archive/me-embedded-l2/` **outside** `javascripts/discourse/` so Discourse’s theme compiler does not bundle these `.gjs` files (they used to break the live theme when placed under `discourse/_archive/`).

**Note:** Connector imports pointed at live `components/` paths; treat as read-only reference only.
