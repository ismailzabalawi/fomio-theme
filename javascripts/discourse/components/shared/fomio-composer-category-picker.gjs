import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";
import icon from "discourse/helpers/d-icon";
import FomioList from "./fomio-list";
import FomioListItem from "./fomio-list-item";
import FomioListSectionHeader from "./fomio-list-section-header";
import FomioListSeparator from "./fomio-list-separator";
import { eq } from "discourse/truth-helpers";
import { themePrefix } from "virtual:theme";

function normalizeSearchTerm(value) {
  return (value ?? "").trim().toLowerCase();
}

export default class FomioComposerCategoryPicker extends Component {
  @service composer;

  @tracked isOpen = false;
  @tracked searchTerm = "";

  get selectedCategory() {
    return this.categories.find((category) => category.id === this.args.value) ?? null;
  }

  get categories() {
    const categories = this.composer.categories ?? [];
    const scopedCategoryId = this.args.scopedCategoryId;
    const readOnlyCategoryId = this.args.readOnlyCategoryId;

    let filtered = categories.filter((category) => {
      if (category.parent_category_id && category.parentCategory?.parent_category_id) {
        return false;
      }

      if (scopedCategoryId) {
        return (
          category.id === scopedCategoryId ||
          category.parent_category_id === scopedCategoryId
        );
      }

      if (readOnlyCategoryId) {
        return category.id === readOnlyCategoryId;
      }

      return category.canCreateTopic;
    });

    if (readOnlyCategoryId) {
      filtered = filtered.map((category) =>
        category.id === readOnlyCategoryId
          ? category
          : category
      );
    }

    return filtered.sort((left, right) => {
      const prioritizedCategoryId = this.args.prioritizedCategoryId;
      const leftPriority = this.priorityFor(left, prioritizedCategoryId);
      const rightPriority = this.priorityFor(right, prioritizedCategoryId);

      if (leftPriority !== rightPriority) {
        return leftPriority - rightPriority;
      }

      if (left.parent_category_id !== right.parent_category_id) {
        if (!left.parent_category_id) {
          return -1;
        }

        if (!right.parent_category_id) {
          return 1;
        }
      }

      return left.name.localeCompare(right.name);
    });
  }

  get filteredCategories() {
    const term = normalizeSearchTerm(this.searchTerm);

    if (!term) {
      return this.categoryEntries;
    }

    return this.categoryEntries.filter(({ category }) => {
      const haystacks = [
        category.name,
        category.slug,
        category.description_text,
        category.parentCategory?.name,
      ]
        .filter(Boolean)
        .map((value) => value.toLowerCase());

      return haystacks.some((value) => value.includes(term));
    });
  }

  get categoryEntries() {
    return this.categories.map((category) => ({
      category,
      description: this.categoryDescription(category),
      meta: this.categoryMeta(category),
      swatchStyle: this.swatchStyle(category),
      isDisabled: this.isItemDisabled(category),
    }));
  }

  get selectedLabel() {
    return this.selectedCategory?.name ?? i18n(themePrefix("composer.category_placeholder"));
  }

  get selectedDescription() {
    return this.selectedCategory?.description_text ?? null;
  }

  get listLabel() {
    return i18n(themePrefix("composer.category_list_label"));
  }

  get isDisabled() {
    return Boolean(this.args.disabled || this.args.readOnlyCategoryId);
  }

  get selectedSwatchStyle() {
    return this.swatchStyle(this.selectedCategory);
  }

  get buttonClass() {
    const classes = ["fomio-composer-category-picker__trigger"];

    if (this.isOpen) {
      classes.push("is-open");
    }

    if (!this.selectedCategory) {
      classes.push("is-empty");
    }

    return classes.join(" ");
  }

  priorityFor(category, prioritizedCategoryId) {
    if (category.id === this.args.value) {
      return 0;
    }

    if (prioritizedCategoryId && category.id === prioritizedCategoryId) {
      return 1;
    }

    if (!category.parent_category_id) {
      return 2;
    }

    return 3;
  }

  categoryDescription(category) {
    return category.description_text || category.parentCategory?.name || null;
  }

  categoryMeta(category) {
    if (category.parentCategory?.name) {
      return category.parentCategory.name;
    }

    if (typeof category.topic_count === "number") {
      return `× ${category.topic_count}`;
    }

    return null;
  }

