# Preferences Integration Guide

## Status

This document describes a **deprecated replacement-screen experiment** and is
no longer the source of truth for Preferences work in `apps/web`.

## Current Rule

Preferences is a **native Discourse leaf**. Do not replace `/preferences/*`
with a custom route body, profile-tab takeover, or standalone settings screen.

- Keep `discourse/frontend/discourse/app/templates/preferences.gjs` and its
  child templates as the source of truth for fields, validation, save flows,
  and plugin compatibility.
- Use `body.user-preferences-page` styling in `common/common.scss` to apply
  Fomio’s three-layer system to the real native controls and group structure.
- Add only small route-local enhancements through verified preference outlets.

## Where To Look Instead

- [mobile-navigation.md](/Users/ismailzabalawi/Projects/Fomio/apps/web/docs/web/mobile-navigation.md)
- [touch-preferences-redesign-pattern.md](/Users/ismailzabalawi/Projects/Fomio/apps/web/docs/web/touch-preferences-redesign-pattern.md)
- [CLAUDE.md](/Users/ismailzabalawi/Projects/Fomio/apps/web/CLAUDE.md)
