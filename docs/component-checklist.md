# Shared Component Development Checklist

Use this checklist when building or updating shared components.

## Before Starting

- [ ] Check `docs/phase-1-shared-components-audit.md` — does this component already exist?
- [ ] Is this a reusable component (used or potentially used across multiple features)?
- [ ] Does it fit into Layer 1 (Controls), Layer 2 (Content), or Layer 3 (Interaction)?
- [ ] Or is it a feature composition (product-specific logic)?

## Component Structure

- [ ] File in `javascripts/discourse/components/shared/` named `fomio-*.gjs`
- [ ] One-line comment at top describing the component's role
- [ ] Use `.fomio-componentname` class on root element
- [ ] Spread `...attributes` on root element
- [ ] No business logic — display and event forwarding only

## Props & API

- [ ] Props use semantic names: `@variant`, `@size`, `@disabled`, `@loading`, `@label`, `@hint`, `@error`
- [ ] Event handlers named consistently: `@onClick`, `@onChange`, `@onSelect`, `@onOpenChange`
- [ ] Props documented in a comment block or README
- [ ] No hardcoded strings — use `i18n()` for labels/placeholders

## Accessibility

- [ ] Uses semantic HTML elements (`<button>`, `<input>`, `<select>`, `<ul>/<li>`)
- [ ] ARIA attributes present: `aria-expanded`, `aria-selected`, `aria-checked`, `aria-disabled` (as needed)
- [ ] Keyboard navigation works (Tab, Arrow keys, Escape, Enter)
- [ ] Tested with screen reader (NVDA, JAWS, VoiceOver)
- [ ] No hardcoded `aria-*` values — let `fomio-ui-components.gjs` manage interactive state

## Styling

Read `docs/responsive-design.md` before writing any styles. It is the authority on which file owns which styles and what patterns to use.

- [ ] All styles in `common/common.scss` (or `desktop/desktop.scss` / `mobile/mobile.scss` for refinements only)
- [ ] All class names prefixed with `fomio-`
- [ ] All colors use `--fomio-*` CSS variables, never hardcoded hex
- [ ] States use ARIA attributes, not `.is-*` or `.active` class names
- [ ] Hover states gated on `(hover: hover) and (pointer: fine)` — not applied to touch
- [ ] Interactive elements have `min-height: 44px` (WCAG 2.5.5 touch target)
- [ ] Dark mode support via `html.fomio-color-dark .fomio-componentname { ... }`
- [ ] Surface-mode variants use body class scoping, not raw media queries

Example structure:
```scss
.fomio-button {
  /* base styles — common.scss */
  min-height: 44px; /* WCAG touch target */
}

.fomio-button--variant {
  /* variant styles */
}

.fomio-button[aria-disabled="true"] {
  /* disabled state */
}

/* Hover — fine pointer only */
@media (hover: hover) and (pointer: fine) {
  .fomio-button:hover { ... }
}

/* Surface-mode adaptation */
body.fomio-surface-touch .fomio-button {
  /* touch shell overrides — common.scss, NOT mobile.scss */
}

/* Dark mode */
html.fomio-color-dark .fomio-button {
  /* dark mode overrides */
}
```

## Interactive Behavior (Layer 3)

- [ ] If this is an interactive component, confirm `fomio-ui-components.gjs` handles its behavior
- [ ] If new interaction needed, add to `fomio-ui-components.gjs` (NOT component-level JS)
- [ ] Behavior uses document-level event delegation, not component listeners
- [ ] ARIA state drives visual changes, not JS-managed class names

## Design Philosophy

Read `docs/design-philosophy.md` before designing or reviewing. Reject AI-generic patterns before they reach implementation.

- [ ] Content before chrome: component shows meaningful content/state before decoration
- [ ] One primary action per region: 1 persistent primary, 0–1 secondary, rest in overflow
- [ ] Lists before cards: component uses a list unless the subject genuinely needs grouping/containment
- [ ] No generic labels: any text in the component uses Fomio nouns/tasks, not SaaS defaults
- [ ] No decorative motion: any animation teaches state change, hierarchy, or spatial transition — or it's removed

