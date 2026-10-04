// Native adapter for core 7b4f0970's Toolbar / ToolbarPopupMenuOptions.
// Reuse native commands, menus and selection handling; never rewrite the body.
const FORMAT_BUTTONS = new Set([
  "bold",
  "italic",
  "heading",
  "link",
  "blockquote",
  "code",
  "list",
  "toggle-direction",
]);

export function groupComposerFormatting(toolbar, { title, label }) {
  // DEditor is also used in admin/settings and other non-composer surfaces.
  if (!toolbar.context?.composerEvents || !Array.isArray(toolbar.groups)) {
    return false;
  }

  const groups = toolbar.groups;
  const fontStyles = groups.find((group) => group.group === "fontStyles");
  if (!fontStyles || groups.some((group) =>
    group.buttons.some((button) => button.id === "fomio-composer-format")
  )) {
    return false;
  }

  const buttons = groups.flatMap((group) => group.buttons)
    .filter((button) => FORMAT_BUTTONS.has(button.id));
  // If core changes the shape, leave the original toolbar intact.
  if (!buttons.length || buttons.some((button) =>
    typeof button.action !== "function" ||
    (button.popupMenu && (
      typeof button.popupMenu.options !== "function" ||
      typeof button.popupMenu.action !== "function"
    ))
  )) {
    return false;
  }

  const formattingOptions = () => buttons.flatMap((button) => {
    if (button.disabled || button.condition?.(toolbar.context) === false) {
      return [];
    }

    if (button.popupMenu) {
      // Flatten core's heading and list choices, including extension options.
      return (button.popupMenu.options() || []).filter((option) =>
        typeof option.condition === "function"
          ? option.condition(toolbar.context)
          : option.condition !== false
      ).map((option) => ({
        ...option,
        condition: true,
        action: () => button.popupMenu.action(option),
      }));
    }

    return [{
      name: button.id,
      icon: button.icon,
      label: button.id === "toggle-direction"
        ? "composer.toggle_direction"
        : `composer.${button.id}_title`,
      translatedTitle: button.title,
      ariaKeyshortcuts: button.ariaKeyshortcuts,
      active: button.active,
      showActiveIcon: Boolean(button.active),
      condition: true,
      // Calling the original action retains trimLeading, events and the
      // active editor's textManipulation implementation in both modes.
      action: () => button.action(),
    }];
  });

  toolbar.addButton({
    id: "fomio-composer-format",
    group: "fontStyles",
    icon: "discourse-text",
    title,
    popupMenu: {
      triggerLabel: label,
      options: () => [...formattingOptions(), {
        name: "fomio-format-close",
        label: "close",
        icon: "xmark",
        condition: true,
        // The native popup closes before invoking this. An explicit exit is
        // useful in its phone sheet and for tablets with a hardware keyboard.
        action: () => {},
      }],
      action: (option) => option.action(),
    },
    unshift: true,
  });

  for (const group of groups) {
    group.buttons = group.buttons.filter((button) => !buttons.includes(button));
  }
  // The design's writing strip starts with Upload. Core adds upload to this
  // group after onToolbarCreate; moving the group retains that same button,
  // its native availability and any plugin contributions.
  const insertionsIndex = groups.findIndex((group) => group.group === "insertions");
  if (insertionsIndex >= 0) {
    const [insertions] = groups.splice(insertionsIndex, 1);
    groups.splice(groups.indexOf(fontStyles), 0, insertions);
  }
  // Core's shortcuts still point at the original commands. Unknown plugin
  // buttons, native upload/options and contextual replacement toolbars stay.
  return true;
}
