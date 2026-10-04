// Visitor empty list (Phase 4.5: no bare "Nothing here").
//
// Core only renders an empty-list state for a signed-in member
// (components/discovery/topics.gjs, showEmptyFilterEducationInFooter checks
// currentUser). A visitor on a list with nothing they can see — Off-topic
// Discussions, whose only topic is unlisted (docs/07) — gets the context
// header and then nothing. This renders core's own empty state for them:
// DEmptyState with core's `empty-topic-filter` identifier, picture and
// generic text, so it looks exactly like a member's (and gets the theme's
// phone cap). It sits after core's footer content in the `topic-list-bottom`
// wrapper outlet, which core renders only once the list is fully loaded.
//
// The ways out are Discourse's existing lists, never invented suggestions:
// Latest, then Categories and Hot, dropping the list the visitor is already
// on. Every label is a core string, so the site's text overrides apply.
import Component from "@glimmer/component";
import { service } from "@ember/service";
import SvgDocumentsCheckmark from "discourse/components/svg/documents-checkmark";
import { apiInitializer } from "discourse/lib/api";
import { filterTypeForMode } from "discourse/lib/filter-mode";
import getURL from "discourse/lib/get-url";
import DEmptyState from "discourse/ui-kit/d-empty-state";
import { i18n } from "discourse-i18n";

class FomioVisitorEmptyList extends Component {
  @service currentUser;

  // Core's condition, minus the signed-in requirement. `allLoaded` is
  // already true inside this outlet.
  get show() {
    const model = this.args.outletArgs?.model;
    return (
      !this.currentUser &&
      model &&
      !model.get("more_topics_url") &&
      !(model.get("topics.length") > 0)
    );
  }

  // Which site-wide list is showing, if any. A category or tag list is
  // never one of the destinations below, so all of them apply there.
  get siteWideFilter() {
    const { category, tag, model } = this.args.outletArgs;
    return category || tag ? null : filterTypeForMode(model.get("filter"));
  }

  get destinations() {
    const current = this.siteWideFilter;
    const all = [
      {
        filter: "latest",
        route: "discovery.latest",
        path: "/latest",
        label: i18n("topic.browse_latest_topics"),
      },
      {
        filter: "categories",
        route: "discovery.categories",
        path: "/categories",
        label: i18n("filters.categories.title"),
      },
      {
        filter: "hot",
        route: "discovery.hot",
        path: "/hot",
        label: i18n("filters.hot.title"),
      },
    ];
    // Hot only ranks topics Latest would list, so from an empty site-wide
    // Latest it would be empty too.
    return all.filter(
      (d) =>
        d.filter !== current && !(current === "latest" && d.filter === "hot")
    );
  }

  get cta() {
    return this.destinations[0];
  }

  get links() {
    return this.destinations
      .slice(1)
      .map((d) => ({ ...d, href: getURL(d.path) }));
  }

  // DEmptyState renders its tip whenever a tip block is passed, so pass one
  // only when there are links for it.
  <template>
    {{#if this.show}}
      {{#if this.links.length}}
        <DEmptyState
          @identifier="empty-topic-filter"
          @title={{i18n "topics.none.education.generic"}}
          @ctaLabel={{this.cta.label}}
          @ctaRoute={{this.cta.route}}
          @svgContent={{SvgDocumentsCheckmark}}
        >
          <:tip>
            {{#each this.links as |link|}}
              <a href={{link.href}} class="fomio-visitor-empty-list__link">
                {{link.label}}
              </a>
            {{/each}}
          </:tip>
        </DEmptyState>
      {{else}}
        <DEmptyState
          @identifier="empty-topic-filter"
          @title={{i18n "topics.none.education.generic"}}
          @ctaLabel={{this.cta.label}}
          @ctaRoute={{this.cta.route}}
          @svgContent={{SvgDocumentsCheckmark}}
        />
      {{/if}}
    {{/if}}
  </template>
}

export default apiInitializer((api) => {
  api.renderAfterWrapperOutlet("topic-list-bottom", FomioVisitorEmptyList);
});
