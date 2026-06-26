# DSP-002: Moderation Review Surface

**Type:** Pattern + Component (Layer 2 — Content)
**Proposer:** Experience Architect + Product Engineer
**Date:** 2026-06-26
**Status:** Proposed

---

## Gap

The six-state matrix requires a **moderation** state defined for any critical flow where content may be flagged, hidden, or pending review. The design philosophy is explicit: *"Separate everyday actions from management actions. Preserve evidence/context before enabling irreversible decisions."*

No canonical pattern or shared component exists for this state in the web theme. Without one:

- Individual features that surface moderation controls will build them ad-hoc with different visual treatments, different action hierarchies, and different levels of confirmation before destructive actions.
- The most likely failure mode — surfaced by the AI anti-pattern rubric in the design philosophy — is exposing all moderation actions simultaneously in a single row: `[Approve] [Reject] [Delete] [Ban] [Warn] [Shadowban] [Archive] [Escalate]`.
- This violates the "one primary action per region" principle and the "progressive disclosure over action glut" principle.
- Without a confirmation gate before irreversible actions (Ban, Archive, Delete), moderators risk accidental destructive operations.

Specific flows that require this pattern:
1. A flagged Byte shown to a moderator in the feed or Byte view.
2. A moderation queue or review list.
3. Any in-context inline flag resolution surface.

---

## Proposal

A **two-part pattern**: an in-context moderation bar as a new shared component, and a review surface composed from existing Layer 3 components.

### Part 1: `fomio-moderation-bar` (new component)

**Layer 2 (Content)** — the contextual in-context indicator and primary action trigger. Display-only aside from the Review trigger.

```
components/shared/fomio-moderation-bar.gjs
```

**What it shows:**
```
[Status badge]  [Reason summary]              [Review →]
```

- A `fomio-badge` showing the moderation status (`"Pending review"`, `"Flagged"`, `"Hidden"`, `"Approved"`).
- A short reason summary (the flag reason or current status note).
- A single `fomio-button @variant="secondary"` labelled "Review" that opens the review surface.

**Props:**

| Prop | Type | Required | Description |
|---|---|---|---|
| `@status` | string | yes | Moderation status label. E.g., `"Flagged"`, `"Pending review"`, `"Hidden"`. |
| `@statusTone` | string | no | Badge tone: `"warning"`, `"danger"`, `"success"`, `"info"`. Defaults to `"warning"`. |
| `@reason` | string | no | Short reason summary. E.g., `"Reported for spam by 2 members."` |
| `@onReview` | function | yes | Opens the review surface. |
| `@reviewLabel` | string | no | CTA label. Defaults to `"Review"`. |

**Template structure:**

```glimmer
<template>
  {{! Moderation bar: in-context status + single Review trigger for moderators.
      Shown only to moderators. All management actions live inside the review surface,
      never on this bar. }}

  <div class="fomio-moderation-bar" role="note" ...attributes>
    <div class="fomio-moderation-bar__status">
      <FomioBadge @label={{@status}} @tone={{this.tone}} />
      {{#if @reason}}
        <span class="fomio-moderation-bar__reason">{{@reason}}</span>
      {{/if}}
    </div>

    <FomioButton
      @variant="secondary"
      @size="sm"
      @onClick={{@onReview}}
    >
      {{this.reviewLabel}}
    </FomioButton>
  </div>
</template>
```

**SCSS — `.fomio-moderation-bar`:**

```scss
// common.scss — Section 2 (Layer 2 Content)

.fomio-moderation-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem;
  padding: 0.5rem 0.75rem;
  background: color-mix(in srgb, var(--fomio-warning, #f5a623) 8%, transparent);
  border: 1px solid color-mix(in srgb, var(--fomio-warning, #f5a623) 25%, transparent);
  border-radius: var(--fomio-radius);
}

.fomio-moderation-bar__status {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  min-width: 0;
}

.fomio-moderation-bar__reason {
  font-size: 0.8125rem;
  color: var(--fomio-text-muted);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

html.fomio-color-dark .fomio-moderation-bar {
  background: color-mix(in srgb, var(--fomio-warning, #f5a623) 6%, transparent);
  border-color: color-mix(in srgb, var(--fomio-warning, #f5a623) 18%, transparent);
}
```

**Rendering rule:** Feature components must gate `<FomioModerationBar>` on `@currentUser.moderator` (or `@currentUser.canModerate`, whichever Discourse exposes). The component itself does not perform permission checks — the feature component owns that.

---

### Part 2: Moderation Review Surface (composition pattern)

Triggered by `@onReview`. Composed from **existing Layer 3 components** — no new Layer 3 component needed.

**On touch surfaces:** Open `fomio-ephemeral-sheet`
**On desktop surfaces:** Open `fomio-modal`

**Review surface structure:**

```
┌─────────────────────────────────────────────────┐
│ Review: [Content title or excerpt]              │
├─────────────────────────────────────────────────┤
│                                                 │
│  [Content preview — full, read-only]            │
│                                                 │
│  Flag details:                                  │
│  • Reported by: 2 members                       │
│  • Reason: Spam                                 │
│  • Reported at: Jun 24, 2026 14:02              │
│                                                 │
├─────────────────────────────────────────────────┤
│  [Approve]    [Reject]        [···] overflow    │
└─────────────────────────────────────────────────┘
```

**Action hierarchy inside the review surface:**

