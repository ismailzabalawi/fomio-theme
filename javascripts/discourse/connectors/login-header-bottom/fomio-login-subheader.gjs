import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

/** Dek below the login title — pairs with js.login.header_title → "Sign in". */
export default class FomioLoginSubheader extends Component {
  get text() {
    return i18n(themePrefix("auth_login.subheader"));
  }

  <template>
    <p class="fomio-login-subheader">{{this.text}}</p>
  </template>
}
