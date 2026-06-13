import Component from "@glimmer/component";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import { eq, not } from "discourse/truth-helpers";
import FomioModal from "./shared/fomio-modal";

// Account preferences screen for the web theme. Organizes user settings into
// sections (Appearance, Notifications, Privacy, Account, Storage, About,
// Danger Zone) using the Layer 1/2/3 component system. Stateful: manages
// theme selection, confirmation modals, and busy states locally. Consumers
// pass callbacks for persistence.
//
// Props: @themeMode, @isAuthenticated, @appVersion, @loading
// Callbacks: @onThemeModeChange, @onSignOut, @onDeleteAccount,
//           @onProfileVisibility, @onContactSupport, @onRateApp,
//           @onPrivacyPolicy, @onTermsOfService

export default class FomioPreferencesScreen extends Component {
  @tracked themeMode = this.args.themeMode ?? "system";
  @tracked showThemeSelectModal = false;
  @tracked showSignOutModal = false;
  @tracked showDeleteAccountModal = false;
  @tracked isBusy = false;

  get themeLabel() {
    const labels = { light: "Light", dark: "Dark", system: "System" };
    return labels[this.themeMode] ?? "System";
  }

  @action
  toggleSystemTheme(enabled) {
    const newMode = enabled ? "system" : "light";
    this.themeMode = newMode;
    this.args.onThemeModeChange?.(newMode);
  }

  @action
  openThemeModal() {
    this.showThemeSelectModal = true;
  }

  @action
  selectTheme(mode) {
    this.themeMode = mode;
    this.showThemeSelectModal = false;
    this.args.onThemeModeChange?.(mode);
  }

  @action
  openSignOutModal() {
    this.showSignOutModal = true;
  }

  @action
  closeSignOutModal() {
    this.showSignOutModal = false;
  }

  @action
  async handleSignOut() {
    this.isBusy = true;
    try {
      await this.args.onSignOut?.();
    } finally {
      this.isBusy = false;
    }
  }

  @action
  openDeleteAccountModal() {
    this.showDeleteAccountModal = true;
  }

  @action
  closeDeleteAccountModal() {
    this.showDeleteAccountModal = false;
  }

  @action
  async handleDeleteAccount() {
    this.isBusy = true;
    try {
      await this.args.onDeleteAccount?.();
    } finally {
      this.isBusy = false;
    }
  }

  <template>
    <div class="fomio-preferences-screen">
      <!-- Appearance -->
      <h2 class="fomio-preferences-section-title">Appearance</h2>
      <ul class="fomio-list">
        <li class="fomio-list__item">
          <button
            type="button"
            class="fomio-list__button"
            disabled={{@loading}}
            {{on "click" (fn this.toggleSystemTheme (not (eq this.themeMode "system")))}}
          >
            <span class="fomio-list__icon" aria-hidden="true">◐</span>
            <span class="fomio-list__content">
              <span class="fomio-list__title">Follow system theme</span>
              <span class="fomio-list__subtitle">Match device settings</span>
            </span>
          </button>
        </li>
        <li class="fomio-list__item">
          <button
            type="button"
            class="fomio-list__button"
            {{on "click" this.openThemeModal}}
          >
            <span class="fomio-list__icon" aria-hidden="true">🌙</span>
            <span class="fomio-list__content">
              <span class="fomio-list__title">Theme</span>
              <span class="fomio-list__subtitle">{{this.themeLabel}}</span>
            </span>
            <span class="fomio-list__meta">{{this.themeLabel}}</span>
          </button>
        </li>
      </ul>

      <!-- Notifications -->
      <h2 class="fomio-preferences-section-title">Notifications</h2>
      <ul class="fomio-list">
        <li class="fomio-list__item">
          <button type="button" class="fomio-list__button" disabled>
            <span class="fomio-list__icon" aria-hidden="true">🔔</span>
            <span class="fomio-list__content">
              <span class="fomio-list__title">Push notifications</span>
              <span class="fomio-list__subtitle">Receive activity alerts • Coming soon</span>
            </span>
          </button>
        </li>
        <li class="fomio-list__item">
          <button type="button" class="fomio-list__button">
            <span class="fomio-list__icon" aria-hidden="true">🔔</span>
            <span class="fomio-list__content">
              <span class="fomio-list__title">Notification preferences</span>
              <span class="fomio-list__subtitle">Customize your notifications</span>
            </span>
          </button>
        </li>
      </ul>

