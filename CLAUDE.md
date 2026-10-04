# apps/web — Fomio Discourse theme

Native-first Discourse theme for Fomio's web surface — a Reddit alternative on
`meta.fomio.app`. Imported into the Fomio monorepo from the `fomio-web` rebuild.
**This monorepo path is the source of truth** for Discourse theme sync.

The previous Sidebar-OS theme lives at `../web-legacy/` (quarry only). Do not
extend it. The rebuild's first pass also remains on the external repo's
`archive/v0` branch if needed.

**Read `docs/` before working here.** Start with `docs/00-roadmap.md`.

**Composer work:** read `docs/13-composer-agent-guide.md` before proposing or
changing anything. It links the v4 roadmap, IA, researched routes and native
reuse contract. The old design prompt and theme-38 experiment are historical,
not instructions or an approved implementation baseline. Documentation
alignment does not itself authorize implementation or deployment.

Rules that are easy to break:

- Work the current phase of the roadmap only. Redesign a Discourse screen
  only when it materially affects the primary Fomio experience — never
  because it looks like Discourse. Solve each need at the highest rung of
  the ladder: setting → native behaviour → theme → component → plugin.
- No sidebar for v1. No replacement search, notifications, moderation or
  composer engine.
- Discourse owns data, vocabulary and configuration; the theme owns layout and
  behaviour. No colour literals, no font names, no new CSS custom properties.
- Discourse owns rendered terminology. The existing site-text overrides stay
  active and unchanged for now; never copy their wording into theme literals.
  Use Discourse's i18n output so future label changes remain controlled by
  Discourse. Do not edit or revert the overrides unless the user asks.
- Before writing a variable, selector or transformer, confirm it in core at
  the server's commit — see `docs/02-discourse-core-reference.md`. Never from
  memory or shorthand.
- Restyle what Discourse renders; never insert a design's own header, nav or
  frame beside it. New markup only in an outlet named in
  `scripts/check-duplication.sh`'s allowlist.
- Run `scripts/check-native.sh`, `scripts/check-variables.sh`,
  `scripts/check-scss.sh` and `scripts/check-duplication.sh` before calling
  work done.
- Ask when direction is unclear. Commit and push only when asked.
