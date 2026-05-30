import Component from "@glimmer/component";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import DiscourseURL from "discourse/lib/url";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import { eq } from "truth-helpers";

// ── Query operator helpers ──────────────────────────────────────────────────

function stripOp(q, key) {
  return q.replace(new RegExp("\\b" + key + ":\\S*", "g"), "").replace(/\s+/g, " ").trim();
}

function hasOp(q, prefix) {
  return new RegExp("(^|\\s)" + prefix + ":").test(q);
}

function opValue(q, prefix) {
  const m = q.match(new RegExp("(?:^|\\s)" + prefix + ":(\\S+)"));
  return m ? m[1] : null;
}

function setOp(q, key, value) {
  const base = stripOp(q, key);
  return value ? (base ? base + " " + key + ":" + value : key + ":" + value) : base;
}

function navigate(q) {
  DiscourseURL.routeTo("/search?q=" + encodeURIComponent(q));
}

const SORT_OPTIONS = [
  { id: "latest", label: "Latest" },
  { id: "views", label: "Views" },
  { id: "likes", label: "Likes" },
];

export default class FomioSearchFilterChips extends Component {
  sortOptions = SORT_OPTIONS;

  get q() {
    return this.args.outletArgs?.search ?? "";
  }

  get hasQuery() {
    return Boolean(this.q.trim());
  }

  get currentOrder() {
    return opValue(this.q, "order");
  }

  get inTitle() {
    return hasOp(this.q, "in") && opValue(this.q, "in") === "title";
  }

  get hasReplies() {
    return hasOp(this.q, "min_replies");
  }

  get resultCount() {
    const gsr = this.args.outletArgs?.model?.grouped_search_result;
    return gsr?.result_count ?? null;
  }

  @action
  setOrder(orderId) {
    navigate(setOp(this.q, "order", orderId || null));
  }

  @action
  toggleInTitle() {
    const base = stripOp(this.q, "in");
    navigate(this.inTitle ? base : setOp(this.q, "in", "title"));
  }

  @action
  toggleHasReplies() {
    navigate(
      this.hasReplies
        ? stripOp(this.q, "min_replies")
        : setOp(this.q, "min_replies", "1")
    );
  }

  <template>
    {{#if this.hasQuery}}
      <div class="fomio-search-chips-bar">
        <div class="fomio-search-chips">

          <span class="fomio-search-chip-label">
            {{i18n (themePrefix "search_page.filter_sort")}}
          </span>

          {{#each this.sortOptions as |opt|}}
            <button
              type="button"
              class="fomio-search-chip {{if (eq this.currentOrder opt.id) 'fomio-search-chip--on'}}"
              {{on "click" (fn this.setOrder opt.id)}}
            >
              {{opt.label}}
            </button>
          {{/each}}

          <span class="fomio-search-chip-divider" aria-hidden="true"></span>

          <button
            type="button"
            class="fomio-search-chip {{if this.inTitle 'fomio-search-chip--on'}}"
            {{on "click" this.toggleInTitle}}
          >
            {{icon "text-height"}}
            {{i18n (themePrefix "search_page.filter_title_only")}}
          </button>

          <button
            type="button"
            class="fomio-search-chip {{if this.hasReplies 'fomio-search-chip--on'}}"
            {{on "click" this.toggleHasReplies}}
          >
            {{icon "comment"}}
            {{i18n (themePrefix "search_page.filter_has_replies")}}
          </button>

        </div>

        {{#if this.resultCount}}
          <span class="fomio-search-result-count">
            <strong>{{this.resultCount}}</strong>
            {{i18n (themePrefix "search_page.results_suffix")}}
          </span>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
