# Preferences Screen Integration Guide

## Overview

The `fomio-preferences-screen.gjs` component provides a complete account settings interface for the web theme, supporting all 7 preference sections (Appearance, Notifications, Privacy, Account, Storage, About, Danger Zone).

## Architecture

```
FomioPreferencesScreen (display component)
    ↓
fomio-preferences-menu.gjs (API initializer — registers component & callbacks)
    ↓
[Connector or custom route needed to render]
```

## Integration Points

The component is stateless from a data perspective — all user data and callbacks are passed in as props:

| Prop | Type | Purpose |
|------|------|---------|
| `@isAuthenticated` | boolean | Show/hide danger zone |
| `@themeMode` | 'light'\|'dark'\|'system' | Current theme selection |
| `@appVersion` | string | Version displayed in About section |
| `@loading` | boolean | Disable controls while loading |
| `@onThemeModeChange` | function | Persist theme preference |
| `@onSignOut` | function | Handle sign out |
| `@onDeleteAccount` | function | Handle account deletion |
| `@onProfileVisibility` | function | Open profile visibility settings |
| `@onContactSupport` | function | Route to support |
| `@onRateApp` | function | Route to rate app |
| `@onPrivacyPolicy` | function | Route to privacy policy |
| `@onTermsOfService` | function | Route to terms |

## Rendering Options

### Option 1: Custom User Preferences Route (Recommended)

Create a new route `/u/{username}/fomio-preferences` that renders the component with proper context.

```gjs
// app/components/routes/user-fomio-preferences.gjs
export default class UserFomioPreferencesRoute {
  <template>
    <FomioPreferencesScreen
      @isAuthenticated={{@user.id}}
      @themeMode={{@currentThemeMode}}
      @appVersion={{@appVersion}}
      @onThemeModeChange={{this.persistThemeMode}}
      @onSignOut={{this.handleSignOut}}
      {{! ... other callbacks }}
    />
  </template>
}
```

### Option 2: User Profile Tab

Inject the preferences screen as a tab in the existing user profile page using a connector at the user profile outlet.

### Option 3: Sidebar Menu Integration

Add a "Settings" or "Preferences" link to the Fomio sidebar navigation (fomio-sidebar.gjs) that opens the preferences screen in a modal or dedicated panel.

## Data Flow

### Reading Settings
1. Component renders with current user theme/prefs from props
2. Component state tracks local changes (theme modal, confirmation dialogs)
3. On confirmation, callback is invoked

### Writing Settings
Callbacks must handle persistence via API:

```javascript
onThemeModeChange: async (mode) => {
  // Call Discourse API to update user preference
  await fetch(`/u/${currentUser.username}/preferences.json`, {
    method: "PUT",
    body: JSON.stringify({ theme_ids: [themeIdForMode(mode)] })
  });
},

onSignOut: async () => {
  // Call Discourse sign-out endpoint
  await fetch("/session.json", { method: "DELETE" });
  // Then redirect to home
},

onDeleteAccount: async () => {
  // Navigate to account deletion flow
  router.push("/u/account-delete");
},
```

## Styling & Layout

The component uses the Fomio design system (Layer 1/2/3 components) and includes built-in SCSS:

- `.fomio-preferences-screen` — main container (max-width: 680px reading measure)
- `.fomio-preferences-section-title` — section headers
- `.fomio-list` — settings group container
- `.fomio-list__item`, `.fomio-list__button` — individual setting rows

All styles use `--fomio-*` tokens for theming.

## Testing & Verification

To test the preferences screen locally:

1. Create a test route or connector that renders the component
2. Pass mock props with test callbacks
3. Verify all sections render correctly
4. Test modal interactions (theme select, confirmations)
5. Verify responsive layout at different breakpoints

## Next Steps

1. Choose integration point (custom route, tab, or sidebar)
2. Create connector/route component
3. Wire up Discourse API callbacks for persistence
4. Test theme switching, sign-out, delete flows
5. Ensure accessibility across all modals and interactions

## Known Limitations

- Currently uses emoji icons (could be upgraded to Discourse icon system)
- Theme selection modal is basic (could be enhanced with theme previews)
- Sign-out/delete confirmations need full implementation
- Some "Coming soon" features (push notifications, offline mode) are placeholders
