import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import FomioUserProfileSummary from "../../components/shared/fomio-user-profile-summary";
import { isAuthPath } from "../../lib/fomio-mobile-nav-paths";
import { subscribeFomioTouchShell } from "../../lib/fomio-subscribe-touch-shell";

export default class FomioUserProfileSummaryConnector extends Component {
  @service router;

  @tracked isTouchShell = false;
  #unsubscribeTouch = null;

  constructor(owner, args) {
    super(owner, args);
    this.#unsubscribeTouch = subscribeFomioTouchShell((value) => {
      this.isTouchShell = value;
    });
  }

  willDestroy() {
    this.#unsubscribeTouch?.();
    super.willDestroy();
  }

  get currentPath() {
    return (this.router.currentURL || "").split("?")[0];
  }

  get user() {
    return this.args.outletArgs?.model;
  }

  get shouldRender() {
    return (
      !this.isTouchShell &&
      !isAuthPath(this.currentPath) &&
      Boolean(this.user?.username)
    );
  }

  get summaryHref() {
    if (!this.user?.username) {
      return null;
    }

    if (/^\/u\/[^/]+\/summary\/?$/.test(this.currentPath) || this.currentPath === "/my" || this.currentPath === "/my/summary") {
      return null;
    }

    return `/u/${this.user.username}/summary`;
  }

  <template>
    {{#if this.shouldRender}}
      <FomioUserProfileSummary
        @user={{this.user}}
        @href={{this.summaryHref}}
      />
    {{/if}}
  </template>
}