### State Matrix (required for interactive components and every critical flow)

Before visual polish begins, all six states must be designed:

- [ ] **Empty** — explains why and what to do next; includes a next action if meaningful
- [ ] **Loading** — skeleton (known layout shape) / spinner (unknown duration) / progress (measurable)
- [ ] **Error** — states what failed, where, and what the user can do; always textual
- [ ] **Long content** — truncation rule defined; expand/collapse preserves focus position
- [ ] **Permissions** — unavailable actions explained when learnable (use `fomio-permission-notice`); hidden when not. See `docs/dsp-001-permission-state.md`
- [ ] **Moderation** — everyday actions separated from management; context preserved before irreversible decisions. Use `fomio-moderation-bar` + review surface composition. See `docs/dsp-002-moderation-surface.md`

### AI-Genericness Self-Check

- [ ] Card saturation ≤ 35% of major content regions on scan-heavy pages
- [ ] ≤ 2 persistent actions per list/feed item (3 → review; 4+ → reject)
- [ ] Top-level nav labels are Fomio-specific, not generic SaaS nouns
- [ ] No decorative gradients or glass effects on every surface
- [ ] Not a happy-path-only design — state matrix complete

## Responsive Design

Read `docs/responsive-design.md` before designing the component's adaptive behavior.

- [ ] Component base styles go in `common/common.scss`
- [ ] Touch-specific behavior (safe areas, overlay layout, bottom-sheet patterns) scoped to `body.fomio-surface-touch` in `common/common.scss` — NOT only in `mobile/mobile.scss`
- [ ] Rail-specific adaptations (icon-only, label tooltips) scoped to `body.fomio-surface-rail`
- [ ] Narrow-width density refinements go in `mobile/mobile.scss`
- [ ] Desktop layout refinements go in `desktop/desktop.scss`
- [ ] Component renders correctly at all four surface modes:
  - expanded (≥ 1280px) — full labels, generous spacing
  - compact-desktop (1024–1279px) — tighter spacing, same interaction model
  - rail (768–1023px) — icon-only where applicable, floating labels
  - touch (< 768px or coarse pointer) — bottom-bar nav, thumb targets, overlays
- [ ] No raw `@media (max-width: Xpx)` as the sole source of touch behavior

## Testing

- [ ] Unit tests in `__tests__/components/shared/` directory
- [ ] Test props → CSS classes
- [ ] Test event handlers (`@onClick`, `@onChange`, etc.)
- [ ] Test ARIA attributes
- [ ] Test keyboard navigation (if applicable)
- [ ] Test at all four surface modes (expanded, compact-desktop, rail, touch)
- [ ] Test dark mode appearance

Example test file:
```javascript
// __tests__/components/shared/FomioComponentName.test.gjs
import { render } from '@ember/test-helpers';
import { hbs } from 'ember-source/dist/ember-template-compiler';
import FomioComponentName from 'fomio/components/shared/fomio-component-name';

describe('FomioComponentName', () => {
  it('renders with props', async () => {
    await render(hbs`<FomioComponentName @label="Test" />`);
    assert.dom('.fomio-component-name').exists();
    assert.dom('.fomio-component-name').hasText('Test');
  });
  
  it('calls event handlers', async () => {
    const handler = sinon.spy();
    await render(hbs`
      <FomioComponentName @onClick={{handler}} />
    `, { handler });
    await click('.fomio-component-name');
    assert.true(handler.calledOnce);
  });
  
  it('respects disabled state', async () => {
    await render(hbs`<FomioComponentName @disabled={{true}} />`);
    assert.dom('.fomio-component-name').hasAttribute('aria-disabled', 'true');
  });
});
```

## Documentation

- [ ] Brief comment at top of `.gjs` file describing the component
- [ ] Props documented (use comment block or JSDoc)
- [ ] Example usage in a comment or `docs/shared-component-development.md`
- [ ] Layer classification (Layer 1/2/3 or feature composition)

