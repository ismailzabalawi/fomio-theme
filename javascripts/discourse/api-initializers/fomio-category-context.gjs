// Category and subcategory context (Phase 2B).
//
// Core's category heading (components/discovery/navigation.gjs) shows the
// category's name and description only when the category has an uploaded
// logo. Without one, a sighted visitor sees no category identity at all —
// only the sr-only h1 from AccessibleDiscoveryHeading. This fills that gap
// with core's own markup for the logo case, minus the logo:
// .category-heading__content, d-category-badge and
// p.category-heading__description, all styled by core
// (common/base/_topic-list.scss). No heading element: the h1 stays the page's
// only heading. Name and description are the category's own, from Discourse.
import Component from "@glimmer/component";
import { trustHTML } from "@ember/template";
import { apiInitializer } from "discourse/lib/api";
import dCategoryBadge from "discourse/ui-kit/helpers/d-category-badge";

class FomioCategoryContext extends Component {
  get category() {
    return this.args.outletArgs?.category;
  }

  // Same condition as core's headingClasses / logo branch.
  get needsContext() {
    return this.category && !this.category.uploaded_logo?.url;
  }

  <template>
    {{#if this.needsContext}}
      <div class="category-heading__content fomio-category-context">
        {{! No hideParent, as core's own heading: a subcategory's badge marks
          its parent with the split square; the breadcrumb names it. }}
        {{dCategoryBadge this.category allowUncategorized=true}}
        {{#if this.category.description}}
          <p class="category-heading__description">
            {{trustHTML this.category.description}}
          </p>
        {{/if}}
      </div>
    {{/if}}
  </template>
}

export default apiInitializer((api) => {
  api.renderInOutlet("category-heading", FomioCategoryContext);
});
