# fomio web screen pack

Responsive mockups for the fomio Discourse theme. Open `00 Index.dc.html`. Each screen file is a canvas of named artboards (1a, 1b…) with a light/AMOLED switch in Tweaks. All content is sample data.

| File | Artboards |
|---|---|
| 01 Home | 1a desktop signed in · 1b desktop signed out · 1c tablet, Tracked on · 1d mobile signed in · 1e mobile signed out · 1f mobile AMOLED, Hot · 1g feed states |
| 02 Categories | 2a desktop · 2b mobile signed out |
| 03 Category | 3a parent category · 3b subcategory · 3c mobile signed out · 3d notification-level sheet |
| 04 Topic | 4a desktop with timeline · 4b mobile top of topic · 4c mobile signed out, login prompt |
| 05 Search | 5a desktop · 5b mobile |
| 06 Composer | v4 (awaiting approval): section index, IA/state axes, named frames for tablets, links, quotes, drafts, permissions, advanced, completion, guided form, uploads, accessibility; coverage table. Prototype `06.1 Composer Prototype`. Handoff `06 Composer handoff.md`. Earlier: `06 Composer v3`/`v2`/`v1` with matching prototypes and handoffs |
| 07 Profile | 7a desktop · 7b mobile |

Shared parts (child components): `FmHeader`, `FmBottomNav`, `FmTopicCard`, `FmPost`, `FmCategoryHeader`, `FmComposer4` (v4 composer frame + `fmc4-lib.js` fixtures; imports `FmHeader` and `FmBottomNav`; props `viewport` phone/narrow/splitNarrow/split600/tabletP/tabletL/desktop, `hwkb`, `zoom`, `reducedMotion`, `scheme`, `preset`, `rtl`, `live`, `sim`, `cmd`), `FmComposer3` (v3 composer frame; props `viewport` phone/narrow/desktop, `scheme`, `preset`, `rtl`, `live`, `sim`), `FmComposer` (v2 composer frame with local simulations; props `viewport`, `scheme`, `frame`, `alt`, `keyboard`, `offline`, `failUpload`, `failLink`, `outcome`).

## Design rules
- **Discourse first.** Stock routes, permissions, topic stream, composer fields and serialized data only. If Discourse doesn't provide a number, it isn't shown.
- **Structure.** Global header → context header (category, topic, user) → local nav (nav pills / horizontal-overflow-nav) → content. No sidebar.
- **Header.** Desktop/tablet: logo, search field, notifications and avatar (signed in) or Sign Up + Log In (signed out). Mobile: logo and search only.
- **Mobile bottom bar.** Home, Categories, New Topic, Notifications, Profile. Signed out: Home, Categories. The bar is 56px plus the home-indicator safe area (34px here, `env(safe-area-inset-bottom)` in production). The active item is violet; the Profile avatar gets a ring. No item is active on pages that aren't one of the five (another member's profile).
- **Density, not architecture.** Breakpoints change padding, type size and thumbnail size. Nav pills collapse into a dropdown on mobile, as in core.
- **One column.** Content, header contents and the context header all align to an 840px column. Topic posts run at 690px, with the timeline in the remaining width.
- **Cards.** Category path, author and age, title, 2-line excerpt, optional topic thumbnail on the right, then first-post likes, reply count, bookmark and share. New topics get a violet dot; topics with new replies get a count badge; read topics get a muted title.
- **Terminology belongs to Discourse.** The live site's site-text overrides stay exactly as they are. Theme code never hardcodes visible labels and never adds theme-local replacements (no theme `locales/` strings for core labels). Every label is rendered through the existing core i18n key, e.g. `i18n("topic.create")`, so whatever the site override says is what renders.
- **Colour and type.** Unchanged from the system: ink on white, AMOLED black, one violet (`tertiary`), Source Sans 3 for UI and body (preview name of Source Sans Pro; the Discourse base_font setting is Source Sans Pro), Roboto Slab for titles. Weights 400/700 only. Category colour appears only as small squares and bars.
- **States.** Hover uses the `hover` wash or a darker border. Focus is a 2px violet ring with a 2px gap. Disabled is 50% opacity. Errors are text with a next step.

