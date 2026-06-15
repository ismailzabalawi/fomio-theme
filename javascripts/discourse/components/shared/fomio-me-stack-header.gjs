import Component from "@glimmer/component";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

/**
 * Me Stack Header — touch-only back nav bar for Me leaf pages.
 *
 * Renders: [‹ Me]  [Section Title]
 *
 * @arg {string} backHref   - URL to navigate back to (Me Hub landing)
 * @arg {string|null} sectionTitle - Localised section name (Activity, Preferences…)
 * @arg {(() => void)|null} onBackClick - Optional: run before following backHref (e.g. arm hub landing)
 */
export default class FomioMeStackHeader extends Component {
  get backLabel() {
    return i18n(themePrefix("me_stack.back"));
  }

  get preferencesLabel() {
    return i18n(themePrefix("me_stack.preferences_menu"));
  }

  @action
  handleBackClick(e) {
    this.args.onBackClick?.(e);
  }

  @action
  handlePreferencesClick(e) {
    this.args.onPreferencesClick?.(e);
  }

  <template>
    <div class="fomio-me-stack-header fomio-masthead fomio-masthead--mobile" aria-label={{@sectionTitle}}>
      <a
        href={{@backHref}}
        class="fomio-me-stack-header__back fomio-masthead__icon-btn"
        aria-label={{this.backLabel}}
        {{on "click" this.handleBackClick}}
      >
        {{icon "chevron-left"}}
        <span class="fomio-me-stack-header__back-label">{{this.backLabel}}</span>
      </a>
      {{#if @sectionTitle}}
        <span class="fomio-me-stack-header__title fomio-masthead__brand">
          {{@sectionTitle}}
        </span>
      {{/if}}
      {{#if @onPreferencesClick}}
        <button
          type="button"
          class="fomio-me-stack-header__prefs fomio-masthead__icon-btn"
          aria-label={{this.preferencesLabel}}
          title={{this.preferencesLabel}}
          {{on "click" this.handlePreferencesClick}}
        >
          {{icon "gear"}}
        </button>
      {{else}}
        {{! Grid column 3 spacer — mirrors the back button width so title stays centred }}
        <span aria-hidden="true"></span>
      {{/if}}
    </div>
  </template>
}
