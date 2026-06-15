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
  isFomioPreferencesRootPath,
} from "../../lib/fomio-preferences-sections";
import { isFomioShellPath } from "../../lib/fomio-mobile-nav-paths";
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
  }

  willDestroy() {
    this.#unsubscribeTouch?.();
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
        isFomioShellPath(this.currentPath) &&
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
