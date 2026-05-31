import Component from "@glimmer/component";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import { service } from "@ember/service";
import DiscourseURL from "discourse/lib/url";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";
import { eq } from "truth-helpers";

const SEARCH_TYPE_DEFAULT = "topics_posts";
const SEARCH_TYPE_CATS_TAGS = "categories_tags";
const SEARCH_TYPE_USERS = "users";

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
  const params = new URLSearchParams(window.location.search);

  if (q?.trim()) {
    params.set("q", q.trim());
  } else {
    params.delete("q");
  }

  const queryString = params.toString();
  DiscourseURL.routeTo(queryString ? `/search?${queryString}` : "/search");
}

const SORT_OPTIONS = [
  { id: 0, term: null, label: "search.relevance" },
  { id: 1, term: "latest", label: "search.latest_post" },
  { id: 2, term: "likes", label: "search.most_liked" },
  { id: 3, term: "views", label: "search.most_viewed" },
  { id: 4, term: "latest_topic", label: "search.latest_topic" },
  { id: 5, term: "read", label: "search.last_read", requiresLogin: true },
];

export default class FomioSearchFilterChips extends Component {
  @service currentUser;
  @service siteSettings;

  get sortOptions() {
    return SORT_OPTIONS.filter(
      (option) => !option.requiresLogin || this.currentUser
    );
  }

  get q() {
    return this.args.outletArgs?.search ?? "";
  }

  get hasQuery() {
    return Boolean(this.q.trim());
  }

  get searchType() {
    return this.args.outletArgs?.type ?? SEARCH_TYPE_DEFAULT;
  }

  get usingDefaultSearchType() {
    return this.searchType === SEARCH_TYPE_DEFAULT;
  }

  get currentSortOrder() {
    return this.args.outletArgs?.sortOrder ?? 0;
  }

  get inTitle() {
    return hasOp(this.q, "in") && opValue(this.q, "in") === "title";
  }

  get hasReplies() {
    return hasOp(this.q, "min_replies");
  }

  get resultCount() {
    const model = this.args.outletArgs?.model;
    const gsr = this.args.outletArgs?.model?.grouped_search_result;

    if (this.searchType === SEARCH_TYPE_CATS_TAGS) {
      return (model?.categories?.length ?? 0) + (model?.tags?.length ?? 0);
    }

    if (this.searchType === SEARCH_TYPE_USERS) {
      return model?.users?.length ?? 0;
    }

    return gsr?.result_count ?? 0;
  }

  get typeLabel() {
    switch (this.searchType) {
      case SEARCH_TYPE_CATS_TAGS:
        return this.siteSettings.tagging_enabled
          ? i18n("search.type.categories_and_tags")
          : i18n("search.type.categories");
      case SEARCH_TYPE_USERS:
        return i18n("search.type.users");
      default:
        return i18n("search.type.default");
    }
  }

  @action
  setOrder(option) {
    navigate(setOp(this.q, "order", option.term));
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
        <div class="fomio-search-result-meta">
          <span class="fomio-search-result-count">
            <strong>{{this.resultCount}}</strong>
            {{i18n (themePrefix "search_page.results_suffix")}}
          </span>
          <span class="fomio-search-result-scope">{{this.typeLabel}}</span>
        </div>

        {{#if this.usingDefaultSearchType}}
          <div class="fomio-search-chips">
            <span class="fomio-search-chip-label">
              {{i18n (themePrefix "search_page.filter_sort")}}
            </span>

            {{#each this.sortOptions as |opt|}}
              <button
                type="button"
                class="fomio-search-chip {{if (eq this.currentSortOrder opt.id) 'fomio-search-chip--on'}}"
                {{on "click" (fn this.setOrder opt)}}
              >
                {{i18n opt.label}}
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
        {{/if}}
      </div>
    {{/if}}
  </template>
}
