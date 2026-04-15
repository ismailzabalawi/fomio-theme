import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

/** Eyebrow + dek — Stitch Screen 3. Wrapper uses display:contents via SCSS for flex order. */
export default class FomioSignupSubheader extends Component {
  get eyebrowText() {
    return i18n(themePrefix("auth_signup.eyebrow"));
  }

  get subheaderText() {
    return i18n(themePrefix("auth_signup.subheader"));
  }

  <template>
    <div class="fomio-signup-header-stack">
      <p class="fomio-signup-eyebrow">{{this.eyebrowText}}</p>
      <p class="fomio-signup-subheader">{{this.subheaderText}}</p>
    </div>
  </template>
}
