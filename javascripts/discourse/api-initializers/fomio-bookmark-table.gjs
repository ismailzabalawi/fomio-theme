import { apiInitializer } from "discourse/lib/api";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

const HEADER_COLUMN_CLASSNAMES = [
  "fomio-bookmark-table__col--bulk-toggle",
  "fomio-bookmark-table__col--topic",
  "fomio-bookmark-table__col--avatar",
  "fomio-bookmark-table__col--updated",
  "fomio-bookmark-table__col--activity",
  "fomio-bookmark-table__col--actions",
];

function applyHeaderColumnClasses(headerRow) {
  const headerCells = Array.from(headerRow?.children || []);
  if (!headerCells.length) {
    return;
  }

  headerCells.forEach((cell) => cell.classList.remove(...HEADER_COLUMN_CLASSNAMES));

  const hasBulkToggleColumn =
    headerCells.length === HEADER_COLUMN_CLASSNAMES.length &&
    headerCells[0]?.classList.contains("bulk-select");
  const columnClasses = hasBulkToggleColumn
    ? HEADER_COLUMN_CLASSNAMES
    : HEADER_COLUMN_CLASSNAMES.slice(1);

  headerCells.forEach((cell, index) => {
    const className = columnClasses[index];
    if (className) {
      cell.classList.add(className);
    }
  });
}

function syncBulkSelectionRowState(root) {
  root.querySelectorAll("tbody.topic-list-body tr.bookmark-list-item").forEach((row) => {
    const checkbox = row.querySelector("input.bulk-select");
    row.classList.toggle("is-selected", Boolean(checkbox?.checked));
  });
}

function buildBulkExitButton(component) {
  const button = document.createElement("button");
  button.type = "button";
  button.title = i18n("bookmarks.bulk.toggle");
  button.className =
    "btn no-text btn-icon btn-flat bulk-select fomio-bookmark-table__bulk-exit";
  button.setAttribute("aria-label", i18n("bookmarks.bulk.toggle"));
  button.innerHTML = `
    <svg
      class="fa d-icon d-icon-list-check svg-icon fa-width-auto svg-string"
      width="1em"
      height="1em"
      aria-hidden="true"
      xmlns="http://www.w3.org/2000/svg"
    >
      <use href="#list-check"></use>
    </svg>
    <span aria-hidden="true">&#8203;</span>
  `;
  button.addEventListener("click", (event) => {
    event.preventDefault();
    event.stopPropagation();
    component.toggleBulkSelect();
  });
  return button;
}

function ensureBulkExitButton(component, headerRow, summary) {
  let bulkToggleButton = headerRow.querySelector("th.bulk-select button.bulk-select");
  const existingExitButton = summary.querySelector("button.bulk-select");

  if (bulkToggleButton) {
    if (existingExitButton && existingExitButton !== bulkToggleButton) {
      existingExitButton.remove();
    }

    summary.prepend(bulkToggleButton);
    bulkToggleButton.classList.add("fomio-bookmark-table__bulk-exit");

    const bulkToggleCell = bulkToggleButton.closest("th.bulk-select");
    if (bulkToggleCell) {
      bulkToggleCell.classList.add("fomio-bookmark-table__bulk-toggle-placeholder");
      bulkToggleCell.innerHTML = "&nbsp;";
    }

    return;
  }

  if (!existingExitButton) {
    summary.prepend(buildBulkExitButton(component));
  }
}

function decorateTopicHeader(component, headerRow, topicCell) {
  if (!headerRow || !topicCell) {
    return;
  }

  const bulkActions = topicCell.querySelector(".bulk-select-topics");
  if (bulkActions) {
    let wrapper = topicCell.querySelector(".fomio-bookmark-table__bulk-bar");
    if (!wrapper) {
      wrapper = document.createElement("div");
      wrapper.className = "fomio-bookmark-table__bulk-bar";
      topicCell.replaceChildren(wrapper);
      wrapper.appendChild(bulkActions);
    }

    let summary = wrapper.querySelector(".fomio-bookmark-table__bulk-summary");
    if (!summary) {
      summary = document.createElement("div");
      summary.className = "fomio-bookmark-table__bulk-summary";
      wrapper.prepend(summary);
    }

    let controls = wrapper.querySelector(".fomio-bookmark-table__bulk-controls");
    if (!controls) {
      controls = document.createElement("div");
      controls.className = "fomio-bookmark-table__bulk-controls";
      wrapper.appendChild(controls);
    }

    ensureBulkExitButton(component, headerRow, summary);

    const dropdown = bulkActions.querySelector(".bulk-select-bookmarks-dropdown");
    const selectAll = bulkActions.querySelector(".bulk-select-all");
    const clearAll = bulkActions.querySelector(".bulk-clear-all");

    if (dropdown) {
      summary.appendChild(dropdown);
    }

    [selectAll, clearAll].filter(Boolean).forEach((button) => {
      controls.appendChild(button);
      button.classList.add("fomio-bookmark-table__bulk-button");
    });

    bulkActions.classList.add("fomio-bookmark-table__bulk-actions");

    return;
  }
}

function decorateBookmarkTable(component) {
  const root = component.element;
  if (!root) {
    return;
  }

  root.classList.add("fomio-bookmark-table-scroll");

  const table = root.querySelector("table.topic-list.bookmark-list");
  if (!table) {
    return;
  }

  table.classList.add("fomio-bookmark-table");
  root.classList.toggle("is-bulk-selecting", Boolean(component.bulkSelectEnabled));
  syncBulkSelectionRowState(root);

  const headerRow = table.querySelector("thead.topic-list-header tr");
  if (!headerRow) {
    return;
  }

  applyHeaderColumnClasses(headerRow);
  decorateTopicHeader(
    component,
    headerRow,
    headerRow.querySelector(".fomio-bookmark-table__col--topic")
  );
}

export default apiInitializer("1.8.0", (api) => {
  api.modifyClass("component:bookmark-list", {
    pluginId: "fomio-bookmark-table",

    attributeBindings: ["tabindex", "role", "ariaLabel:aria-label"],
    tabindex: 0,
    role: "region",

    get ariaLabel() {
      return i18n(themePrefix("bookmarks_table.scroll_region_label"));
    },

    didInsertElement() {
      this._super(...arguments);
      decorateBookmarkTable(this);
    },

    didRender() {
      this._super(...arguments);
      decorateBookmarkTable(this);
    },
  });
});
