# DSP-001: Permission State Pattern

**Type:** Pattern + Component (Layer 2 — Content)
**Proposer:** Experience Architect
**Date:** 2026-06-26
**Status:** Proposed

---

## Gap

The six-state matrix now required for all critical flows includes a **permission** state — when a user cannot perform an action due to their role, ownership, or access level. No canonical pattern or shared component exists for this state.

Current behavior across the theme is inconsistent:
- Some screens hide the restricted action entirely, giving users no signal that the action exists.
- Some screens show a disabled `<button>` with no explanation, which reads as a broken UI rather than a permission boundary.
- Some screens show nothing, leaving users to infer that posting, editing, or moderating isn't possible.

The design philosophy requires: *"Show unavailable actions with explanation when the user can benefit from understanding the constraint; otherwise hide them entirely."* Right now "otherwise hide" is the only implemented behavior, applied universally — even where an explanation would help.

Specific flows that expose this gap:
1. A non-author viewing a Byte — the Edit action should appear with a muted explanation, not silently disappear.
2. A standard user in a member-only Teret — the Reply action should explain the requirement rather than vanish.
3. A non-moderator viewing flagged content — the Review action should be hidden entirely (no explanation needed; the user can't act on it).

---

## Proposal

**Two behaviors, one decision rule: can the user do something about this constraint?**

| Situation | Behavior |
|---|---|
| Constraint is learnable or temporary (wrong role, not author, upgrade available) | Show the restricted action in a locked state with inline explanation |
| Constraint is permanent or explaining would confuse (feature disabled, system-level restriction) | Hide the action entirely — no component needed |

### New component: `fomio-permission-notice`

**Layer 2 (Content)** — display-only, no interactive behavior managed internally.

```
components/shared/fomio-permission-notice.gjs
```

**Props:**

| Prop | Type | Required | Description |
|---|---|---|---|
| `@reason` | string | yes | Plain-language explanation. E.g., "Only the author can edit this Byte." |
| `@icon` | string | no | Icon key from `fomio-ph-icon`. Defaults to `"lock"`. Pass `false` to suppress. |
| `@label` | string | no | Optional CTA label. E.g., "Learn more" or "Request access". |
| `@onAction` | function | no | Handler for the optional CTA. Only rendered when `@label` is also set. |

**Template structure:**

```glimmer
<template>
  {{! Permission notice: inline explanation for a locked or restricted action.
      Use when the constraint is learnable. Hide the action entirely when it is not. }}

  <div class="fomio-permission-notice" role="note" ...attributes>
    {{#if this.showIcon}}
      <span class="fomio-permission-notice__icon" aria-hidden="true">
        <FomioPhIcon @icon={{this.iconName}} />
      </span>
    {{/if}}

    <span class="fomio-permission-notice__reason">{{@reason}}</span>

    {{#if (and @label @onAction)}}
      <button
        type="button"
        class="fomio-permission-notice__action"
        {{on "click" @onAction}}
      >
        {{@label}}
      </button>
    {{/if}}
  </div>
</template>
```

**Usage pattern:**

```glimmer
{{! Feature component — parent owns the permission check }}
{{#if this.canEdit}}
  <FomioButton @variant="ghost" @onClick={{this.edit}}>Edit</FomioButton>
{{else if this.showEditReason}}
  <FomioPermissionNotice
    @reason="Only the author can edit this Byte."
    @icon="pencil-slash"
  />
{{/if}}
```

**SCSS — `.fomio-permission-notice`:**

```scss
// common.scss — Section 2 (Layer 2 Content)

.fomio-permission-notice {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  color: var(--fomio-text-muted);
  font-size: 0.8125rem;

  // role="note" — supplementary, not an alert
  // No alert role; contrast requirements are for text, not the container
}

.fomio-permission-notice__icon {
  width: 0.875rem;
  height: 0.875rem;
  flex-shrink: 0;
  opacity: 0.6;
}

.fomio-permission-notice__reason {
  // inherits color from parent
}

.fomio-permission-notice__action {
  background: none;
  border: none;
  padding: 0;
  color: var(--fomio-primary);
  font-size: inherit;
  cursor: pointer;
  text-decoration: underline;
  text-underline-offset: 2px;

  &:focus-visible {
    outline: 2px solid var(--fomio-primary);
    outline-offset: 2px;
    border-radius: 2px;
  }
}

html.fomio-color-dark .fomio-permission-notice {
  color: var(--fomio-text-muted);
}
```

**Accessibility contract:**
- `role="note"` — supplementary content. Not `role="alert"` (not urgent) or `role="status"` (not a live update).
- Icon is `aria-hidden="true"` — the reason text carries the meaning.
- CTA button is a real `<button>` — keyboard-operable and announced to screen readers.
- Reason text must meet 4.5:1 contrast against its background even at muted opacity.

---

## Alternatives Considered

**Use `fomio-notice` with `@tone="info"`**
Rejected. `fomio-notice` is for system-status messages that flow with content as an announcement (info, success, warning, danger). A permission explanation is a supplement to a specific absent action — different semantic role (`note` vs `status`/`alert`), different visual weight (should be quieter and inline, not a full notice bar), and different placement (immediately where the action would have been).

**Use `aria-disabled` on the button with a tooltip**
Rejected. Tooltip text is not persistently visible — keyboard users and screen reader users may never encounter it. The reason must be rendered as persistent text adjacent to the locked location, not on-hover only.

**Use `fomio-empty-state`**
Rejected. Empty-state is a full-region no-data component with an illustration, title, body, and action. A permission notice is an inline, single-line explanation. Using empty-state for a locked action would over-weight the explanation and break spatial coherence.

**Hardcode per-feature explanations in each feature component**
Rejected. Without a shared component, each team member implements slightly different visual treatments, accessibility semantics, and copy patterns. The point of the state matrix is consistent, reviewable behavior — that requires a shared component.

---

## System Impact

| File | Change |
|---|---|
| `components/shared/fomio-permission-notice.gjs` | **New file** |
| `common/common.scss` | Add `.fomio-permission-notice` styles in Section 2 |
| `CLAUDE.md` | Add `fomio-permission-notice.gjs` to Layer 2 list |
| `docs/component-checklist.md` | Note this component covers the Permissions state in the state matrix |

No existing components change. No token additions needed — uses `--fomio-text-muted` and `--fomio-primary`, which already exist.

---

## Implementation

1. Create `javascripts/discourse/components/shared/fomio-permission-notice.gjs` following the template above.
2. Add `.fomio-permission-notice` styles in `common/common.scss` Section 2 (after `.fomio-empty-state` block).
3. Update `CLAUDE.md` Layer 2 component list.
4. Update `docs/component-checklist.md` to reference this component for the Permissions state row.

The component requires no new tokens and no changes to `fomio-ui-components.gjs` (display-only; no interactive ARIA state).

---

## Rollout

**Non-breaking.** New component only; no existing components changed.

**Adoption rule:**
- Required for any new feature component where a restricted action would otherwise silently disappear and the reason is learnable.
- Optional migration for existing screens — prioritize high-traffic surfaces (Byte view, Teret composer) in a follow-up pass.
- Where the constraint is non-learnable, continue hiding the action outright. No component needed for that case.

**Decision guide for feature implementors:**

```
Does the user encounter this restriction during normal use?
  → Yes: Is there something they can do about it (role change, upgrade, request)?
      → Yes: use fomio-permission-notice with @reason and optionally @label + @onAction
      → No: show the notice without @label (reason only)
  → No (system-level, permanent, or irrelevant to the user): hide the action entirely
```
