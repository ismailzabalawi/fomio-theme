import Component from "@glimmer/component";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import FomioPhIcon from "../../components/shared/fomio-ph-icon";

const LABEL_KEYS_BY_ACTION_TYPE = {
  1: "liked",
  2: "liked",
  4: "created_byte",
  5: "replied",
  6: "replied",
  7: "replied",
  9: "replied",
};

const ICONS_BY_ACTION_KEY = {
  created_byte: "fomio-ph-note-pencil",
  replied: "fomio-ph-arrow-bend-up-left",
  liked: "fomio-ph-heart",
};

function valueFor(object, key) {
  if (!object) {
    return null;
  }

  if (typeof object.get === "function") {
    return object.get(key);
  }

  return object[key];
}

export default class FomioActivityActionLabel extends Component {
  @service router;

  get item() {
    return this.args.outletArgs?.item;
  }

  get shouldRender() {
    return (
      this.router.currentRouteName?.startsWith("userActivity") &&
      Boolean(this.label)
    );
  }

  get actionKey() {
    return LABEL_KEYS_BY_ACTION_TYPE[valueFor(this.item, "action_type")];
  }

  get label() {
    if (!this.actionKey) {
      return null;
    }

    return i18n(themePrefix(`activity_screen.actions.${this.actionKey}`));
  }

  get icon() {
    return ICONS_BY_ACTION_KEY[this.actionKey] || "fomio-ph-rows";
  }

  get teretName() {
    return valueFor(valueFor(this.item, "category"), "name");
  }

  <template>
    {{#if this.shouldRender}}
      <span
        class="fomio-activity-action-label"
        data-fomio-activity-action={{this.actionKey}}
      >
        <span class="fomio-activity-action-label__icon" aria-hidden="true">
          <FomioPhIcon @name={{this.icon}} @size={{15}} />
        </span>

        <span class="fomio-activity-action-label__text">{{this.label}}</span>

        {{#if this.teretName}}
          <span class="fomio-activity-action-label__teret">
            {{this.teretName}}
          </span>
        {{/if}}
      </span>
    {{/if}}
  </template>
}