## Label fixtures
Visible labels in the mockups are **preview fixtures**: they show what the live site renders, not strings the theme owns. Elements whose wording depends on the site carry `data-fixture="…"`. Each screen header has a "Fixture" note.

| Shown in mockups | Source | Status |
|---|---|---|
| New Byte (New Topic action: nav row, category header, bottom bar) | core `topic.create`, site-text override | **Confirmed** rendered wording |
| Home, Categories, Notifications, Profile (bottom bar) | core strings used by the bottom bar | Core default shown; override not known |
| Latest, Hot, New, Unread, Top, Categories (nav pills) | core `filters.*.title` | Core default shown; override not known |
| Tracked | core tracked-filter string | Fixture; key to confirm (see Unresolved 1) |
| Default scope (unfiltered) | — | Deliberately unlabeled |
| Create a new Topic, Create Topic, category…, optional tags, Type title, or paste a link here | core `composer.*` / `topic.create_long` | Core default shown; likely overridden (Byte wording); confirm |
| Watching, Tracking, Watching First Post, Normal, Muted, and their descriptions | core `topic.notifications.*` / category notification strings | Core default shown |
| Reply, Bookmark, Share, Sign Up, Log In, Message, Search, Relevance, Advanced filters, Topics/Posts, Categories/Tags, Users, Summary, Activity, Badges | core | Core default shown |
| Welcome to fomio + subheader, category names/descriptions, topic content | site content (admin / users) | Sample content |
| "Sign up or log in to like, bookmark and reply…", "Log in to join the discussion." + subtext, "Showing topics in categories and tags you track or watch…", "Nothing tracked yet.", "Couldn't load topics." | not core strings | Mockup annotations. Before shipping, map each to an existing core key or drop it; don't add theme strings. |
| Composer labels (06, 06.1) | observed per-control wording 2026-09-28 + core defaults | See `06 Composer handoff.md` §6 for observed, core and proposed (Photo / Format / More etc.) labels. |
| Older component docs examples ("Create byte", "Choose a teret", "Delete this byte?", "No bytes yet.") | written before this rule | Unverified example copy, not confirmed overrides. Replace with fixtures when those components are next touched. |

## Token refinements
- Content column 760 → **840px**, so the nav row (pills + Tracked + New Topic) fits on one line at desktop.
- Topic thumbnail: full-width 16:9 → **right-hand 3:2 thumbnail** (168×112 desktop, 84×84 mobile). This keeps the feed dense and scannable.
- Header search field radius 999px → **8px**, to match the rest of the system.

## Unresolved choices
1. **Tracked filter label and default scope.** Tracked is a single on/off filter on the nav row. It is signed-in only and appends `?f=tracked` to the current list. The project doesn't establish a core string for the unfiltered scope, so the default is **left unlabeled** (the filter is simply off). The earlier "Everything" label has been removed. The "Tracked" label is also a fixture until the core key it renders from is confirmed.
2. **Signed-out mobile Log In.** The mobile header is meant to be logo + search, but signed-out users need a way in. This pack keeps a small Log In in the header. The alternative is a third bar item.
3. **Topic map views.** Views are native but left out, in line with the no view-count social proof rule. Add them back if you want core parity.
4. **Categories page style.** The pack uses "categories and latest topics". Boxes-style is the other native option.
5. **Card layout.** Core renders the topic list as a table. The card layout still needs a small layout stylesheet (Horizon-style); everything else is settings and variables.
6. **Tablet.** Tablet uses the desktop layout and the pill row wraps. Check at 768px if top_menu has more items than shown here.
7. **Images.** Thumbnails and post images are placeholders. Real images come from user uploads.