  swatchStyle(category) {
    const color = category?.color ?? "D5D1CA";
    const textColor = category?.text_color ?? "6B6B72";
    return `background-color:#${color};color:#${textColor}`;
  }

  isItemDisabled(category) {
    return Boolean(
      this.args.readOnlyCategoryId && category.id !== this.args.readOnlyCategoryId
    );
  }

  @action
  togglePicker() {
    if (this.isDisabled) {
      return;
    }

    this.isOpen = !this.isOpen;

    if (!this.isOpen) {
      this.searchTerm = "";
    }
  }

  @action
  closePicker() {
    this.isOpen = false;
    this.searchTerm = "";
  }

  @action
  handleKeydown(event) {
    if (event.key === "Escape") {
      event.preventDefault();
      this.closePicker();
    }
  }

  @action
  handleFocusOut(event) {
    const nextFocused = event.relatedTarget;

    if (nextFocused && event.currentTarget.contains(nextFocused)) {
      return;
    }

    this.closePicker();
  }

  @action
  updateSearch(event) {
    this.searchTerm = event.target.value;
  }

  @action
  selectCategory(categoryId) {
    if (this.args.readOnlyCategoryId) {
      return;
    }

    this.composer.updateCategory(categoryId);
    this.closePicker();
  }

  <template>
    <div
      class="fomio-composer-category-picker"
      {{on "keydown" this.handleKeydown}}
      {{on "focusout" this.handleFocusOut}}
    >
      <button
        type="button"
        class={{this.buttonClass}}
        disabled={{this.isDisabled}}
        aria-expanded={{if this.isOpen "true" "false"}}
        {{on "click" this.togglePicker}}
      >
        <span
          class="fomio-composer-category-picker__swatch"
          style={{this.selectedSwatchStyle}}
          aria-hidden="true"
        ></span>

        <span class="fomio-composer-category-picker__trigger-copy">
          <span class="fomio-composer-category-picker__label">{{this.selectedLabel}}</span>
          {{#if this.selectedDescription}}
            <span class="fomio-composer-category-picker__meta">{{this.selectedDescription}}</span>
          {{/if}}
        </span>

        <span class="fomio-composer-category-picker__chevron" aria-hidden="true">
          {{icon (if this.isOpen "chevron-up" "chevron-down")}}
        </span>
      </button>

      {{#if this.isOpen}}
        <div class="fomio-composer-category-picker__panel">
          <label class="fomio-composer-category-picker__search">
            <input
              type="text"
              value={{this.searchTerm}}
              placeholder={{i18n (themePrefix "composer.category_search_placeholder")}}
              {{on "input" this.updateSearch}}
            />
            <span class="fomio-composer-category-picker__search-icon" aria-hidden="true">
              {{icon "search"}}
            </span>
          </label>

          <FomioList @tag="div" @extraClass="fomio-composer-category-picker__list">
            <FomioListSectionHeader @tag="div">
              {{this.listLabel}}
            </FomioListSectionHeader>
            <FomioListSeparator @tag="div" />
            {{#each this.filteredCategories as |entry|}}
              <FomioListItem
                @wrapperTag="div"
                @isActive={{eq entry.category.id @value}}
                @isDisabled={{entry.isDisabled}}
                @extraClass="fomio-composer-category-picker__item"
                {{on "click" (fn this.selectCategory entry.category.id)}}
              >
                <span
                  class="fomio-composer-category-picker__item-swatch"
                  style={{entry.swatchStyle}}
                  aria-hidden="true"
                ></span>

                <span class="fomio-list__content">
                  <span class="fomio-list__title">{{entry.category.name}}</span>
                  {{#if entry.description}}
                    <span class="fomio-list__subtitle">{{entry.description}}</span>
                  {{/if}}
                </span>

                {{#if entry.meta}}
                  <span class="fomio-list__meta">{{entry.meta}}</span>
                {{/if}}
              </FomioListItem>
            {{else}}
              <div class="fomio-composer-category-picker__empty">
                {{i18n (themePrefix "composer.category_search_empty")}}
              </div>
            {{/each}}
          </FomioList>
        </div>
      {{/if}}
    </div>
  </template>
}
