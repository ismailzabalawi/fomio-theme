// Editorial hero for the profile Summary detail surface, rendered through
// Discourse's `above-user-summary-stats` outlet (outletArgs: { model, user }).
// Display-only: eyebrow + serif display title + deck line, with a quiet
// "On Fomio since" pill derived from the user's join date.
import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

export default class FomioSummaryHero extends Component {
  get user() {
    return this.args.outletArgs?.user;
  }

  get displayName() {
    const user = this.user;
    return (user?.name && String(user.name).trim()) || user?.username || "";
  }

  get joinedLabel() {
    const createdAt = this.user?.created_at;
    if (!createdAt) {
      return null;
    }

    const date = new Date(createdAt);
    if (Number.isNaN(date.getTime())) {
      return null;
    }

    const formatted = new Intl.DateTimeFormat(undefined, {
      month: "long",
      year: "numeric",
    }).format(date);

    return i18n(themePrefix("summary_page.joined"), { date: formatted });
  }

  <template>
    <header class="fomio-summary-hero">
      <span class="fomio-summary-hero__eyebrow">
        {{i18n (themePrefix "summary_page.eyebrow")}}
      </span>
      <h2 class="fomio-summary-hero__title">
        {{i18n (themePrefix "summary_page.title")}}
      </h2>
      {{#if this.displayName}}
        <p class="fomio-summary-hero__deck">
          {{i18n (themePrefix "summary_page.deck") name=this.displayName}}
        </p>
      {{/if}}
      {{#if this.joinedLabel}}
        <span class="fomio-summary-hero__joined">{{this.joinedLabel}}</span>
      {{/if}}
    </header>
  </template>
}
