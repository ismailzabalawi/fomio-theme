import Component from "@glimmer/component";
import { service } from "@ember/service";
import FomioUserProfileSummary from "../../components/shared/fomio-user-profile-summary";
import { fomioCurrentPath } from "../../lib/fomio-router-pathname";
import { shouldRenderInlineProfileIdentity } from "../../lib/fomio-profile-identity-ownership";

export default class FomioUserProfileSummaryConnector extends Component {
  @service router;

  get currentPath() {
    return fomioCurrentPath(this.router.currentURL || "");
  }

  get user() {
    return this.args.outletArgs?.model;
  }

  get shouldRender() {
    return shouldRenderInlineProfileIdentity({
      currentPath: this.currentPath,
      viewedUser: this.user,
    });
  }

  get summaryHref() {
    if (!this.user?.username) {
      return null;
    }

    if (/^\/u\/[^/]+\/summary\/?$/.test(this.currentPath)) {
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