      <!-- Privacy -->
      <h2 class="fomio-preferences-section-title">Privacy</h2>
      <ul class="fomio-list">
        <li class="fomio-list__item">
          <button
            type="button"
            class="fomio-list__button"
            {{on "click" @onProfileVisibility}}
          >
            <span class="fomio-list__icon" aria-hidden="true">🛡️</span>
            <span class="fomio-list__content">
              <span class="fomio-list__title">Profile visibility</span>
              <span class="fomio-list__subtitle">Control who can see your activity</span>
            </span>
          </button>
        </li>
        <li class="fomio-list__item">
          <button type="button" class="fomio-list__button">
            <span class="fomio-list__icon" aria-hidden="true">✋</span>
            <span class="fomio-list__content">
              <span class="fomio-list__title">Blocked users</span>
              <span class="fomio-list__subtitle">Manage your blocked list</span>
            </span>
          </button>
        </li>
      </ul>

      <!-- Account -->
      <h2 class="fomio-preferences-section-title">Account</h2>
      <ul class="fomio-list">
        <li class="fomio-list__item">
          <button type="button" class="fomio-list__button">
            <span class="fomio-list__icon" aria-hidden="true">👤</span>
            <span class="fomio-list__content">
              <span class="fomio-list__title">Edit profile</span>
              <span class="fomio-list__subtitle">Avatar, bio, links</span>
            </span>
          </button>
        </li>
      </ul>

