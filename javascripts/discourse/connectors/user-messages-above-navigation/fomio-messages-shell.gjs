import Component from "@glimmer/component";
import FomioMessagesMasterDetail from "../../components/fomio-messages-master-detail";

/**
 * Injects the Fomio messages shell into the verified `user-messages-above-navigation`
 * outlet rendered by Discourse's `user/messages.gjs` template.
 */
export default class FomioMessagesShell extends Component {
  constructor(owner, args) {
    super(owner, args);
    document.body.classList.add("fomio-messages-mode");
  }

  willDestroy() {
    super.willDestroy(...arguments);
    document.body.classList.remove("fomio-messages-mode");
  }

  <template>
    <div class="fomio-messages-shell-wrapper">
      <FomioMessagesMasterDetail @model={{@outletArgs.model}} />
    </div>
  </template>
}
