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

- The plugin depends on Discourse continuing to render `.new-user-content-wrapper`, `.user-navigation.user-navigation-secondary`, and `#user-content` on the supported user routes.
- It does not create a new wrapper outlet in core.
- True in-card Level 3 containment would still require a follow-up Discourse extension if the final Option 3 design needs a different Glimmer-owned hierarchy.

## Option 3 path from here

1. Keep the current M2 menus as-is.
2. Update the Fomio theme to target the plugin contract instead of raw core selectors where practical.
3. If the final card design still needs a new outlet or wrapper structure, implement that as a narrowly scoped Discourse extension after the theme contract has been validated.
