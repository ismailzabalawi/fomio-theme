# Shared Component Development Guide

This guide provides practical patterns and conventions for developing and using the Fomio Web shared component system.

## Quick Links

- **Audit & Definitions:** `docs/phase-1-shared-components-audit.md`
- **Component Styles:** `common/common.scss` (Sections 2–6)
- **Interactive Behavior:** `javascripts/discourse/api-initializers/fomio-ui-components.gjs`
- **Component Directory:** `javascripts/discourse/components/shared/`

## Component Template

All shared components follow this structure:

```glimmer
<template>
  {{! A concise description of what this component does }}
  
  <div class="fomio-component" ...attributes>
    {{! Component content }}
  </div>
</template>

<script>
export default class FomioComponent {
  @service router;
  
  constructor(owner) {
    super(owner);
  }
}
</script>
```

**Key patterns:**
- Always include a one-line comment describing the component's role
- Use `.fomio-component` class (replace with actual name)
- Spread `...attributes` on the root element (allows HTML attributes from parent)
- No business logic — just display and event forwarding

## Component Props

Use semantic names and follow this vocabulary:

| Prop | Type | Use case |
|------|------|----------|
| `@variant` | string | `"primary"`, `"secondary"`, `"ghost"`, `"danger"` — for visual style variation |
| `@size` | string | `"sm"`, `"base"`, `"lg"` — for component sizing |
| `@disabled` | boolean | Disable the control (both visual + aria-disabled) |
| `@loading` | boolean | Show loading state (spinner, disabled) |
| `@leadingIcon` | string | Icon key from `fomio-ph-icon` (left side) |
| `@trailingIcon` | string | Icon key from `fomio-ph-icon` (right side) |
| `@label` | string | Human-readable label for input/select/textarea |
| `@hint` | string | Secondary text below label (gray, small) |
| `@error` | string | Error message below input (red, small) |
| `@value` | string/number | Current value for controlled inputs |
| `@selectedKey` | string | Currently selected key in tab/select/radio-group |

**Event handlers:**
| Handler | Signature | Use case |
|---------|-----------|----------|
| `@onClick` | `() => void` | Trigger-like button clicked |
| `@onChange` | `(value) => void` | Input/textarea value changed |
| `@onSelect` | `(key) => void` | Tab/segmented-control selected |
| `@onOpenChange` | `(open: boolean) => void` | Dropdown/sheet open/close toggled |

Example:

```glimmer
<FomioButton
  @variant="primary"
  @size="base"
  @disabled={{this.isLoading}}
  @loading={{this.isLoading}}
  @leadingIcon="check"
  @onClick={{this.handleSave}}
>
  Save
</FomioButton>
```

## State Management Pattern

Shared components are **display-only**. The parent component owns state:

```glimmer
<template>
  {{! Parent owns the state }}
  <FomioTabs
    @selectedKey={{this.activeTab}}
    @onSelect={{this.handleTabChange}}
  >
    <:tab1>
      Panel 1 content
    </:tab1>
    <:tab2>
      Panel 2 content
    </:tab2>
  </FomioTabs>
</template>

<script>
import { tracked } from '@glimmer/tracking';

export default class MyPage {
  @tracked activeTab = 'tab1';
  
  handleTabChange = (key) => {
    this.activeTab = key;
  };
}
</script>
```

**Key principle:** Component receives state as `@args`, calls handlers to notify parent of changes.

## ARIA Attributes & Accessibility

The interactive behavior layer (`fomio-ui-components.gjs`) manages all ARIA state. Components should:

1. **Use semantic HTML elements** — `<button>`, `<input>`, `<select>`, `<ul>`, `<li>`, etc.
2. **Let JavaScript set ARIA attributes** — don't hardcode `aria-expanded="true"` in the template; the behavior initializer will set it
3. **Preserve semantic focus flow** — don't prevent default keyboard behavior unless explicitly overriding with managed focus

Examples:

**Dropdown trigger** (JavaScript sets `aria-expanded`):
```glimmer
<button class="fomio-dropdown__trigger" data-trigger>
  {{@label}}
  <FomioPhIcon @icon="chevron-down" />
</button>
```

