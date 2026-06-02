import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import {
  isFomioShellPath,
  isHomeFeedPath,
} from "../../lib/fomio-mobile-nav-paths";
import { subscribeFomioTouchShell } from "../../lib/fomio-subscribe-touch-shell";

export default class FomioHomePills extends Component {
  @service router;

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
    return (this.router.currentURL || "").split("?")[0];
  }

  get shouldRender() {
    return (
      this.isTouchShell &&
      isFomioShellPath(this.currentPath) &&
      isHomeFeedPath(this.currentPath)
    );
  }

  get isLatestActive() {
    const p = this.currentPath;
    return p === "/" || p.startsWith("/latest");
  }

  get isHotActive() {
    return this.currentPath.startsWith("/hot");
  }

  get isUnreadActive() {
    return this.currentPath.startsWith("/unread");
  }

  get homePillsAriaLabel() {
    return i18n(themePrefix("mobile_nav.home_pills_aria"));
  }

  get hotLabel() {
    return i18n(themePrefix("mobile_nav.pill_hot"));
  }

  get latestLabel() {
    return i18n(themePrefix("mobile_nav.pill_latest"));
  }

  get unreadLabel() {
    return i18n(themePrefix("mobile_nav.pill_unread"));
  }

  <template>
    {{#if this.shouldRender}}
      <nav
        class="fomio-context-pills fomio-context-pills--home"
        aria-label={{this.homePillsAriaLabel}}
      >
        <div class="fomio-context-pills__scroller">
          <a
            href="/hot"
            class="fomio-context-pills__item {{if this.isHotActive 'is-active'}}"
            aria-current={{if this.isHotActive "page"}}
          >
            {{this.hotLabel}}
          </a>
          <a
            href="/latest"
            class="fomio-context-pills__item {{if this.isLatestActive 'is-active'}}"
            aria-current={{if this.isLatestActive "page"}}
          >
            {{this.latestLabel}}
          </a>
          <a
            href="/unread"
            class="fomio-context-pills__item {{if this.isUnreadActive 'is-active'}}"
            aria-current={{if this.isUnreadActive "page"}}
          >
            {{this.unreadLabel}}
          </a>
        </div>
      </nav>
    {{/if}}
  </template>
}