| Position | Action | Component |
|---|---|---|
| Primary | Approve | `FomioButton @variant="primary"` |
| Secondary | Reject | `FomioButton @variant="danger"` |
| Overflow menu | Warn, Archive, Escalate | `FomioDropdown` items |
| Overflow menu (destructive) | Ban | `FomioDropdown` item + confirmation |

**Confirmation gate for irreversible actions:**

Ban and Archive must open a `fomio-popover` (or an inline confirm step within the review surface) before executing. The confirmation must:
1. Name the action explicitly: *"This will permanently ban [username]."*
2. State what it cannot be undone: *"This cannot be undone from this interface."*
3. Require an explicit confirmation click: "Confirm Ban" (danger variant) + "Cancel".

```glimmer
{{! Pattern for destructive confirmation inside review surface }}
<FomioPopover
  @title="Confirm ban"
  @body="This will ban @username from Fomio. Contact an admin to reverse."
  @confirmLabel="Confirm ban"
  @confirmVariant="danger"
  @onConfirm={{this.executeBan}}
  @cancelLabel="Cancel"
>
  <:trigger>
    <FomioButton @variant="ghost" @size="sm">Ban</FomioButton>
  </:trigger>
</FomioPopover>
```

**Content preservation rule:**
The review surface must always show the full content being reviewed before any action is available. Moderators must read-then-decide, not decide-without-reading. The actions section is always below the content preview, not above.

---

## Alternatives Considered

**Single inline row with all actions**
Rejected. This is the exact anti-pattern documented in the design philosophy: `[Approve] [Reject] [Delete] [Ban] [Warn] [Shadowban] [Archive] [Escalate]` all visible at once. It violates the one-primary-action rule, raises cognitive load, and creates conditions for accidental destructive actions without the user having reviewed the content in context.

**Extend `fomio-notice` with action buttons**
Rejected. `fomio-notice` is for system status (info/warning/danger announcements). A moderation bar is a moderator-specific management surface with a distinct semantic role. Reusing notice would contaminate its semantic meaning and produce a visually wrong weight — notice bars should not carry management actions.

**Extend `fomio-empty-state`**
Rejected. Empty-state is for no-data conditions. A flagged piece of content is not an empty state — it has content that requires review.

**Discourse's native flag moderation**
Considered as a baseline. Discourse provides moderation controls but they are styled as Discourse UI, not Fomio UI. The web theme must present a Fomio-branded moderation surface consistent with the rest of the product experience. Native Discourse controls may back the actual API calls, but the surface is owned by the theme.

**One combined component for bar + review surface**
Rejected. The bar and the review surface have different lifecycles (bar is always mounted when content is visible; review surface is mounted on demand), different layout contexts (bar is inline with content; review surface is a sheet/modal), and different accessibility roles. Combining them would create a stateful component that violates the display-only shared component rule.

---

## System Impact

| File | Change |
|---|---|
| `components/shared/fomio-moderation-bar.gjs` | **New file** |
| `common/common.scss` | Add `.fomio-moderation-bar` styles in Section 2 |
| `CLAUDE.md` | Add `fomio-moderation-bar.gjs` to Layer 2 list |
| `docs/component-checklist.md` | Note this covers the Moderation state in the state matrix |
| `docs/design-philosophy.md` | Cross-reference DSP-002 in the Moderation state row |

No existing components change. The review surface uses existing `fomio-ephemeral-sheet`, `fomio-modal`, `fomio-button`, `fomio-dropdown`, `fomio-popover`, and `fomio-badge` — no new Layer 3 components needed.

**Discourse API dependency:** The feature component using this pattern will need to call Discourse moderation endpoints (approve post, reject post, warn user, etc.) via the theme's `ajax()` helper. Those calls happen in the feature component, not in the shared components.

---

## Implementation

### Step 1: Create `fomio-moderation-bar.gjs`

```
javascripts/discourse/components/shared/fomio-moderation-bar.gjs
```

Implements the template from the Proposal section. Composes `FomioBadge` and `FomioButton`. Display-only aside from forwarding `@onReview`.

### Step 2: Add styles to `common.scss`

Add `.fomio-moderation-bar` and `.fomio-moderation-bar__*` styles in Section 2 (Layer 2 Content), after `.fomio-permission-notice` if DSP-001 has shipped.

### Step 3: Update `CLAUDE.md`

Add to the Layer 2 component list:
```
- `fomio-moderation-bar.gjs` — Moderator-only status + Review trigger for flagged/pending content
```

### Step 4: First feature adoption (reference implementation)

When the first feature component uses this pattern (e.g., inline moderation on the Byte view for moderators), that implementation becomes the canonical reference for the review surface composition. Document it in `docs/shared-component-development.md` under a new "Moderation Surface" example section.

---

## Rollout

**Non-breaking.** New component only; no existing components changed.

**Adoption rule:**
- Required for any new feature that surfaces flagged, pending, or hidden content to moderators.
- The review surface is a composition pattern — feature components implement it using existing Layer 3 components. There is no single "review surface" component to import.
- Feature components must gate `<FomioModerationBar>` on the appropriate Discourse moderator permission check.

**Open question before implementation:**
Which Discourse permission property to gate on — `currentUser.moderator`, `currentUser.staff`, or a more granular trust-level check — should be confirmed via `discourse-archeologist /trace` on the Discourse moderation API before implementing the first feature that uses this pattern.
