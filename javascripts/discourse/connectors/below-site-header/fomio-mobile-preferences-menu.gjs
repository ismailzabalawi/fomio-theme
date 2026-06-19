import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import FomioList from "../../components/shared/fomio-list";
import FomioListItem from "../../components/shared/fomio-list-item";
import {
  clearFomioPreferencesMenuMarker,
  FOMIO_PREFERENCES_SECTIONS,
  hasFomioPreferencesMenuMarker,
  isFomioPreferencesPath,
  isFomioPreferencesRootPath,
} from "../../lib/fomio-preferences-sections";
import { fomioCurrentPath } from "../../lib/fomio-router-pathname";
import { subscribeFomioTouchShell } from "../../lib/fomio-subscribe-touch-shell";

export default class FomioMobilePreferencesMenu extends Component {
  @service router;
  @service currentUser;

  @tracked isTouchShell = false;
  #unsubscribeTouch = null;

  constructor(owner, args) {
    super(owner, args);
    this.#unsubscribeTouch = subscribeFomioTouchShell((v) => {
      this.isTouchShell = v;
    });

    // The menu marker is a sticky sessionStorage flag set when the user opens
    // the preferences menu. Clear it as soon as they leave the preferences
    // area so a stale marker can never resurface the menu on other screens.
    this._onRouteDidChange = () => {
      if (!isFomioPreferencesPath(this.currentPath)) {
        clearFomioPreferencesMenuMarker();
      }
    };
    this.router.on("routeDidChange", this._onRouteDidChange);
  }

  willDestroy() {
    this.#unsubscribeTouch?.();
    this.router.off("routeDidChange", this._onRouteDidChange);
    super.willDestroy();
  }

  get currentPath() {
    return fomioCurrentPath(this.router.currentURL || "");
  }

  get hasMenuMarker() {
    return hasFomioPreferencesMenuMarker(this.router.currentURL || "");
  }

  get shouldRender() {
    return Boolean(
      this.currentUser &&
        this.isTouchShell &&
        isFomioPreferencesPath(this.currentPath) &&
        (isFomioPreferencesRootPath(this.currentPath) || this.hasMenuMarker)
    );
  }

  get ariaLabel() {
    return i18n(themePrefix("mobile_preferences_menu.aria_label"));
  }

  get sections() {
    return FOMIO_PREFERENCES_SECTIONS.map((section) => ({
      ...section,
      label: i18n(section.labelKey),
      subtitle: i18n(themePrefix(section.subtitleKey)),
    }));
  }

  @action
  openSection() {
    clearFomioPreferencesMenuMarker();
  }

  <template>
    {{#if this.shouldRender}}
      <nav class="fomio-mobile-preferences-menu" aria-label={{this.ariaLabel}}>
        <FomioList @extraClass="fomio-mobile-preferences-menu__list">
          {{#each this.sections as |section|}}
            <FomioListItem
              @href={{section.href}}
              @leadingIcon={{section.icon}}
              @title={{section.label}}
              @subtitle={{section.subtitle}}
              @trailingIcon="angle-right"
              @extraClass="fomio-mobile-preferences-menu__item"
              {{on "click" this.openSection}}
            />
          {{/each}}
        </FomioList>
      </nav>
    {{/if}}
  </template>
}
