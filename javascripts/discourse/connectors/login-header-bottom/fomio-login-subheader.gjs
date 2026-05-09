import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import { peekAuthIntent } from "../../lib/fomio-auth-intent";

/** Dek below the login title — pairs with js.login.header_title → "Sign in". */
export default class FomioLoginSubheader extends Component {
  _intent = null;

  constructor(owner, args) {
    super(owner, args);
    this._intent = peekAuthIntent();
  }

  get text() {
    return i18n(themePrefix("auth_login.subheader"));
  }

  get intentMessage() {
    switch (this._intent) {
      case "create_byte":
        return i18n(themePrefix("auth_intent.create_byte"));
      case "join_discussion":
        return i18n(themePrefix("auth_intent.join_discussion"));
      case "save_interact_bytes":
        return i18n(themePrefix("auth_intent.save_interact_bytes"));
      case "view_saved":
        return i18n(themePrefix("auth_intent.view_saved"));
      case "view_profile":
        return i18n(themePrefix("auth_intent.view_profile"));
      default:
        return null;
    }
  }

  <template>
    {{#if this.intentMessage}}
      <p class="fomio-auth-intent">{{this.intentMessage}}</p>
    {{/if}}
    <p class="fomio-login-subheader">{{this.text}}</p>
  </template>
}
