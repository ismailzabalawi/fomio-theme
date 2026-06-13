import Component from "@glimmer/component";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import { getCurrentThemeMode } from "../../lib/fomio-preferences-api";
import FomioPreferencesScreen from "../../components/fomio-preferences-screen";

// Connector that renders the FomioPreferencesScreen within the user profile.
// This integration shows the full wiring pattern for:
// - Passing user data and preferences to the component
// - Handling all callbacks from the preferences screen
// - Managing loading states during API operations
// - Only rendering on the user's own profile

export default class FomioPreferencesTab extends Component {
  @service currentUser;
  @service router;
  @service site;
  @tracked isLoading = false;

  get isOwnProfile() {
    return this.currentUser?.id === this.args.user?.id;
  }

  get currentThemeMode() {
    return getCurrentThemeMode(this.currentUser, this.site);
  }

  get appVersion() {
    return this.args.siteSettings?.fomio_app_version || "1.0.0";
  }

  @action
  async handleThemeModeChange(mode) {
    this.isLoading = true;
    try {
      // Call the preferences menu initializer's callback
      const args = this.args.controller.preferencesScreenArgs;
      if (args?.onThemeModeChange) {
        await args.onThemeModeChange(mode);
      }
    } catch (error) {
      console.error("Error changing theme:", error);
    } finally {
      this.isLoading = false;
    }
  }

  @action
  async handleSignOut() {
    this.isLoading = true;
    try {
      const args = this.args.controller.preferencesScreenArgs;
      if (args?.onSignOut) {
        await args.onSignOut();
      }
    } catch (error) {
      console.error("Error signing out:", error);
    } finally {
      this.isLoading = false;
    }
  }

  @action
  async handleDeleteAccount() {
    this.isLoading = true;
    try {
      const args = this.args.controller.preferencesScreenArgs;
      if (args?.onDeleteAccount) {
        await args.onDeleteAccount();
      }
    } catch (error) {
      console.error("Error deleting account:", error);
    } finally {
      this.isLoading = false;
    }
  }

  @action
  async handleProfileVisibility() {
    const args = this.args.controller.preferencesScreenArgs;
    if (args?.onProfileVisibility) {
      await args.onProfileVisibility();
    }
  }

  @action
  handleContactSupport() {
    const args = this.args.controller.preferencesScreenArgs;
    if (args?.onContactSupport) {
      args.onContactSupport();
    }
  }

  @action
  handleRateApp() {
    const args = this.args.controller.preferencesScreenArgs;
    if (args?.onRateApp) {
      args.onRateApp();
    }
  }

  @action
  handlePrivacyPolicy() {
    const args = this.args.controller.preferencesScreenArgs;
    if (args?.onPrivacyPolicy) {
      args.onPrivacyPolicy();
    }
  }

  @action
  handleTermsOfService() {
    const args = this.args.controller.preferencesScreenArgs;
    if (args?.onTermsOfService) {
      args.onTermsOfService();
    }
  }

  <template>
    {{#if this.isOwnProfile}}
      <div class="fomio-preferences-tab-wrapper">
        <FomioPreferencesScreen
          @isAuthenticated={{this.currentUser.id}}
          @username={{this.currentUser.username}}
          @themeMode={{this.currentThemeMode}}
          @appVersion={{this.appVersion}}
          @loading={{this.isLoading}}
          @onThemeModeChange={{this.handleThemeModeChange}}
          @onSignOut={{this.handleSignOut}}
          @onDeleteAccount={{this.handleDeleteAccount}}
          @onProfileVisibility={{this.handleProfileVisibility}}
          @onContactSupport={{this.handleContactSupport}}
          @onRateApp={{this.handleRateApp}}
          @onPrivacyPolicy={{this.handlePrivacyPolicy}}
          @onTermsOfService={{this.handleTermsOfService}}
        />
      </div>
    {{/if}}
  </template>
}

