import Component from "@glimmer/component";
import { htmlSafe } from "@ember/template";
import formatDate from "discourse/helpers/format-date";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

export default class FomioActivityTopicRow extends Component {
  get topic() {
    return this.args.topic;
  }

  get titleHtml() {
    const t = this.topic;
    return htmlSafe(t?.fancy_title ?? t?.fancyTitle ?? t?.title ?? "");
  }

  get url() {
    const t = this.topic;
    if (t?.linked_post_number) {
      return t.urlForPostNumber(t.linked_post_number);
    }
    return t?.lastUnreadUrl ?? t?.url ?? null;
  }

  get teret() {
    return this.topic?.category?.name ?? null;
  }

  get teretStyle() {
    const color = this.topic?.category?.color;
    if (!color) return null;
    return htmlSafe(
      `color:#${color};background:color-mix(in oklab, #${color} 13%, transparent)`
    );
  }

  get replyCount() {
    const t = this.topic;
    return t?.reply_count ?? t?.replyCount ?? 0;
  }

  get createdAt() {
    return this.topic?.created_at ?? null;
  }

  get replyAriaLabel() {
    return `${this.replyCount} ${i18n(themePrefix("activity_topics.replies"))}`;
  }

  <template>
    <article class="fomio-atr">
      <a href={{this.url}} class="fomio-atr__link">
        <span class="fomio-atr__body">
          <span class="fomio-atr__title">{{this.titleHtml}}</span>
          <span class="fomio-atr__meta">
            {{#if this.teret}}
              <span class="fomio-atr__teret" style={{this.teretStyle}}>{{this.teret}}</span>
              <span class="fomio-atr__sep" aria-hidden="true">·</span>
            {{/if}}
            {{#if this.createdAt}}
              <span class="fomio-atr__age">
                {{formatDate this.createdAt format="tiny" noTitle="true"}}
              </span>
            {{/if}}
          </span>
        </span>
        <span class="fomio-atr__stats" aria-label={{this.replyAriaLabel}}>
          <span class="fomio-atr__stat-icon" aria-hidden="true">
            {{icon "comment"}}
          </span>
          <span class="fomio-atr__stat-count">{{this.replyCount}}</span>
        </span>
      </a>
    </article>
  </template>
}
