import Component from "@glimmer/component";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

/**
 * Connector: before-composer-fields
 *
 * Refinement banner shown above the title on the full-page Edit surface
 * ("Editing your byte · readers will see an edited indicator"). Renders only
 * when editing an existing post. Coexists with fomio-fullscreen-composer-fields
 * in the same outlet; their render guards are mutually exclusive in practice.
 */
export default class FomioComposerEditBanner extends Component {
  get model() {
    return this.args.outletArgs?.model;
  }

  get shouldRender() {
    return Boolean(this.model?.editingPost);
  }

  <template>
    {{#if this.shouldRender}}
      <div class="fomio-composer-edit-banner">
        <span class="fomio-composer-edit-banner__icon" aria-hidden="true">
          {{icon "pen-to-square"}}
        </span>
        <span class="fomio-composer-edit-banner__text">
          <b>{{i18n (themePrefix "composer.edit_banner_title")}}</b>
          <span>{{i18n (themePrefix "composer.edit_banner_subtitle")}}</span>
        </span>
      </div>
    {{/if}}
  </template>
}