      {{#if @isAuthenticated}}
        <!-- Storage & Cache -->
        <h2 class="fomio-preferences-section-title">Storage &amp; Cache</h2>
        <ul class="fomio-list">
          <li class="fomio-list__item">
            <button type="button" class="fomio-list__button" disabled>
              <span class="fomio-list__icon" aria-hidden="true">💾</span>
              <span class="fomio-list__content">
                <span class="fomio-list__title">Storage &amp; cache</span>
                <span class="fomio-list__subtitle">Free up storage space • Coming soon</span>
              </span>
            </button>
          </li>
          <li class="fomio-list__item">
            <button type="button" class="fomio-list__button" disabled>
              <span class="fomio-list__icon" aria-hidden="true">⬇️</span>
              <span class="fomio-list__content">
                <span class="fomio-list__title">Offline mode</span>
                <span class="fomio-list__subtitle">Cache latest feed for offline • Coming soon</span>
              </span>
            </button>
          </li>
        </ul>
      {{/if}}

      <!-- About -->
      <h2 class="fomio-preferences-section-title">About</h2>
      <ul class="fomio-list">
        <li class="fomio-list__item">
          <button type="button" class="fomio-list__button" disabled>
            <span class="fomio-list__icon" aria-hidden="true">ℹ️</span>
            <span class="fomio-list__content">
              <span class="fomio-list__title">Version</span>
              <span class="fomio-list__subtitle">App version</span>
            </span>
            <span class="fomio-list__meta">{{@appVersion}}</span>
          </button>
        </li>
        <li class="fomio-list__item">
          <button
            type="button"
            class="fomio-list__button"
            {{on "click" @onContactSupport}}
          >
            <span class="fomio-list__icon" aria-hidden="true">❓</span>
            <span class="fomio-list__content">
              <span class="fomio-list__title">Contact support</span>
              <span class="fomio-list__subtitle">Get help with your account</span>
            </span>
          </button>
        </li>
        <li class="fomio-list__item">
          <button type="button" class="fomio-list__button" {{on "click" @onRateApp}}>
            <span class="fomio-list__icon" aria-hidden="true">⭐</span>
            <span class="fomio-list__content">
              <span class="fomio-list__title">Rate Fomio</span>
              <span class="fomio-list__subtitle">Help us improve with your feedback</span>
            </span>
          </button>
        </li>
        <li class="fomio-list__item">
          <button
            type="button"
            class="fomio-list__button"
            {{on "click" @onPrivacyPolicy}}
          >
            <span class="fomio-list__icon" aria-hidden="true">🔐</span>
            <span class="fomio-list__content">
              <span class="fomio-list__title">Privacy policy</span>
              <span class="fomio-list__subtitle">Read our privacy policy</span>
            </span>
          </button>
        </li>
        <li class="fomio-list__item">
          <button
            type="button"
            class="fomio-list__button"
            {{on "click" @onTermsOfService}}
          >
            <span class="fomio-list__icon" aria-hidden="true">📄</span>
            <span class="fomio-list__content">
              <span class="fomio-list__title">Terms of service</span>
              <span class="fomio-list__subtitle">Read our terms of service</span>
            </span>
          </button>
        </li>
      </ul>

      {{#if @isAuthenticated}}
        <!-- Danger Zone -->
        <h2 class="fomio-preferences-section-title fomio-preferences-section-title--danger">
          Danger Zone
        </h2>
        <ul class="fomio-list">
          <li class="fomio-list__item">
            <button
              type="button"
              class="fomio-list__button fomio-list__button--danger"
              {{on "click" this.openSignOutModal}}
            >
              <span class="fomio-list__icon" aria-hidden="true">🚪</span>
              <span class="fomio-list__content">
                <span class="fomio-list__title">Sign out</span>
                <span class="fomio-list__subtitle">Sign out of your account</span>
              </span>
            </button>
          </li>
          <li class="fomio-list__item">
            <button type="button" class="fomio-list__button fomio-list__button--danger" disabled>
              <span class="fomio-list__icon" aria-hidden="true">🔑</span>
              <span class="fomio-list__content">
                <span class="fomio-list__title">Revoke all access</span>
                <span class="fomio-list__subtitle">Sign out from app and browser • Coming soon</span>
              </span>
            </button>
          </li>
          <li class="fomio-list__item">
            <button
              type="button"
              class="fomio-list__button fomio-list__button--danger"
              {{on "click" this.openDeleteAccountModal}}
            >
              <span class="fomio-list__icon" aria-hidden="true">🗑️</span>
              <span class="fomio-list__content">
                <span class="fomio-list__title">Delete account</span>
                <span class="fomio-list__subtitle">Permanently delete your account</span>
              </span>
            </button>
          </li>
        </ul>
      {{/if}}

      <!-- Theme Selection Modal -->
      <FomioModal
        @open={{this.showThemeSelectModal}}
        @title="Choose theme"
        @onOpenChange={{fn (mut this.showThemeSelectModal)}}
      >
        <div class="fomio-modal-theme-select">
          <button
            type="button"
            class="fomio-modal-theme-option {{if (eq this.themeMode "light") "active"}}"
            {{on "click" (fn this.selectTheme "light")}}
          >
            <span class="fomio-modal-theme-icon">☀️</span>
            <span class="fomio-modal-theme-label">Light</span>
          </button>
          <button
            type="button"
            class="fomio-modal-theme-option {{if (eq this.themeMode "dark") "active"}}"
            {{on "click" (fn this.selectTheme "dark")}}
          >
            <span class="fomio-modal-theme-icon">🌙</span>
            <span class="fomio-modal-theme-label">Dark</span>
          </button>
          <button
            type="button"
            class="fomio-modal-theme-option {{if (eq this.themeMode "system") "active"}}"
            {{on "click" (fn this.selectTheme "system")}}
          >
            <span class="fomio-modal-theme-icon">◐</span>
            <span class="fomio-modal-theme-label">System</span>
          </button>
        </div>
      </FomioModal>

      <!-- Sign Out Confirmation Modal -->
      <FomioModal
        @open={{this.showSignOutModal}}
        @title="Sign out"
        @body="You will be signed out of your account. Are you sure?"
        @cancelLabel="Cancel"
        @confirmLabel="Sign out"
        @danger={{true}}
        @onOpenChange={{fn (mut this.showSignOutModal)}}
        @onConfirm={{this.handleSignOut}}
      />

      <!-- Delete Account Confirmation Modal -->
      <FomioModal
        @open={{this.showDeleteAccountModal}}
        @title="Delete account"
        @body="Deleting your account is permanent and cannot be undone. All your data will be lost. Are you sure?"
        @cancelLabel="Cancel"
        @confirmLabel="Delete account"
        @danger={{true}}
        @onOpenChange={{fn (mut this.showDeleteAccountModal)}}
        @onConfirm={{this.handleDeleteAccount}}
      />
    </div>
  </template>
}
