import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import { isAuthPath, isDiscoverPath } from "../../lib/fomio-mobile-nav-paths";
import { subscribeFomioTouchShell } from "../../lib/fomio-subscribe-touch-shell";

export default class FomioDiscoverPills extends Component {
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
      !isAuthPath(this.currentPath) &&
      isDiscoverPath(this.currentPath)
    );
  }

  get isHubsActive() {
    const p = this.currentPath;
    return p === "/categories" || p.startsWith("/c/");
  }

  get isTrendingActive() {
    return this.currentPath.startsWith("/top");
  }

  get discoverPillsAriaLabel() {
    return i18n(themePrefix("mobile_nav.discover_pills_aria"));
  }

  get hubsLabel() {
    return i18n(themePrefix("mobile_nav.pill_hubs"));
  }

  get trendingLabel() {
    return i18n(themePrefix("mobile_nav.pill_trending"));
  }

  <template>
    {{#if this.shouldRender}}
      <nav
        class="fomio-context-pills fomio-context-pills--discover"
        aria-label={{this.discoverPillsAriaLabel}}
      >
        <div class="fomio-context-pills__scroller">
          <a
            href="/categories"
            class="fomio-context-pills__item {{if this.isHubsActive 'is-active'}}"
            aria-current={{if this.isHubsActive "page"}}
          >
            {{this.hubsLabel}}
          </a>
          <a
            href="/top"
            class="fomio-context-pills__item {{if this.isTrendingActive 'is-active'}}"
            aria-current={{if this.isTrendingActive "page"}}
          >
            {{this.trendingLabel}}
          </a>
        </div>
      </nav>
    {{/if}}
  </template>
}
