# Mobile web navigation — Phase 4 studio checklist

Use before release or after major touch-shell changes. Aligns with `docs/50-studio/` (mobile adaptations in `studio.mdc`).

## Design system (Pass 1)

- [ ] Touch chrome uses Fomio tokens only (`--fomio-*`, `--d-*` where required).
- [ ] Terminology: Hub, Teret, Byte, Saved, Reply — no forbidden synonyms in `locales/en.yml`.
- [ ] Bottom bar: five tabs only; central Create is visually primary.
- [ ] Context pills read as **local mode**, not global nav.

## Frontend boundary (Pass 2)

- [ ] Connectors are `.gjs`; outlets verified for this Discourse version (`below-site-header`, etc.).
- [ ] No `fetch` in theme JS for product data.
- [ ] Path helpers centralized in `lib/fomio-mobile-nav-paths.js` where shared.

## Product / quality (Pass 3)

- [ ] **States:** logged-in vs logged-out for Saved / Me / Create; auth pages show no Fomio dock.
- [ ] **Accessibility:** `aria-label` on `nav.fomio-bottom-bar`; sheet uses `role="dialog"`, `aria-modal`, closed when unmounted; Escape closes sheet.
- [ ] **Motion:** `prefers-reduced-motion` respected for sheet animation.
- [ ] **Safe area:** `env(safe-area-inset-*)` on dock and sheet.
- [ ] **No horizontal scroll** on typical topic with images at touch widths.
- [ ] **Desktop / rail / expanded:** unchanged; non-touch surfaces share the same Master Pane overlay model, with sidebar width as the only surface difference.

## Verdict

Record: `PASS` | `CONDITIONAL PASS` | `FAIL` with owner and date.

---

## Manual smoke (touch)

1. Home → pills switch Latest / Hot / Following / New.
2. Discover → Hubs + Trending + overflow sheet opens/closes.
3. Create → composer (logged-in) or login intent (logged-out).
4. Saved → bookmarks or intent.
5. Me → summary; Me hub rows navigate to profile, activity, bookmarks, preferences, messages.
6. Topic page: readable title/body; bottom dock does not cover last reply control.
