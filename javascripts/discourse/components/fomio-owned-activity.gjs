import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { settings, themePrefix } from "virtual:theme";
import {
  normalizeOwnedActivityPayload,
  ownedActivityRequest,
  parseOwnedActivityRoute,
} from "../lib/fomio-owned-activity";
import { subscribeFomioTouchShell } from "../lib/fomio-subscribe-touch-shell";
import FomioButton from "./shared/fomio-button";
import FomioEmptyState from "./shared/fomio-empty-state";

const READY_CLASS = "fomio-owned-activity-ready";

export default class FomioOwnedActivity extends Component {
  @service currentUser;
  @service router;

  @tracked items = [];
  @tracked isLoading = false;
  @tracked isLoadingMore = false;
  @tracked error = null;
  @tracked loadMoreUrl = null;
  @tracked nextPage = null;
  @tracked isTouchShell = false;
  #unsubscribeTouch = null;

  #routeHandler = () => {
    this.loadInitial();
  };

  constructor() {
    super(...arguments);
    this.router.on?.("routeDidChange", this.#routeHandler);
    this.#unsubscribeTouch = subscribeFomioTouchShell((value) => {
      const changed = this.isTouchShell !== value;
      this.isTouchShell = value;
      // Other-user activity is touch-only; reload when the surface flips.
      if (changed) {
        this.loadInitial();
      }
    });
    this.loadInitial();
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.router.off?.("routeDidChange", this.#routeHandler);
    this.#unsubscribeTouch?.();
    this.#setReady(false);
  }

  get routeState() {
    if (this.args.routeState) {
      return this.args.routeState;
    }

    return parseOwnedActivityRoute(this.router.currentURL, this.currentUser);
  }

  get shouldRender() {
    const routeState = this.routeState;

    if (
      (!this.args.detached && !settings.fomio_owned_me_activity_enabled) ||
      !this.currentUser ||
      !routeState?.isActivity
    ) {
      return false;
    }

    if (this.args.detached) {
      return routeState.isSelf;
    }

    return routeState.isSelf || this.isTouchShell;
  }

  get activeFilter() {
    return this.routeState.filter ?? "all";
  }

  get titleLabel() {
    return i18n(themePrefix("owned_activity.title"));
  }

  get subtitleLabel() {
    return i18n(themePrefix(`owned_activity.subtitle.${this.activeFilter}`));
  }

  get loadingLabel() {
    return i18n(themePrefix("owned_activity.loading"));
  }

  get loadMoreLabel() {
    return i18n(themePrefix("owned_activity.load_more"));
  }

  get emptyTitle() {
    return i18n(themePrefix("owned_activity.empty.title"));
  }

  get emptyBody() {
    return i18n(themePrefix("owned_activity.empty.body"));
  }

  get errorTitle() {
    return i18n(themePrefix("owned_activity.error.title"));
  }

  get errorBody() {
    return i18n(themePrefix("owned_activity.error.body"));
  }

  get retryLabel() {
    return i18n(themePrefix("owned_activity.error.retry"));
  }

  get isInitialLoading() {
    return this.isLoading && !this.items.length;
  }

  get hasItems() {
    return this.items.length > 0;
  }

  get canLoadMore() {
    return Boolean(this.loadMoreUrl || this.nextPage !== null);
  }

  get groupedItems() {
    const groups = [];
    const groupMap = new Map();

    this.items.forEach((item) => {
      const id = this.dayGroupId(item.createdAt);
      let group = groupMap.get(id);

      if (!group) {
        group = {
          id,
          label: this.dayGroupLabel(item.createdAt),
          items: [],
        };
        groupMap.set(id, group);
        groups.push(group);
      }

      group.items.push(item);
    });

    return groups;
  }

  iconFor(item) {
    if (item.type === "like") {
      return "heart";
    }
    if (item.type === "reply") {
      return "reply";
    }
    if (item.type === "read") {
      return "clock";
    }
    return "comment";
  }

  async loadInitial() {
    if (!this.shouldRender) {
      this.#setReady(false);
      return;
    }

    this.isLoading = true;
    this.error = null;
    this.#setReady(false);

    try {
      const payload = await this.#fetchPayload(this.routeState, { page: 0 });
      this.items = payload.items;
      this.loadMoreUrl = payload.loadMoreUrl;
      this.nextPage = payload.nextPage;
      this.#setReady(true);
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error("[Fomio] Activity: failed to load owned activity", error);
      this.items = [];
      this.loadMoreUrl = null;
      this.nextPage = null;
      this.error = error;
      this.#setReady(false);
    } finally {
      this.isLoading = false;
    }
  }

  async #fetchPayload(routeState, options = {}) {
    const request = ownedActivityRequest(routeState, options);

    if (!request) {
      return { items: [], loadMoreUrl: null, nextPage: null };
    }

    const ajaxOptions = request.data ? { data: request.data } : undefined;
    const response = await ajax(request.url, ajaxOptions);
    return normalizeOwnedActivityPayload(response, routeState, options);
  }

  dayGroupId(createdAt) {
    const date = new Date(createdAt);

    if (Number.isNaN(date.getTime())) {
      return "unknown";
    }

    return date.toISOString().slice(0, 10);
  }

  dayGroupLabel(createdAt) {
    const date = new Date(createdAt);

    if (Number.isNaN(date.getTime())) {
      return i18n(themePrefix("owned_activity.sections.older"));
    }

    const today = new Date();
    const todayId = this.dayGroupId(today);
    const yesterday = new Date(today);
    yesterday.setDate(today.getDate() - 1);

    if (this.dayGroupId(date) === todayId) {
      return i18n(themePrefix("owned_activity.sections.today"));
    }

    if (this.dayGroupId(date) === this.dayGroupId(yesterday)) {
      return i18n(themePrefix("owned_activity.sections.yesterday"));
    }

    return date.toLocaleDateString(undefined, {
      month: "short",
      day: "numeric",
      year: date.getFullYear() === today.getFullYear() ? undefined : "numeric",
    });
  }

  #setReady(isReady) {
    document.body?.classList.toggle(READY_CLASS, Boolean(isReady));
  }

  @action
  retry() {
    this.loadInitial();
  }

  @action
  async loadMore() {
    if (!this.canLoadMore || this.isLoadingMore) {
      return;
    }

    this.isLoadingMore = true;

    try {
      const payload = await this.#fetchPayload(this.routeState, {
        loadMoreUrl: this.loadMoreUrl,
        page: this.nextPage ?? 0,
      });
      this.items = [...this.items, ...payload.items];
      this.loadMoreUrl = payload.loadMoreUrl;
      this.nextPage = payload.nextPage;
      this.#setReady(true);
    } catch (error) {
      // Do not unset the owned layer after the initial successful render.
      // eslint-disable-next-line no-console
      console.error("[Fomio] Activity: failed to load more", error);
    } finally {
      this.isLoadingMore = false;
    }
  }

  <template>
    {{#if this.shouldRender}}
      <section
        class="fomio-owned-activity"
        aria-labelledby="fomio-owned-activity-title"
      >
        <header class="fomio-owned-activity__header">
          <h1 id="fomio-owned-activity-title" class="fomio-owned-activity__title">
            {{this.titleLabel}}
          </h1>
          <p class="fomio-owned-activity__subtitle">
            {{this.subtitleLabel}}
          </p>
        </header>

        {{#if this.isInitialLoading}}
          <div class="fomio-owned-activity__loading" role="status">
            <div class="spinner small"></div>
            <span>{{this.loadingLabel}}</span>
          </div>
        {{else if this.error}}
          <FomioEmptyState
            @variant="centered"
            @icon="triangle-exclamation"
            @title={{this.errorTitle}}
            @body={{this.errorBody}}
            @extraClass="fomio-owned-activity__state"
          >
            <FomioButton @variant="secondary" {{on "click" this.retry}}>
              {{this.retryLabel}}
            </FomioButton>
          </FomioEmptyState>
        {{else if this.hasItems}}
          <div class="fomio-owned-activity__timeline">
            {{#each this.groupedItems as |group|}}
              <section class="fomio-owned-activity__group">
                <h2 class="fomio-owned-activity__group-title">
                  {{group.label}}
                </h2>

                <ol class="fomio-owned-activity__list">
                  {{#each group.items as |item|}}
                    <li class="fomio-owned-activity__item">
                      <a class="fomio-owned-activity__card" href={{item.href}}>
                        <span class="fomio-owned-activity__icon" aria-hidden="true">
                          {{icon (this.iconFor item)}}
                        </span>
                        <span class="fomio-owned-activity__body">
                          <span class="fomio-owned-activity__eyebrow">
                            {{item.eyebrow}}
                          </span>
                          <span class="fomio-owned-activity__item-title">
                            {{item.title}}
                          </span>
                          {{#if item.excerpt}}
                            <span class="fomio-owned-activity__excerpt">
                              {{item.excerpt}}
                            </span>
                          {{/if}}
                        </span>
                      </a>
                    </li>
                  {{/each}}
                </ol>
              </section>
            {{/each}}
          </div>

          {{#if this.canLoadMore}}
            <footer class="fomio-owned-activity__footer">
              <FomioButton
                @variant="secondary"
                @isDisabled={{this.isLoadingMore}}
                {{on "click" this.loadMore}}
              >
                {{this.loadMoreLabel}}
              </FomioButton>
            </footer>
          {{/if}}
        {{else}}
          <FomioEmptyState
            @variant="centered"
            @icon="bars-staggered"
            @title={{this.emptyTitle}}
            @body={{this.emptyBody}}
            @extraClass="fomio-owned-activity__state"
          />
        {{/if}}
      </section>
    {{/if}}
  </template>
}
