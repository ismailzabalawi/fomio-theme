import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import FomioMeActivityNav from "../../components/shared/fomio-me-activity-nav";
import FomioMeStackHeader from "../../components/shared/fomio-me-stack-header";
import {
  getFomioActivityChildSections,
  getFomioNotificationsChildSections,
  isOwnedActivitySectionPath,
} from "../../lib/fomio-account-sections";
import {
  hasFomioPreferencesMenuMarker,
  isFomioPreferencesChildPath,
  setFomioPreferencesMenuMarker,
} from "../../lib/fomio-preferences-sections";
import {
  isActivityPath,
  isFomioShellPath,
  isMeStackPath,
  isNotificationsPath,
  isOwnNotificationsPath,
  meHubPathForUser,
  meSectionTitleKey,
} from "../../lib/fomio-mobile-nav-paths";
import { fomioCurrentPath } from "../../lib/fomio-router-pathname";
import { subscribeFomioTouchShell } from "../../lib/fomio-subscribe-touch-shell";

/**
 * Connector: below-site-header
 *
 * Renders the Me stack header (‹ Me | Section Title) on touch surfaces
 * whenever the user is on a Me leaf page (Activity, Preferences, Notifications,
 * Messages, Invites, Badges) — i.e. inside the Me context but NOT on the hub
 * landing screen (`/u/:me`).
 *
 * Relies on:
 *  - `isMeStackPath` — true for any Me leaf that's not the hub
 *  - `meSectionTitleKey` — maps the current path to an i18n key
 *  - `subscribeFomioTouchShell` — reacts to surface-mode changes
 */
export default class FomioMeStackHeaderConnector extends Component {
  @service router;
  @service currentUser;

  @tracked isTouchShell = false;
  #unsubscribeTouch = null;

  constructor(owner, args) {
    super(owner, args);
    this.#unsubscribeTouch = subscribeFomioTouchShell((v) => {
      this.isTouchShell = v;
    });
  }

  willDestroy() {
    this.#unsubscribeTouch?.();
    super.willDestroy();
  }

  get currentPath() {
    return fomioCurrentPath(this.router.currentURL || "");
  }

  get shouldRender() {
    if (!this.isTouchShell) {
      return false;
    }
    if (!isFomioShellPath(this.currentPath)) {
      return false;
    }
    if (this.isPrimaryNotificationsDestination) {
      return false;
    }
    return isMeStackPath(this.currentPath, this.currentUser);
  }

  get isPrimaryNotificationsDestination() {
    if (!isOwnNotificationsPath(this.currentPath, this.currentUser)) {
      return false;
    }

    const path = this.currentPath.replace(/\/+$/, "") || "/";

    if (path === "/notifications" || path === "/my/notifications") {
      return true;
    }

    if (!this.currentUser?.username) {
      return false;
    }

    const ownPath = `/u/${this.currentUser.username}/notifications`;
    return path.toLowerCase() === ownPath.toLowerCase();
  }

  get backHref() {
    return meHubPathForUser(this.currentUser) ?? "/";
  }

  get sectionTitle() {
    const key = meSectionTitleKey(this.currentPath);
    if (!key) {
      return null;
    }
    return i18n(themePrefix(key));
  }

  get shouldRenderActivityNav() {
    return (
      isActivityPath(this.currentPath) &&
      isOwnedActivitySectionPath(this.currentPath)
    );
  }

  get shouldRenderNotificationsNav() {
    return isNotificationsPath(this.currentPath);
  }

  get shouldRenderPreferencesButton() {
    return (
      isFomioPreferencesChildPath(this.currentPath) &&
      !hasFomioPreferencesMenuMarker(this.router.currentURL || "")
    );
  }

  get shouldRenderChildNav() {
    return this.shouldRenderActivityNav || this.shouldRenderNotificationsNav;
  }

  get childNavAriaLabel() {
    if (this.shouldRenderNotificationsNav) {
      return i18n(themePrefix("notifications_master_pane.title"));
    }
    return null;
  }

  get childSections() {
    const builder = this.shouldRenderNotificationsNav
      ? getFomioNotificationsChildSections
      : getFomioActivityChildSections;

    return builder({
      currentUser: this.currentUser,
      currentPath: this.currentPath,
    }).map((section) => ({
      ...section,
      label: i18n(themePrefix(section.labelKey)),
    }));
  }

  @action
  openPreferencesMenu() {
    setFomioPreferencesMenuMarker();
    this.router.transitionTo("/my/preferences?fomio_menu=1");
  }

  <template>
    {{#if this.shouldRender}}
      <div class="fomio-me-stack-shell">
        <FomioMeStackHeader
          @backHref={{this.backHref}}
          @sectionTitle={{this.sectionTitle}}
          @onPreferencesClick={{if this.shouldRenderPreferencesButton this.openPreferencesMenu}}
        />

        {{#if this.shouldRenderChildNav}}
          <FomioMeActivityNav
            @sections={{this.childSections}}
            @ariaLabel={{this.childNavAriaLabel}}
          />
        {{/if}}
      </div>
    {{/if}}
  </template>
}
