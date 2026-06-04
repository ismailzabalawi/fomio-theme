import UpsertHyperlink from "discourse/components/modal/upsert-hyperlink";
import {
  computeToolbarTriggerRect,
  computeToolbarViewportPosition,
} from "./fomio-selection-toolbar-geometry";

function findSelectionLinkMark(state) {
  const { from, to } = state.selection;
  let linkMark = null;

  state.doc.nodesBetween(from, to, (node) => {
    if (linkMark || !node.isText) {
      return;
    }

    linkMark = node.marks.find((mark) => mark.type === state.schema.marks.link);

    return !linkMark;
  });

  return linkMark;
}

class FomioSelectionToolbarPluginView {
  #getContext;
  #toggleMarkCommand;
  #utils;
  #TextSelection;
  #view;
  #toolbarElement;
  #selection;
  #linkMark;
  #scrollContainer;
  #calculatingCoords = false;
  #boundScroll = () => this.#repositionToolbar();
  #boundFocusOut = () => {
    requestAnimationFrame(() => {
      if (!this.#view?.hasFocus()) {
        this.#resetToolbar();
      }
    });
  };

  constructor({ utils, getContext, toggleMarkCommand, TextSelection }) {
    this.#utils = utils;
    this.#getContext = getContext;
    this.#toggleMarkCommand = toggleMarkCommand;
    this.#TextSelection = TextSelection;
  }

  update(view) {
    try {
      this.#view = view;

      if (!this.#isEligibleSelection(view)) {
        this.#resetToolbar();
        return;
      }

      this.#selection = {
        from: view.state.selection.from,
        to: view.state.selection.to,
      };
      this.#linkMark = findSelectionLinkMark(view.state);

      this.#attachListeners();
      this.#showToolbar();
    } catch {
      // Never throw into editor setup — silent fail per CLAUDE.md failure mode 3
      this.#resetToolbar();
    }
  }

  destroy() {
    this.#resetToolbar();
    this.#toolbarElement?.remove();
    this.#toolbarElement = null;
  }

  #isEligibleSelection(view) {
    if (!view.dom.closest("#reply-control") || !view.hasFocus()) {
      return false;
    }

    const { selection, doc } = view.state;

    if (!(selection instanceof this.#TextSelection) || selection.empty) {
      return false;
    }

    return !!doc.textBetween(selection.from, selection.to, "\n", "\n").trim();
  }

  #toggleMark(markType) {
    this.#toggleMarkCommand(markType)(this.#view.state, this.#view.dispatch);
    this.#view.focus();
  }

  #openLinkModal() {
    const toolbarEvent = this.#buildToolbarEvent();

    this.#getContext().modal.show(UpsertHyperlink, {
      model: {
        editing: !!this.#linkMark?.attrs?.href,
        linkText: toolbarEvent.selected.value,
        linkUrl: this.#linkMark?.attrs?.href,
        toolbarEvent,
      },
    });
  }

  #buildToolbarEvent() {
    const selection = this.#selection ?? {
      from: this.#view.state.selection.from,
      to: this.#view.state.selection.to,
    };

    return {
      selected: {
        start: selection.from,
        end: selection.to,
        value: this.#utils.convertToMarkdown(
          this.#view.state.doc.slice(selection.from, selection.to)
        ),
      },
      addText: (text) => this.#replaceSelection(selection, text),
    };
  }

  #replaceSelection(selection, markdown) {
    const doc = this.#utils.convertFromMarkdown(markdown);
    const firstChild = doc.content.firstChild;

    if (!firstChild) {
      return;
    }

    const content =
      firstChild.type.name === "paragraph" ? firstChild.content : firstChild;

    this.#view.dispatch(
      this.#view.state.tr
        .replaceWith(selection.from, selection.to, content)
        .scrollIntoView()
    );
    this.#view.focus();
  }

  #attachListeners() {
    const nextScrollContainer = this.#view.dom.closest(".d-editor-textarea-wrapper");

    if (this.#scrollContainer !== nextScrollContainer) {
      this.#scrollContainer?.removeEventListener("scroll", this.#boundScroll);
      this.#scrollContainer = nextScrollContainer;
      this.#scrollContainer?.addEventListener("scroll", this.#boundScroll);
    }

    this.#view.dom.removeEventListener("focusout", this.#boundFocusOut);
    this.#view.dom.addEventListener("focusout", this.#boundFocusOut);
    window.removeEventListener("scroll", this.#boundScroll, true);
    window.addEventListener("scroll", this.#boundScroll, true);
  }

  #detachListeners() {
    this.#scrollContainer?.removeEventListener("scroll", this.#boundScroll);
    this.#scrollContainer = null;
    this.#view?.dom?.removeEventListener("focusout", this.#boundFocusOut);
    window.removeEventListener("scroll", this.#boundScroll, true);
  }

  #showToolbar() {
    if (!this.#toolbarElement) {
      this.#createToolbarElement();
    }

    this.#repositionToolbar();
    this.#toolbarElement.style.display = "flex";
  }

  #createToolbarElement() {
    this.#toolbarElement = document.createElement("div");
    this.#toolbarElement.className = "fomio-selection-toolbar";
    this.#toolbarElement.setAttribute("role", "toolbar");

    const i18n = this.#getContext().siteSettings.themeTranslatedTextOverrides || {};
    const ariaLabel = i18n["composer.toolbar_aria_label"] || "Text formatting";
    this.#toolbarElement.setAttribute("aria-label", ariaLabel);

    const buttonConfigs = [
      {
        id: "bold",
        label: "B",
        ariaLabel: i18n["composer.toolbar_bold"] || "Bold",
        shortcut: "⌘B",
        action: () => this.#toggleMark(this.#view.state.schema.marks.strong),
      },
      {
        id: "italic",
        label: "I",
        ariaLabel: i18n["composer.toolbar_italic"] || "Italic",
        shortcut: "⌘I",
        action: () => this.#toggleMark(this.#view.state.schema.marks.em),
      },
      {
        id: "link",
        label: "🔗",
        ariaLabel: i18n["composer.toolbar_link"] || "Link",
        shortcut: "⌘K",
        action: () => this.#openLinkModal(),
      },
    ];

    buttonConfigs.forEach(({ id, label, ariaLabel, shortcut, action }) => {
      const button = document.createElement("button");
      button.className = "fomio-selection-toolbar__button";
      button.setAttribute("type", "button");
      button.setAttribute("aria-label", ariaLabel);
      button.setAttribute("title", shortcut);
      button.setAttribute("data-id", id);
      button.textContent = label;

      button.addEventListener("mousedown", (e) => {
        e.preventDefault();
        action();
        this.#view.focus();
      });

      this.#toolbarElement.appendChild(button);
    });

    document.body.appendChild(this.#toolbarElement);
  }

  #repositionToolbar() {
    if (!this.#toolbarElement) {
      return;
    }

    const coords = this.#getTriggerClientRect();
    const { top, left } = computeToolbarViewportPosition(
      coords,
      this.#toolbarElement.offsetWidth,
      { width: window.innerWidth, height: window.innerHeight }
    );

    this.#toolbarElement.style.position = "fixed";
    this.#toolbarElement.style.top = `${top}px`;
    this.#toolbarElement.style.left = `${left}px`;
    this.#toolbarElement.style.zIndex = "10000";
  }

  #getTriggerClientRect() {
    const { doc, selection } = this.#view.state;

    if (
      this.#calculatingCoords ||
      !this.#selection ||
      this.#selection.to > doc.content.size ||
      this.#selection.from > doc.content.size ||
      selection.empty
    ) {
      return { left: 0, top: 0, width: 0, height: 0 };
    }

    this.#calculatingCoords = true;

    try {
      const start = this.#view.coordsAtPos(this.#selection.from);
      const end = this.#view.coordsAtPos(this.#selection.to);
      const replyTopbarRect = document
        .querySelector("#reply-control .reply-to")
        ?.getBoundingClientRect();
      const safeTop = replyTopbarRect ? replyTopbarRect.bottom + 8 : 8;

      return computeToolbarTriggerRect(start, end, safeTop);
    } finally {
      this.#calculatingCoords = false;
    }
  }

  #resetToolbar() {
    this.#detachListeners();
    if (this.#toolbarElement) {
      this.#toolbarElement.style.display = "none";
    }
    this.#selection = null;
  }
}

const extension = {
  plugins: ({ pmState, utils, getContext, pmCommands }) => {
    const { Plugin, TextSelection } = pmState;

    return new Plugin({
      view() {
        return new FomioSelectionToolbarPluginView({
          utils,
          getContext,
          toggleMarkCommand: pmCommands.toggleMark,
          TextSelection,
        });
      },
    });
  },
};

export default extension;
