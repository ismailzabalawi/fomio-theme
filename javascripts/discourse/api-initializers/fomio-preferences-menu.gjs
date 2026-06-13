import { apiInitializer } from "discourse/lib/api";
import {
  updateThemePreference,
  signOutUser,
  requestAccountDeletion,
  updateNotificationPreference,
  getCurrentThemeMode,
  updatePrivacySetting,
} from "../lib/fomio-preferences-api";

// Integrates the Fomio preferences screen into the Discourse theme system.
// This initializer:
// 1. Registers the FomioPreferencesScreen component
// 2. Provides preferences context (current user, theme mode, callbacks)
// 3. Wires up API calls for theme/settings persistence
// 4. Handles sign-out, delete account, and other destructive actions

export default apiInitializer("1.8.0", (api) => {
  // Register the FomioPreferencesScreen component for use in connectors
  api.registerComponent("fomio-preferences-screen", () =>
    import("../components/fomio-preferences-screen")
  );

  // Helper to resolve theme IDs from site themes
  function getThemeIdMap(site) {
    const themes = site.themes || [];
    const map = { light: null, dark: null, system: [] };

    // Find light and dark theme IDs by name
    for (const theme of themes) {
      const name = theme.name?.toLowerCase() || "";
      if (name.includes("fomio") && !name.includes("dark")) {
        map.light = theme.id;
      }
      if (name.includes("fomio") && name.includes("dark")) {
        map.dark = theme.id;
      }
    }

    return map;
  }

  // Extend the application controller to provide preferences context
  api.modifyClass("controller:application", {
    pluginId: "fomio-preferences",

    // Computed properties for preferences data
    get currentThemeMode() {
      return getCurrentThemeMode(this.currentUser, this.site);
    },

    get themeIdMap() {
      return getThemeIdMap(this.site);
    },

    // Helper to show notifications (uses Discourse's capabilities or fallback)
    showNotification(message, type = "success") {
      // Try to use Discourse's notification system if available
      if (this.get("model.sent")) {
        // Controller has notification capability
        this.set("model.sent", message);
      } else {
        // Fallback to console logging with structured output
        const prefix = `[Fomio ${type.toUpperCase()}]`;
        console[type === "danger" ? "error" : "log"](prefix, message);
      }
    },

    get preferencesScreenArgs() {
      const user = this.currentUser;

      if (!user) {
        return null;
      }

      // Create a bound instance of this controller for use in callbacks
      const self = this;
      const themeMap = this.themeIdMap;

      return {
        isAuthenticated: Boolean(user.id),
        username: user.username,
        themeMode: this.currentThemeMode,
        appVersion: this.siteSettings?.fomio_app_version || "1.0.0",
        loading: false,

        // Callback: Update theme mode
        onThemeModeChange: async (mode) => {
          try {
            self.set("loading", true);
            await updateThemePreference(user, mode, themeMap);
            // Update local state
            user.notifyPropertyChange("theme_ids");
            self.showNotification("Theme preference saved", "success");
          } catch (error) {
            console.error("Error updating theme:", error);
          } finally {
            self.set("loading", false);
          }
        },

        // Callback: Sign out
        onSignOut: async () => {
          try {
            self.set("loading", true);
            await signOutUser(user);
            // Navigation happens in API call
          } catch (error) {
            console.error("Error signing out:", error);
          } finally {
            self.set("loading", false);
          }
        },

        // Callback: Delete account (initiates confirmation flow)
        onDeleteAccount: async () => {
          try {
            self.set("loading", true);
            await requestAccountDeletion(user);
            // Navigation happens in API call
          } catch (error) {
            console.error("Error requesting account deletion:", error);
          } finally {
            self.set("loading", false);
          }
        },

        // Callback: Profile visibility settings
        onProfileVisibility: async () => {
          // Would navigate to privacy settings page or open modal
          console.log("Profile visibility settings requested");
        },

        // Callback: Contact support
        onContactSupport: () => {
          const supportEmail = this.siteSettings?.fomio_support_email || "support@fomio.app";
          window.location.href = `mailto:${supportEmail}?subject=Support Request`;
        },

        // Callback: Rate app
        onRateApp: () => {
          const appUrl = this.siteSettings?.fomio_app_url || "https://fomio.app";
          window.location.href = `${appUrl}/apps`;
        },

        // Callback: Privacy policy
        onPrivacyPolicy: () => {
          const privacyUrl = this.siteSettings?.privacy_policy_url || "https://meta.fomio.app/privacy";
          window.location.href = privacyUrl;
        },

        // Callback: Terms of service
        onTermsOfService: () => {
          const tosUrl = this.siteSettings?.tos_url || "https://meta.fomio.app/tos";
          window.location.href = tosUrl;
        },
      };
    },
  });
});
