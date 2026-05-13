import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import FomioMeActivityNav from "../../components/fomio-me-activity-nav";
import FomioMeStackHeader from "../../components/fomio-me-stack-header";
import {
  getFomioActivityChildSections,
  isOwnedActivitySectionPath,
} from "../../lib/fomio-account-sections";
import {
  isAuthPath,
  isActivityPath,
  isMeStackPath,
  meSectionTitleKey,
  profileSummaryPathForUser,
} from "../../lib/fomio-mobile-nav-paths";
import { subscribeFomioTouchShell } from "../../lib/fomio-subscribe-touch-shell";
import { armMeHubLandingForNextSummaryVisit } from "../../lib/fomio-me-hub-landing";

/**
 * Connector: below-site-header
 *
 * Renders the Me stack header (‹ Me | Section Title) on touch surfaces
 * whenever the user is on a Me leaf page (Activity, Preferences, Notifications,
 * Messages, Invites, Badges) — i.e. inside the Me context but NOT on the hub
 * landing screen (/u/:me/summary).
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
    return (this.router.currentURL || "").split("?")[0];
  }

  get shouldRender() {
    if (!this.isTouchShell) {
      return false;
    }
    if (isAuthPath(this.currentPath)) {
      return false;
    }
    return isMeStackPath(this.currentPath, this.currentUser);
  }

  get backHref() {
    return profileSummaryPathForUser(this.currentUser) ?? "/";
  }

  get sectionTitle() {
    const key = meSectionTitleKey(this.currentPath);
    if (!key) {
      return null;
    }
    return i18n(themePrefix(key));
  }

  get shouldRenderActivityNav() {
    return isActivityPath(this.currentPath) && isOwnedActivitySectionPath(this.currentPath);
  }

  get activitySections() {
    return getFomioActivityChildSections({
      currentUser: this.currentUser,
      currentPath: this.currentPath,
    }).map((section) => ({
      ...section,
      label: i18n(themePrefix(section.labelKey)),
    }));
  }

  @action
  armMeHubLandingBeforeBack(e) {
    if (
      e &&
      (e.ctrlKey || e.metaKey || e.shiftKey || e.altKey || e.button !== 0)
    ) {
      return;
    }
    armMeHubLandingForNextSummaryVisit();
  }

  <template>
    {{#if this.shouldRender}}
      <div class="fomio-me-stack-shell">
        <FomioMeStackHeader
          @backHref={{this.backHref}}
          @sectionTitle={{this.sectionTitle}}
          @onBackClick={{this.armMeHubLandingBeforeBack}}
        />

        {{#if this.shouldRenderActivityNav}}
          <FomioMeActivityNav @sections={{this.activitySections}} />
        {{/if}}
      </div>
    {{/if}}
  </template>
}