**Tabs triggers** (JavaScript sets `aria-selected` and manages panels):
```glimmer
<button 
  class="fomio-tabs__trigger"
  id="tab-{{@key}}"
  aria-controls="panel-{{@key}}"
>
  {{@label}}
</button>
<div id="panel-{{@key}}" class="fomio-tabs__panel" role="tabpanel">
  {{yield}}
</div>
```

**Input with error** (ARIA describes the error):
```glimmer
<label for={{@id}}>{{@label}}</label>
<input 
  id={{@id}}
  class="fomio-input"
  value={{@value}}
  aria-invalid={{if @error "true"}}
  aria-describedby={{if @error "error-{{@id}}"}}
  {{on "input" @onChange}}
/>
<div id="error-{{@id}}" class="fomio-input__error">
  {{@error}}
</div>
```

## Styling Conventions

All component styles live in `common.scss`. Use BEM naming with the `fomio-` prefix:

```scss
// Base class
.fomio-button {
  display: inline-flex;
  padding: var(--fomio-button-padding);
  background: var(--fomio-primary);
  color: var(--fomio-text);
  font-family: var(--fomio-font-ui);
  cursor: pointer;
  border: none;
  border-radius: var(--fomio-radius);
  transition: background 150ms ease;
  
  // Variants
  &.fomio-button--secondary {
    background: var(--fomio-secondary);
  }
  
  &.fomio-button--ghost {
    background: transparent;
    border: 1px solid var(--fomio-border);
  }
  
  // States
  &:hover:not(:disabled) {
    background: var(--fomio-primary-hover);
  }
  
  &:disabled,
  &[aria-disabled="true"] {
    opacity: 0.5;
    cursor: not-allowed;
  }
  
  // Size variants
  &.fomio-button--sm {
    padding: var(--fomio-button-padding-sm);
    font-size: 0.875rem;
  }
  
  &.fomio-button--lg {
    padding: var(--fomio-button-padding-lg);
    font-size: 1.125rem;
  }
  
  // ARIA state — let JavaScript manage this
  &[aria-busy="true"] {
    opacity: 0.6;
    pointer-events: none;
  }
}

// Sub-elements
.fomio-button__icon {
  width: 1em;
  height: 1em;
  margin-right: 0.5em;
}
```

**Rules:**
- Use CSS variables for all colors, spacing, typography — never hardcoded hex values
- Use ARIA attributes for state selection (`[aria-expanded="true"]`, `[aria-selected="true"]`, `[aria-disabled="true"]`)
- Avoid JS-managed class names like `.is-open` or `.active` — use ARIA instead
- Scoped dark mode via `html.fomio-color-dark .fomio-button { ... }`
- Touch-shell behavior (overlays, safe areas, thumb targets) belongs in `common/common.scss` under `body.fomio-surface-touch` — not only in `mobile/mobile.scss`, which is width-gated and will miss landscape phones and foldables
- Narrow-width density refinements go in `mobile/mobile.scss`; wide-layout and sidebar refinements go in `desktop/desktop.scss`
- Read `docs/responsive-design.md` before writing any surface-adaptive styles

## Example: Building a Layer 3 Component (Dropdown)

Starting point: "We need a dropdown with keyboard navigation and nested submenus."

### Step 1: Define ARIA contract

```glimmer
{{! fomio-dropdown.gjs }}
<template>
  {{! Dropdown: click trigger to toggle panel, keyboard nav (ArrowUp/Down/Right/Left, Escape) }}
  
  <div class="fomio-dropdown" {{#if @disabled}}aria-disabled="true"{{/if}}>
    <button
      class="fomio-dropdown__trigger"
      aria-expanded="false"
      aria-haspopup="menu"
      aria-label={{@label}}
      {{on "click" this.handleTriggerClick}}
    >
      {{@label}}
      <FomioPhIcon @icon="chevron-down" />
    </button>
    
    <div 
      class="fomio-dropdown__panel"
      role="menu"
      inert
    >
      {{yield}}
    </div>
  </div>
</template>
```

