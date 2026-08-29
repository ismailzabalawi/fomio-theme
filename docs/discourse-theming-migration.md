# Discourse Theming Migration

Date: 2026-08-29
Status: In progress — steps 1, 3, 4 complete; step 2 partial
Visual QA: passed on `?preview_theme_id=33`, one defect found and fixed (see below)

## Rule

This is the styling counterpart of [taxonomy-admin-first-migration.md](./taxonomy-admin-first-migration.md).
Same principle, applied to colour and CSS:

> When Discourse already delivers a value through the colour-scheme system, prefer
> that over hard-coding it in the theme.

Theme SCSS should own:

- Fomio's *scale* — which value sits at each step of the ramp
- Fomio's layout, reading UX, and component composition

Theme SCSS should **not** own:

- literal hex values for anything derivable from a colour-scheme slot
- a second source of truth for which colour scheme is active
- a hand-maintained copy of a value Discourse already computes per scheme

## Why

Discourse's own first-party theme achieves a comparably aggressive re-skin at a
fraction of the size, because it re-points core's variables instead of
overriding core's components:

| | Fomio (at start) | Horizon (`discourse/themes/horizon/`) |
|---|---:|---:|
| SCSS lines | 32,175 | 3,567 |
| `!important` | 523 | 0 |
| `display: none` | 160 | 17 lines total |
| Core CSS vars used | 1 | the whole theme is built on them |

The gap is not styling ambition. It is the cost of maintaining a parallel
`--fomio-*` namespace that never meets the `--primary` / `--secondary` /
`--d-*` variables core components actually read.

## What Discourse already gives us

Verified against the vendored checkout in `discourse/`. These are the controls
to reach for first.

| Concern | Core mechanism | Source |
|---|---|---|
| Per-scheme stylesheet (light/dark) | `common/color_definitions.scss` is recompiled once per scheme | `lib/stylesheet/manager.rb:21` |
| Theme colour block appended into core's `:root` | `import_color_definitions` | `lib/stylesheet/importer.rb:128` |
| Derived neutral ramp from 10 slots | `$primary-50…900`, `$primary-low/medium/high`, `$secondary-*`, `$tertiary-*` | `common/foundation/color_transformations.scss` |
| Scheme-aware blend / choose functions | `blend-two-colors`, `dark-light-diff`, `dark-light-choose` | `common/foundation/variables.scss:174-202` |
| Scheme-aware shadows | `--shadow-card`, `--shadow-menu-panel`, `--shadow-modal`, `--shadow-composer` | `app/assets/stylesheets/color_definitions.scss:147-154` |
| Core aliases that cascade off the ramp | `--content-border-color`, `--table-border-color`, `--input-border-color`, `--metadata-color`, `--excerpt-color` | same file, `:138-146` |
| Theme SCSS partials on the Sass load path | `stylesheets/` (also accepts `scss/`) | `app/models/theme.rb:918-939`, `app/models/theme_field.rb:660` |
| Theme settings exposed as SCSS `$vars` | `Theme#scss_variables` | `app/models/theme.rb:942` |
| Self-hosted fonts + `--font-family` | `base_font` / `heading_font` site settings | `lib/stylesheet/importer.rb:52,62` |

## What changed

### 1. Neutrals derive from colour-scheme slots — done

`common/color_definitions.scss` is **generated** by `scripts/generate-web-colors.js`.
Edit the generator, never the output.

Before, every neutral was a hard-coded pair:

```scss
--fomio-border: #{dark-light-choose(#E3E3E6, #2A2A2C)};
```

Now it is computed from the slots with Discourse's own functions:

```scss
--fomio-border:      #{dark-light-choose(blend-two-colors($primary, $secondary, 14.3%),
                                         blend-two-colors($primary, $secondary, 2.8%))};
--fomio-border-soft: #{rgba($primary, 0.08)};
```

Hard-coded hex in that file: **21 → 9**. The nine left are the blue accent,
amber warning and info hues, which no Discourse slot can express.

**We did not adopt core's `--primary-low` ramp.** It was checked first and does
not fit: in the AMOLED dark scheme `$secondary` is pure black, so the whole
`--secondary-*` ramp collapses to `#000000`, and `--primary-low` lands at
`#383838` against Fomio's `#2A2A2C`. Horizon does not use the core ramp either —
it derives its own formulas from the slots. We solved blend percentages against
the canonical `@fomio/design-tokens` values instead.

Those percentages are **verified at build time**. The generator re-implements
`blend-two-colors` and `dark-light-diff` in JS and fails if any derived
expression drifts more than 10/255 from the token value:

```bash
node scripts/generate-web-colors.js --explain
```

```
--fomio-surface   light  #F2F1ED  vs token #F2F1EC   drift 0.8
--fomio-card      light  #FFFFFF  vs token #FFFFFF   drift 0.0
--fomio-muted     light  #6E6E6C  vs token #6B6B72   drift 6.1
--fomio-secondary light  #61605F  vs token #5C5D67   drift 8.3
```

