// "Top terets" bar-chart for the profile Summary surface, rendered through
// Discourse's `below-user-summary-stats` outlet (outletArgs: { model, user }).
// Mirrors the prototype's SummarySection "Top terets" block: a teret tag, a
// relative activity bar (topics + replies, scaled to the busiest teret), and a
// count. Display-only over model.top_categories — replaces the native count
// table (hidden via common.scss). No fetch.
import Component from "@glimmer/component";
import { htmlSafe } from "@ember/template";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import { profileTopTerets } from "../../lib/fomio-profile-summary-fields";

export default class FomioTopTerets extends Component {
  get terets() {
    return profileTopTerets(this.args.outletArgs?.model);
  }

  barStyle = (teret) => {
    const color = teret.color || "var(--fomio-primary)";
    return htmlSafe(`width:${teret.pct}%;background:${color}`);
  };

  tagStyle = (teret) => {
    const color = teret.color || "var(--fomio-primary)";
    return htmlSafe(
      `color:${color};background:color-mix(in oklab, ${color} 14%, transparent)`
    );
  };

  <template>
    {{#if this.terets.length}}
      <section
        class="fomio-top-terets"
        aria-label={{i18n (themePrefix "summary_terets.title")}}
      >
        <h3 class="fomio-top-terets__title">
          {{i18n (themePrefix "summary_terets.title")}}
        </h3>
        <div class="fomio-top-terets__list">
          {{#each this.terets as |teret|}}
            <div class="fomio-top-terets__row">
              <span
                class="fomio-top-terets__tag"
                style={{this.tagStyle teret}}
              >{{teret.name}}</span>
              <span class="fomio-top-terets__track">
                <span
                  class="fomio-top-terets__bar"
                  style={{this.barStyle teret}}
                ></span>
              </span>
              <span class="fomio-top-terets__count">{{teret.count}}</span>
            </div>
          {{/each}}
        </div>
      </section>
    {{/if}}
  </template>
}