### Step 2: Let the behavior initializer manage state

```javascript
// fomio-ui-components.gjs — already handles dropdowns
// Just register .fomio-dropdown elements and the initializer does:
// - aria-expanded toggle on click
// - panel [inert] attribute
// - click-outside close
// - Escape close
// - ArrowUp/Down/Right/Left navigation
```

### Step 3: Style variants and states

```scss
// common.scss

.fomio-dropdown {
  position: relative;
  display: inline-block;
}

.fomio-dropdown__trigger {
  display: inline-flex;
  align-items: center;
  padding: var(--fomio-button-padding);
  background: var(--fomio-bg);
  border: 1px solid var(--fomio-border);
  cursor: pointer;
  
  // Visual feedback for open state
  &[aria-expanded="true"] {
    border-color: var(--fomio-primary);
    box-shadow: 0 0 0 2px rgba(var(--fomio-primary-rgb), 0.1);
  }
}

.fomio-dropdown__panel {
  position: absolute;
  top: 100%;
  left: 0;
  margin-top: 0.5rem;
  background: var(--fomio-bg);
  border: 1px solid var(--fomio-border);
  border-radius: var(--fomio-radius);
  box-shadow: var(--fomio-shadow-lg);
  min-width: 200px;
  
  // [inert] hides from keyboard + screen readers
  &[inert] {
    visibility: hidden;
    pointer-events: none;
  }
}

.fomio-dropdown__item {
  display: block;
  width: 100%;
  padding: 0.75rem 1rem;
  text-align: left;
  background: transparent;
  border: none;
  cursor: pointer;
  color: var(--fomio-text);
  
  &:focus-visible {
    outline: 2px solid var(--fomio-primary);
  }
  
  &[aria-disabled="true"] {
    opacity: 0.5;
    cursor: not-allowed;
  }
}
```

### Step 4: Export and use

```glimmer
{{! Feature component uses the shared component }}
<FomioDropdown @label="Sort by" @onSelect={{this.handleSort}}>
  <button class="fomio-dropdown__item">Latest</button>
  <button class="fomio-dropdown__item">Top</button>
  <button class="fomio-dropdown__item">New</button>
</FomioDropdown>
```

## Composition Example: Building a Feature Component

Feature: "User profile card with avatar, name, subtitle, and action buttons."

```glimmer
{{! fomio-user-profile-summary.gjs }}
<template>
  {{! Profile card: composes Avatar + Identity + MetaRow + Button }}
  
  <FomioCard class="fomio-user-profile-summary">
    <header class="fomio-user-profile-summary__header">
      <FomioAvatar
        @username={{@user.username}}
        @size="lg"
        @online={{@user.online}}
      />
      
      <FomioIdentity
        @username={{@user.username}}
        @subtitle={{@user.title}}
      />
    </header>
    
    <section class="fomio-user-profile-summary__stats">
      <FomioMetaRow
        @label="Posts"
        @value={{@user.postCount}}
      />
      <FomioMetaRow
        @label="Member since"
        @value={{this.joinedDate}}
      />
    </section>
    
    <footer class="fomio-user-profile-summary__actions">
      <FomioButton @variant="secondary" @onClick={{@onMessage}}>
        Send message
      </FomioButton>
      <FomioButton @variant="ghost" @onClick={{@onVisitProfile}}>
        View profile
      </FomioButton>
    </footer>
  </FomioCard>
</template>

<script>
import Component from '@glimmer/component';

export default class FomioUserProfileSummary extends Component {
  get joinedDate() {
    return new Intl.DateTimeFormat('en-US', {
      month: 'short',
      year: 'numeric'
    }).format(new Date(this.args.user.createdAt));
  }
}
</script>
```

**What this shows:**
- Composes Layer 1 (Button), Layer 2 (Card, Avatar, Identity, MetaRow)
- Still display-only — no logic beyond formatting
- Passes events up to parent (`@onMessage`, `@onVisitProfile`)
- Can be dropped into any feature that needs user profile display

## Phase 2 Work: Feature Integration