The residual drift is the slight cool tint in the old neutrals, which cannot be
derived from Fomio's warm slots. That is the accepted price of admin-editability.

One deliberate value change: `--fomio-danger-soft` was `rgba(220,38,38,·)` while
`--fomio-danger` is `#EF4444`. It now derives as `rgba($danger, ·)`, so the wash
finally matches its own base colour — about 2 RGB units at 12% alpha.

### 2. Elevation moved into per-scheme tokens — partial

Values that differ light↔dark belong in `color_definitions.scss`, not in an
`html.fomio-color-dark` override block. Added:

`--fomio-shadow-sm`, `--fomio-shadow-card`, `--fomio-shadow-menu`,
`--fomio-shadow-lift`, `--fomio-shadow-avatar`, `--fomio-border-hover`,
`--fomio-hatch`

Blocks removed: **34 → 23**. Among them:

- **Two dead rules.** `body.fomio-color-dark …` on the stats section never
  matched — `fomio-color-mode.gjs` sets the class on `<html>`, not `<body>`.
- **Two duplicate no-ops.** `html.fomio-color-dark .fomio-topic-context__thumb`
  appeared twice, setting the value the light rule already set.
- **One false split.** `--fomio-hatch` is `rgba($primary, 0.045)` in *both*
  schemes; light and dark were the same formula written as two literals.

### 3. Discourse core bridge — done

Eight declarations added to the generated colour layer:

```scss
/* common/color_definitions.scss — generated */
--primary-very-low:  var(--fomio-surface);
--primary-low:       var(--fomio-border);
--primary-400:       var(--fomio-border);
--primary-medium:    var(--fomio-muted);
--primary-high:      var(--fomio-secondary);
--shadow-card:       var(--fomio-shadow-card);
--shadow-menu-panel: var(--fomio-shadow-menu);

/* stylesheets/base.scss — see "Where a bridge declaration must live" */
:root { --d-content-background: var(--fomio-card); }
```

The theme's colour block is appended into core's `:root`, so a later declaration
wins at equal specificity — **no `!important` needed**. Only the ramp positions
Fomio deviates on are listed; core aliases the rest off them, so the cascade is
free. This puts **951 references across Discourse's stylesheets** onto the Fomio
scale.

#### Where a bridge declaration must live

Bridging from `color_definitions.scss` only works for variables core declares
**in that same file**. Core deliberately puts some custom properties in
`common/foundation/base.scss` instead — its own comment says why:

> These CSS custom properties are added here instead of in variables.scss
> because variables.scss is injected into every theme CSS file which causes
> problems when overriding custom properties in themes.

That file ships in the `common` bundle, which the browser loads *after*
`color_definitions`. Bridging such a variable from the colour layer is silently
dead. Load order confirmed on a live preview:

```
[5][6]  color_definitions_*    <- the generated colour layer
[7]     common_*               <- core base.scss: --d-content-background: initial
[25]    common_theme_33_*      <- the theme's own common bundle
```

Two rules follow:

1. A variable core declares in `common` must be bridged from the theme's own
   common bundle — i.e. a partial in `stylesheets/`.
2. It must use `:root`. `stylesheets/base.scss` overrides its other variables on
   `html`, which is *lower* specificity than core's `:root` and loses even though
   it loads later.

`--d-content-background` is the only variable in the current bridge that hits
this. Verified on the live preview by inserting each candidate rule into the
real `common_theme_33` sheet:

| Rule inserted at the theme's cascade position | Computed value |
|---|---|
| *(nothing — as deployed)* | `""` |
| `html { --d-content-background: var(--fomio-card) }` | `""` — still dead |
| `:root { --d-content-background: var(--fomio-card) }` | `white` (light) / `#141414` (dark) |

The other seven bridged variables are re-declared only in `qunit-custom.scss`,
a test harness that is never served, so they resolve correctly from the colour
layer — confirmed live.

Deliberately **not** bridged:

| Not bridged | Why |
|---|---|
| `--primary`, `--secondary`, `--tertiary` | already identical to the fomio token by construction |
| `--d-hover`, `--d-selected` | come from the `hover` / `selected` scheme slots, set deliberately per mode in `packages/design-tokens/web.js` (`WEB_DARK_SELECTION`) and admin-editable |
| `--primary-*-rgb` companions | used almost only by admin styles, which stay Discourse-native |

### 4. `common.scss` split into partials — done

`common/common.scss` is now a **38-line import manifest with no rules**. The
27,789 lines moved to 27 partials in `apps/web/stylesheets/`, which Discourse
adds to the Sass load path.

Largest single file: **27,851 → 7,870** (`stylesheets/sidebar.scss`).

Manifest order is cascade order. Add a partial where its rules should apply;
never re-sort the list alphabetically.

## How this was verified

No live Discourse was available, so correctness was established by compiling the
theme the way Discourse does and diffing the output. This harness is worth
rebuilding for any future change to this layer.

