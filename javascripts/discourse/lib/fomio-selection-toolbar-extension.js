import { TrackedObject } from "@ember-compat/tracked-built-ins";
import ToolbarButtons from "discourse/components/composer/toolbar-buttons";
import UpsertHyperlink from "discourse/components/modal/upsert-hyperlink";
import { updatePosition } from "discourse/float-kit/lib/update-position";
import { ToolbarBase } from "discourse/lib/composer/toolbar";
import { rovingButtonBar } from "discourse/lib/roving-button-bar";

const MENU_IDENTIFIER = "fomio-composer-selection-toolbar";
const MENU_OFFSET = 12;

function selectionHasMark(state, markType) {
  const { from, to, empty } = state.selection;

  if (empty) {
    return !!(state.storedMarks || state.selection.$from.marks()).find(
      (mark) => mark.type === markType
    );
  }

  return state.doc.rangeHasMark(from, to, markType);
}

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

class FomioSelectionToolbar extends ToolbarBase {
  constructor(opts = {}) {
    super(opts);

    this.addButton({
      id: "bold",
      icon: "bold",
      shortcut: "B",
      action: opts.toggleBold,
      active: ({ state }) => state.inBold,
    });

    this.addButton({
      id: "italic",
      icon: "italic",
      shortcut: "I",
      action: opts.toggleItalic,
      active: ({ state }) => state.inItalic,
    });

    this.addButton({
      id: "link",
      icon: "link",
      action: opts.upsertLink,
      active: ({ state }) => state.inLink,
    });
  }
}

class FomioSelectionToolbarPluginView {
  #getContext;
  #toggleMarkCommand;
  #utils;
  #TextSelection;
  #view;
  #toolbar;
  #toolbarState;
  #menuInstance;
  #selection;
  #linkMark;
  #scrollContainer;
  #menuTrigger;
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

    this.#ensureToolbar();
    this.#attachListeners();
    this.#showToolbar();
  }

  destroy() {
    this.#resetToolbar();
    this.#toolbar = null;
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

  #ensureToolbar() {
    if (!this.#toolbar) {
      this.#toolbarState = new TrackedObject({
        inBold: false,
        inItalic: false,
        inLink: false,
      });

      this.#toolbar = new FomioSelectionToolbar({
        capabilities: this.#getContext().capabilities,
        site: this.#getContext().site,
        toggleBold: () => this.#toggleMark(this.#view.state.schema.marks.strong),
        toggleItalic: () => this.#toggleMark(this.#view.state.schema.marks.em),
        upsertLink: () => this.#openLinkModal(),
      });

      this.#toolbar.context = {
        textManipulation: { state: this.#toolbarState },
        newToolbarEvent: () => this.#buildToolbarEvent(),
      };
      this.#toolbar.rovingButtonBar = rovingButtonBar;
    }

    Object.assign(this.#toolbarState, {
      inBold: selectionHasMark(this.#view.state, this.#view.state.schema.marks.strong),
      inItalic: selectionHasMark(this.#view.state, this.#view.state.schema.marks.em),
      inLink: selectionHasMark(this.#view.state, this.#view.state.schema.marks.link),
    });
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
    this.#menuTrigger = {
      getBoundingClientRect: () => this.#getTriggerClientRect(),
    };

    if (this.#menuInstance?.expanded) {
      this.#menuInstance.trigger = this.#menuTrigger;
      this.#repositionToolbar();
      return;
    }

    this.#menuInstance?.destroy();
    this.#getContext()
      .menu.show(this.#menuTrigger, {
        portalOutletElement: this.#view.dom.parentElement,
        identifier: MENU_IDENTIFIER,
        component: ToolbarButtons,
        placement: "top",
        padding: 0,
        hide: true,
        boundary: this.#view.dom.parentElement,
        fallbackPlacements: ["top-start", "top-end", "bottom", "bottom-start"],
        closeOnClickOutside: false,
        data: this.#toolbar,
      })
      .then((instance) => {
        this.#menuInstance = instance;
      });
  }

  #repositionToolbar() {
    if (!this.#menuInstance?.content) {
      return;
    }

    this.#menuInstance.trigger = this.#menuTrigger;
    updatePosition(this.#menuTrigger, this.#menuInstance.content, {});
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
      const left = Math.round((start.left + end.left) / 2);
      const top = Math.min(start.top, end.top) - MENU_OFFSET;

      return {
        left,
        right: left,
        top,
        bottom: top,
        width: 0,
        height: 0,
      };
    } finally {
      this.#calculatingCoords = false;
    }
  }

  #resetToolbar() {
    this.#detachListeners();
    this.#menuInstance?.destroy();
    this.#menuInstance = null;
    this.#selection = null;
    this.#menuTrigger = null;
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
