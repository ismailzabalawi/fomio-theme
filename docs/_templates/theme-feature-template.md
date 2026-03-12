# Theme Feature: [Feature Name]

**Status:** Draft
**Owner:** UI/UX | Frontend
**Last updated:** YYYY-MM-DD
**Surface:** web-beta → web

---

## 1. Problem / Goal

[One paragraph. What user experience gap does this theme change address? How does it serve the goal of bridging web readers to the Fomio mobile app?]

**Success criteria:**
1. [Measurable outcome]
2. [Measurable outcome]

**Non-goals:**
- [What this change explicitly does NOT do]

---

## 2. Discourse API / Data Available

> Use `discourse-archeologist` skill if needed: `/trace <feature>` or `/serialize <endpoint>`

- **What data is already on the page:** [Discourse model data available without extra requests]
- **Value transformers available:** [check with `rg 'applyValueTransformer' discourse/app -l`]
- **Outlets available:** [verify with `rg '<PluginOutlet @name="outlet-name"' discourse/app`]
- **No fetch calls allowed** — if data isn't available on the page, this feature may not be feasible as a theme

---

## 3. Implementation Approach

Priority order (use the highest level that works):

- [ ] **Value transformer** — modify existing Discourse data before render (no new markup)
- [ ] **Connector at outlet** — inject GJS component at a `<PluginOutlet>`
- [ ] **`onPageChange`** — react to client-side navigation (last resort for page-level orchestration)
- [ ] **DOM manipulation** — absolute last resort; document the reason here

**Chosen approach:** [transformer | connector | onPageChange | DOM]

**Reason:** [Why this level and not a higher one]

---

## 4. Files to Create / Modify

### Beta (all work lands here first)

- [ ] `apps/web-beta/javascripts/discourse/connectors/<outlet>/fomio-<name>.gjs` — connector component
- [ ] `apps/web-beta/javascripts/discourse/api-initializers/<name>.gjs` — initializer (if new entry point needed)
- [ ] `apps/web-beta/javascripts/discourse/components/Fomio<Name>.gjs` — reusable GJS component (if shared)
- [ ] `apps/web-beta/common/common.scss` — token updates or new styles
- [ ] `apps/web-beta/settings.yml` — new `fomio_*` settings (if needed)
- [ ] `apps/web-beta/locales/en.yml` — new strings via `themePrefix()` (if user-facing copy)

### Stable (promoted after critique passes)

- [ ] Same files mirrored to `apps/web/`

---

## 5. Design System

- [ ] Uses existing `--fomio-*` tokens only → no DS work needed
- [ ] New visual treatment needed → DSP for new token(s) (use `fomio-ds` skill: `/token`)
- [ ] New reusable GJS component needed → full DSP required (`/dsp` in `fomio-ds` skill)

**Tokens used:** [list `--fomio-*` or `--d-*` variables]

**fomio- CSS classes:** [list any new classes added, prefixed with `fomio-`]

---

## 6. Studio Critique

Run before promoting to stable. See `.cursor/rules/studio.mdc` — Web Theme Adaptations.

- [ ] **Pass 1 — Experience Architect:** Product language, terminology compliance, visual coherence with mobile, token usage, hierarchy
- [ ] **Pass 2 — Frontend Engineer:** GJS correctness, outlet/transformer verification in discourse/ source, `fomio-` CSS scoping, no fetch, no hardcoded deep links, settings via `virtual:theme`
- [ ] **Pass 3 — Product Engineer:** Mobile browser behavior, graceful degradation (no JS), desktop/mobile SCSS split, no forbidden terminology in locales

**Verdict:** PASS | CONDITIONAL PASS | FAIL

---

## 7. Verification Commands

```bash
# Check outlets exist
rg '<PluginOutlet @name="<outlet-name>"' discourse/app

# Check transformers exist
rg 'applyValueTransformer.*"<key>"' discourse/app

# Terminology check
node apps/mobile/scripts/check-terminology.js

# Token sync check
node apps/mobile/scripts/check-token-sync.js
```

---

## 8. Promotion Checklist (web-beta → web)

- [ ] Studio critique passed (all 3 passes)
- [ ] Quality audit passed (all 6 passes) — see `docs/50-studio/quality-audit.md`
- [ ] Terminology check clean
- [ ] Token sync check clean
- [ ] Tested in Discourse desktop preview
- [ ] Tested in Discourse mobile browser preview
- [ ] Files mirrored to `apps/web/` with identical structure
- [ ] `apps/web/docs/README.md` updated if new pattern documented

---

## 9. Definition of Done

- [ ] All 3 critique passes passed
- [ ] Verified in desktop + mobile Discourse views
- [ ] No forbidden terminology in locales or component copy
- [ ] All CSS scoped under `fomio-` prefix
- [ ] No fetch calls in theme JS
- [ ] Promoted to `apps/web/`