1. Build the prelude Discourse prepends: every scheme slot as a `$var`, then
   `@import "common/foundation/variables"` and `"…/mixins"`.
2. Compile each of `color_definitions` / `common` / `desktop` / `mobile` against
   **both** schemes from `about.json` — 8 combinations.
3. Pass the same two Sass load paths Discourse does, including `stylesheets/`.
4. Diff the compiled CSS against the same build from `HEAD`.

Results:

- 8/8 scheme × target combinations compile
- steps 1–3: 76 changed CSS lines in `common`, **0 in `desktop` and `mobile`**,
  every change intended
- step 4: compiled CSS **byte-identical** (`cmp`) in both schemes, all three
  entrypoints — the split provably cannot have altered rendering
- `npm run tokens:check` green · token tests 14/14 · theme tests 120/120

### Visual QA on the deployed preview

Run against `https://meta.fomio.app/?preview_theme_id=33`. Passed: light and
AMOLED dark home feeds; desktop sidebar and mobile bottom nav; topic/article
layouts; dark composer; mobile dark search overlay; card, border, shadow,
metadata and active-state contrast; widths 375/640/767/768/820/1024/1440 with no
horizontal overflow; light/dark persistence across navigation.

**One defect found — `--d-content-background` bridge was ineffective.** Its
computed value was empty in both schemes, so core surfaces that read it (search
results, user pages, directory, groups, badges, messages) did not inherit the
Fomio card colour. Cause and fix are in "Where a bridge declaration must live"
above. The other seven bridge declarations resolved correctly.

This is the class of bug the offline harness cannot catch: it compiles and
diffs *one stylesheet at a time*, so it cannot see a later bundle overwriting an
earlier one. **Any change to the core bridge needs a preview check**, not just a
green compile.

## What is left

All remaining work needs a running Discourse instance for visual QA. Static
analysis cannot prove these safe.

| Work | Size | Blocked on |
|---|---|---|
| Fold the last 23 `html.fomio-color-dark` blocks | sidebar, composer, search, bottom-bar chrome | each encodes a dark-only *composition*, not just a value — needs a design call on its light equivalent |
| Delete the override layer | 523 `!important` | proving an override redundant requires seeing what core renders for that element |
| Replace `display: none` suppression | 138 of the 523 | wants outlets / theme modifiers, the Horizon approach, not CSS suppression |
| Delete `fomio-color-mode.gjs` | 1 file | only once the last dark block is gone |

### Correction to an earlier estimate

The core bridge was scoped on the assumption it would let us delete ~115 of the
523 `!important`. That was wrong. The colour-property `!important` rules are
overwhelmingly `background: transparent !important` (21×) — they *strip* core
chrome rather than recolour it, and a colour bridge does not make them
deletable. Only 8 single-property colour overrides on core selectors use a
bridged token, and none are provably redundant without a live instance.

The bridge's value is forward-looking — un-overridden core chrome now matches
the theme, and new work inherits the palette — not retroactive deletion.

## Rules for new code

- **Never hand-edit `common/color_definitions.scss`.** It is generated; edit
  `scripts/generate-web-colors.js` and run `npm run tokens:fix`.
- **Never add an `html.fomio-color-dark` block.** Anything whose value differs
  light↔dark is a `dark-light-choose()` token in `color_definitions.scss`.
  Discourse recompiles that file per scheme, so it flips with no JavaScript.
- **Never hard-code a hex** that a scheme slot can express. Prefer
  `blend-two-colors($primary, $secondary, …)` or `rgba($primary, …)`.
- **Before overriding a core component**, check whether bridging a core variable
  in `color_definitions.scss` does the job for every component at once.
- **When adding a bridge, check where core declares that variable.** If it is
  declared outside `color_definitions.scss` — anywhere in the `common` bundle —
  bridge it from a `stylesheets/` partial under `:root` instead, and confirm the
  computed value in a preview. A dead bridge fails silently.
- **Rules go in `stylesheets/<feature>.scss`**, never in the `common.scss`
  manifest. See [responsive-design.md](./responsive-design.md) §9 for which file
  owns what.

## Not yet started

Opportunities identified during the audit but out of scope so far:

- **Fonts** — `common/head_tag.html` hard-codes a Google Fonts CDN link.
  Discourse self-hosts fonts and exposes `--font-family` / `--heading-font-family`
  from the `base_font` / `heading_font` site settings.
- **`settings.yml` has one setting.** Brand knobs, radii and max-widths are baked
  into SCSS, so every tweak needs a git push. Theme settings support
  `color`/`bool`/`enum`/`list`/`upload`, are admin-editable live, and reach SCSS
  as `$name`.
- **`about.json` `modifiers` is empty.** Horizon uses `svg_icons`,
  `serialize_topic_is_hot`, and a setting-bound `serialize_topic_excerpts`.
- **Breakpoints are hard-coded** at 480/640/767/768/820/860/900/1099px. Core
  ships `@mixin breakpoint`.
