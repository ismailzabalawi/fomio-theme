import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import { subscribeMessagesState } from "../lib/fomio-messages-state";
import FomioMessagesMaster from "./fomio-messages-master";
import FomioMessagesDetail from "./fomio-messages-detail";

/**
 * Fomio Messages Master-Detail Shell
 *
 * This component coordinates the entire messages interface:
 * - Left pane: conversation list (master)
 * - Right pane: message thread detail (detail)
 * - Responsive grid adapts to surface mode (expanded, compact, rail, touch)
 *
 * Phase 2: Render the master and detail panes.
 * Phase 2.5: Add pagination, real-time updates, and edge-case handling.
 */

export default class FomioMessagesMasterDetail extends Component {
  @service router;
  @tracked selectedTopicId = null;

  #unsubscribeMessages = null;

  constructor(owner, args) {
    super(owner, args);

    this.#unsubscribeMessages = subscribeMessagesState((state) => {
      this.selectedTopicId = state.selectedTopicId;
    });
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.#unsubscribeMessages?.();
  }

  get hasSelection() {
    return Boolean(this.selectedTopicId);
  }

  <template>
    <div
      class="fomio-messages-master-detail {{if this.hasSelection 'fomio-messages-master-detail--conversation-open'}}"
    >
      <div class="fomio-messages-master">
        <FomioMessagesMaster />
      </div>

      <div class="fomio-messages-detail">
        <FomioMessagesDetail />
      </div>
    </div>
  </template>
}