Once Phase 1 components are stabilized, Phase 2 adopts them in existing features:

1. **Audit existing feature UIs** — which use custom markup that could be replaced by shared components
2. **Extract shared patterns** — e.g., if three features have custom "empty state" markup, extract to `fomio-empty-state`
3. **Normalize feature component APIs** — update to use shared component conventions
4. **Test across surfaces** — verify desktop, tablet, mobile all work

See `docs/phase-1-shared-components-audit.md` Section "Feature Adoption Status" for adoption candidates.

## Testing Shared Components

Basic test structure:

```javascript
// __tests__/components/shared/FomioButton.test.gjs
import { render } from '@ember/test-helpers';
import { hbs } from 'ember-source/dist/ember-template-compiler';
import FomioButton from 'fomio/components/shared/fomio-button';

describe('FomioButton', () => {
  it('renders with variant and size', async () => {
    await render(hbs`
      <FomioButton
        @variant="primary"
        @size="lg"
      >
        Click me
      </FomioButton>
    `);
    
    assert.dom('.fomio-button').hasClass('fomio-button--primary');
    assert.dom('.fomio-button').hasClass('fomio-button--lg');
    assert.dom('.fomio-button').hasText('Click me');
  });
  
  it('calls @onClick when clicked', async () => {
    const onClick = sinon.spy();
    await render(hbs`
      <FomioButton @onClick={{onClick}}>
        Click
      </FomioButton>
    `, { onClick });
    
    await click('.fomio-button');
    assert.true(onClick.calledOnce);
  });
  
  it('disables when @disabled is true', async () => {
    await render(hbs`
      <FomioButton @disabled={{true}}>
        Disabled
      </FomioButton>
    `);
    
    assert.dom('.fomio-button').hasAttribute('aria-disabled', 'true');
    assert.dom('.fomio-button').isDisabled();
  });
});
```

**Key patterns:**
- Test props → CSS classes / ARIA attributes
- Test event handlers via `click()`, `fillIn()`, etc.
- Test accessibility (aria-*, role attributes)
- Don't test SCSS (visual appearance is tested in design reviews, not unit tests)

## Performance Considerations

1. **Event delegation** — All interactive behavior uses document-level event listeners. No performance risk from many components.
2. **Class names** — Use aria attributes for state selection, not managed class names. Faster SCSS targeting.
3. **Lazy components** — Layer 3 sheets/modals should use `{{#if @open}}` to avoid rendering when not needed.

## Common Mistakes to Avoid

1. **Business logic in shared components** — Don't fetch data, manage complex state, or call APIs. That belongs in feature components.
2. **Hardcoded styling** — Use `--fomio-*` CSS variables. Never inline hex colors.
3. **Managing ARIA manually** — Let `fomio-ui-components.gjs` set aria-expanded, aria-selected, etc. Don't hardcode them in templates.
4. **Avoiding composition** — If a shared component exists for what you need, use it. Don't build custom versions.
5. **Responsive via media queries alone** — `mobile/mobile.scss` is width-gated (< 640px). A touch phone in landscape or a foldable unfolded to 800px never receives it. Use `body.fomio-surface-touch` in `common.scss` for touch behavior. See `docs/responsive-design.md`.

## Resources

- **Responsive design:** `docs/responsive-design.md` — read before writing any surface-adaptive CSS
- **Design system audit:** `docs/phase-1-shared-components-audit.md`
- **Component styles:** `common/common.scss` (especially Sections 1A for tokens, Sections 2–6 for component styles)
- **Interactive behavior:** `javascripts/discourse/api-initializers/fomio-ui-components.gjs`
- **Design system product rules:** `apps/mobile/docs/00-product/product-ui-rules.md`
- **Icon library:** `fomio-ph-icon.gjs` (uses Phosphor icons)

## Questions?

Refer to:
1. **"How do I build a component?"** → Start with the template section above
2. **"What props should this have?"** → Check the component vocabulary table
3. **"How do I style it?"** → Look at existing layer components in `common.scss`
4. **"Is this a shared component or feature-specific?"** → Check the audit; if unsure, keep local and extract after second use
