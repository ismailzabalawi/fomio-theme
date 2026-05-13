import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import FomioMeActivityNav from "../../components/fomio-me-activity-nav";
import {
  getFomioActivityChildSections,
  isOwnedActivitySectionPath,
} from "../../lib/fomio-account-sections";
import { isAuthPath } from "../../lib/fomio-mobile-nav-paths";
import { subscribeFomioTouchShell } from "../../lib/fomio-subscribe-touch-shell";

export default class FomioMeActivityNavDesktopConnector extends Component {
  @service router;
  @service currentUser;
  @service siteSettings;

  @tracked isTouchShell = false;
  #unsubscribeTouch = null;

  constructor(owner, args) {
    super(owner, args);
    this.#unsubscribeTouch = subscribeFomioTouchShell((value) => {
      this.isTouchShell = value;
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
    if (this.isTouchShell || isAuthPath(this.currentPath)) {
      return false;
    }

    return Boolean(this.currentUser) && isOwnedActivitySectionPath(this.currentPath);
  }

  get sections() {
    return getFomioActivityChildSections({
      currentUser: this.currentUser,
      currentPath: this.currentPath,
      siteSettings: this.siteSettings,
    }).map((section) => ({
      ...section,
      label: i18n(themePrefix(section.labelKey)),
    }));
  }

  <template>
    {{#if this.shouldRender}}
      <FomioMeActivityNav @sections={{this.sections}} />
    {{/if}}
  </template>
}
