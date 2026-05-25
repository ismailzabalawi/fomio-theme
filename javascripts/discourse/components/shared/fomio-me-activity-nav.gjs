import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

export default class FomioMeActivityNav extends Component {
  get groupAriaLabel() {
    return this.args.ariaLabel || i18n(themePrefix("me_activity_nav.nav_aria"));
  }

  sectionClass = (isActive) => {
    const base = "fomio-me-activity-nav__link";
    return isActive ? `${base} is-active` : base;
  };

  <template>
    <nav class="fomio-me-activity-nav" aria-label={{this.groupAriaLabel}}>
      <div class="fomio-me-activity-nav__inner">
        {{#each @sections as |section|}}
          <a
            href={{section.href}}
            class={{this.sectionClass section.isActive}}
            aria-current={{if section.isActive "page"}}
            data-activity-key={{section.key}}
          >
            <span class="fomio-me-activity-nav__label">{{section.label}}</span>
          </a>
        {{/each}}
      </div>
    </nav>
  </template>
}