Example comment block:
```glimmer
<template>
  {{! 
    FomioButton — Layer 1 control component
    
    Props:
      @label (string) — Button text
      @variant (string) — "primary" | "secondary" | "ghost" | "danger"
      @size (string) — "sm" | "base" | "lg"
      @disabled (boolean) — Disable the button
      @loading (boolean) — Show loading spinner
      @leadingIcon (string) — Icon key from fomio-ph-icon
      @onClick (function) — Click handler
    
    Example:
      <FomioButton @variant="primary" @onClick={{this.handleSave}}>
        Save
      </FomioButton>
  }}
</template>
```

## Before Shipping

- [ ] All tests passing
- [ ] No linting errors (`eslint *.gjs`)
- [ ] Run `npm run tokens:check` if token changes were made
- [ ] Verified on desktop (Chrome, Safari)
- [ ] Verified on mobile (iPhone, Android simulator)
- [ ] Verified in dark mode
- [ ] All four surface modes work: expanded, compact-desktop, rail, touch
- [ ] No hardcoded strings or hex colors
- [ ] No console errors or warnings
- [ ] Design critique passed (for new components or significant changes)
- [ ] State matrix complete: all 6 states designed for every critical flow
- [ ] AI-genericness self-check passed: ≤ 35% card saturation, ≤ 2 persistent actions/item, Fomio-specific labels
- [ ] Accessibility bar: focus visible + not obscured, touch targets ≥ 44×44px, contrast ≥ 4.5:1 text / 3:1 non-text

## Code Review Checklist

When reviewing a shared component PR:

- [ ] Props are semantic and follow naming conventions?
- [ ] Event handlers clearly named (`@onClick`, not `@onPress`)?
- [ ] Component is stateless (no `@tracked` properties managing UI state)?
- [ ] Styles use `--fomio-*` variables and ARIA attributes for state?
- [ ] ARIA attributes correct for the semantic role?
- [ ] No business logic or API calls?
- [ ] Tests cover props, events, and accessibility?
- [ ] Keyboard navigation works if applicable?
- [ ] Dark mode appearance verified?
- [ ] No duplicate functionality with existing shared components?
- [ ] File in correct directory (`components/shared/`)?
- [ ] Styles in `common.scss` (not component-scoped CSS)?
- [ ] One primary action per region — not multiple equally-weighted persistent actions?
- [ ] State matrix present — not just the happy-path ideal state?
- [ ] No AI-generic patterns: no card saturation, no generic labels, no decorative motion?

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| "How do I manage open/close state for a dropdown?" | Don't — let `fomio-ui-components.gjs` manage it via aria-expanded. Parent component doesn't need to track state. |
| "Should this be a shared component or feature-specific?" | Shared if reusable across features; feature-specific if product-logic-heavy or one-off. Extract after second use. |
| "Where do I put styles?" | `common.scss` for all shared component styles. Only use `desktop.scss` / `mobile.scss` for refinements. |
| "Why isn't my keyboard navigation working?" | Check `fomio-ui-components.gjs` — if your component uses new selectors/classes, add them there. Don't put keyboard handlers in component JS. |
| "Should I use a component class or template-only component?" | Use a component class only if you need `@service` injections or computed properties. Otherwise, template-only is fine. |
| "How do I compose multiple shared components?" | Nest them in a feature component. Feature components own layout and data flow. See `fomio-user-profile-summary.gjs` for example. |

## Phase 2: Feature Integration

After Phase 1 stabilization:

- [ ] Audit existing feature UIs for custom markup that could use shared components
- [ ] Extract common patterns into new shared components (with design critique)
- [ ] Update feature components to use shared component APIs
- [ ] Update tests to verify shared component usage
- [ ] Verify no regressions in feature behavior

Reference: `docs/phase-1-shared-components-audit.md` — "Feature Adoption Status"
