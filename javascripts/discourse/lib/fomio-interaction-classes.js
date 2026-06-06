function push(classes, value) {
  if (!value) {
    return;
  }

  classes.push(value);
}

function classString(classes) {
  return classes.join(" ");
}

export function normalizeDropdownAlign(args = {}) {
  return args.align ?? "start";
}

export function normalizeDropdownSide(args = {}) {
  return args.side ?? "bottom";
}

export function dropdownClassNames(args = {}) {
  const classes = ["fomio-dropdown"];

  if (normalizeDropdownAlign(args) === "end") {
    classes.push("fomio-dropdown--align-end");
  }

  if (normalizeDropdownSide(args) === "top") {
    classes.push("fomio-dropdown--align-top");
  }

  if (args.isOpen) {
    classes.push("fomio-dropdown--open");
  }

  push(classes, args.extraClass ?? args.wrapperClass);
  return classString(classes);
}

export function dropdownTriggerClassNames(args = {}) {
  const classes = ["fomio-dropdown__trigger"];

  if (args.triggerClass) {
    classes.push(args.triggerClass);
  } else if (args.variant === "plain") {
    classes.push("fomio-btn", "fomio-btn--plain");
  } else {
    classes.push("fomio-btn", "fomio-btn-secondary");
  }

  return classString(classes);
}

export function dropdownPanelClassNames(args = {}) {
  const classes = ["fomio-dropdown__panel"];

  push(classes, args.panelClass);
  return classString(classes);
}

export function normalizeDropdownItems(args = {}) {
  return (args.items ?? []).map((item, index) => {
    const type = item.type ?? "item";

    return {
      key:
        item.key ??
        item.id ??
        item.value ??
        item.label ??
        `${type}-${index}`,
      type,
      isDivider: type === "divider",
      isSection: type === "section",
      value: item.value ?? item.id ?? item.key ?? item.label,
      label: item.label ?? "",
      description: item.description ?? null,
      href: item.href ?? null,
      icon: item.icon ?? null,
      phIcon: item.phIcon ?? null,
      trailingIcon: item.trailingIcon ?? null,
      isDanger: item.isDanger ?? item.danger ?? false,
      isDisabled: item.isDisabled ?? item.disabled ?? false,
      isLoading: item.isLoading ?? item.loading ?? false,
      isUnavailable:
        (item.isDisabled ?? item.disabled ?? false) ||
        (item.isLoading ?? item.loading ?? false),
      keepOpen: item.keepOpen ?? false,
      selected:
        item.selected ??
        item.isSelected ??
        item.value === (args.selectedKey ?? args.selected),
    };
  });
}

export function normalizeTabs(args = {}) {
  const tabs = args.tabs ?? args.items ?? args.options ?? [];
  const selectedKey = args.selectedKey ?? args.selected ?? args.value;
  const firstEnabledTab = tabs.find(
    (tab) => !(tab.isDisabled ?? tab.disabled)
  );
  const fallbackKey =
    firstEnabledTab?.key ?? firstEnabledTab?.id ?? firstEnabledTab?.value;

  return tabs.map((tab, index) => {
    const key = tab.key ?? tab.id ?? tab.value ?? `tab-${index}`;
    return {
      ...tab,
      key,
      label: tab.label ?? "",
      panelId: tab.panelId ?? `${args.idPrefix ?? "fomio-tabs"}-panel-${key}`,
      triggerId:
        tab.triggerId ?? `${args.idPrefix ?? "fomio-tabs"}-trigger-${key}`,
      isDisabled: tab.isDisabled ?? tab.disabled ?? false,
      isSelected:
        tab.isSelected ??
        key === (selectedKey ?? args.defaultSelectedKey ?? fallbackKey),
    };
  });
}

export function normalizeRadioOptions(args = {}) {
  const selectedValue = args.value ?? args.selected ?? args.selectedKey ?? null;

  return (args.options ?? []).map((option, index) => {
    const value = option.value ?? option.id ?? option.key ?? `radio-${index}`;

    return {
      ...option,
      value,
      label: option.label ?? "",
      description: option.description ?? null,
      isDisabled: option.isDisabled ?? option.disabled ?? false,
      isSelected:
        option.isSelected ??
        option.checked ??
        value === selectedValue,
    };
  });
}

export function radioGroupClassNames(args = {}) {
  const classes = ["fomio-radio-group"];

  if (args.orientation === "horizontal") {
    classes.push("fomio-radio-group--horizontal");
  }

  if (args.size && args.size !== "md") {
    classes.push(`fomio-radio-group--${args.size}`);
  }

  push(classes, args.extraClass);
  return classString(classes);
}

export function radioOptionClassNames(option, args = {}) {
  const classes = ["fomio-radio"];

  if (option.isSelected) {
    classes.push("fomio-radio--selected");
  }

  if (option.isDisabled) {
    classes.push("fomio-radio--disabled");
  }

  if (args.size && args.size !== "md") {
    classes.push(`fomio-radio--${args.size}`);
  }

  return classString(classes);
}

export function normalizeSegmentedValue(args = {}) {
  return args.value ?? args.selected ?? null;
}

export function normalizedSegmentedOptions(args = {}) {
  const selectedValue = normalizeSegmentedValue(args);

  return (args.options ?? []).map((option) => {
    const value = option.id ?? option.value;
    return {
      ...option,
      value,
      label: option.label ?? "",
      isActive: option.isActive ?? value === selectedValue,
      isDisabled: option.isDisabled ?? option.disabled ?? false,
    };
  });
}

export function segmentedWrapperClassNames(args = {}) {
  const classes = ["fomio-seg"];

  if (args.variant) {
    classes.push(`fomio-seg--${args.variant}`);
  }

  if (args.size && args.size !== "md") {
    classes.push(`fomio-seg--${args.size}`);
  }

  push(classes, args.wrapperClass);
  return classString(classes);
}

export function segmentedButtonClassNames(option, args = {}) {
  const classes = ["fomio-seg-btn"];

  if (args.buttonClass) {
    classes.push(args.buttonClass);
  }

  if (args.variant) {
    classes.push(`fomio-seg-btn--${args.variant}`);
  }

  if (args.size && args.size !== "md") {
    classes.push(`fomio-seg-btn--${args.size}`);
  }

  if (option.isActive) {
    classes.push("active", "is-active");
  }

  if (option.isDisabled) {
    classes.push("is-disabled");
  }

  return classString(classes);
}

export function normalizeSheetVariant(args = {}) {
  return args.variant ?? args.source ?? args.mode ?? "desktop";
}

export function normalizeModalSize(args = {}) {
  return args.size ?? "md";
}

export function modalClassNames(args = {}) {
  const classes = ["fomio-modal"];

  classes.push(`fomio-modal--${normalizeModalSize(args)}`);

  if (args.danger || args.tone === "danger") {
    classes.push("fomio-modal--danger");
  }

  push(classes, args.extraClass ?? args.panelClass);
  return classString(classes);
}

export function modalBackdropClassNames(args = {}) {
  const classes = ["fomio-modal-backdrop"];
  push(classes, args.backdropClass);
  return classString(classes);
}

export function normalizeToastTone(args = {}) {
  return args.tone ?? args.variant ?? "neutral";
}

export function toastClassNames(args = {}) {
  const classes = ["fomio-toast", `fomio-toast--${normalizeToastTone(args)}`];

  if (args.dismissible !== false) {
    classes.push("fomio-toast--dismissible");
  }

  if (args.withIcon ?? args.icon) {
    classes.push("fomio-toast--with-icon");
  }

  push(classes, args.extraClass);
  return classString(classes);
}

export function normalizeCommandItems(args = {}) {
  return (args.items ?? []).map((item, index) => {
    const type = item.type ?? "item";

    return {
      ...item,
      type,
      key:
        item.key ??
        item.id ??
        item.value ??
        item.label ??
        `${type}-${index}`,
      label: item.label ?? "",
      subtitle: item.subtitle ?? item.description ?? null,
      shortcut: item.shortcut ?? null,
      section: item.section ?? null,
      icon: item.icon ?? null,
      href: item.href ?? null,
      isSection: type === "section",
      isDivider: type === "divider",
      isDisabled: item.isDisabled ?? item.disabled ?? false,
      value: item.value ?? item.id ?? item.key ?? item.label,
      searchText:
        item.searchText ??
        [item.label, item.subtitle, item.section]
          .filter(Boolean)
          .join(" ")
          .toLowerCase(),
    };
  });
}

export function commandPaletteClassNames(args = {}) {
  const classes = ["fomio-command-palette"];

  if (args.size) {
    classes.push(`fomio-command-palette--${args.size}`);
  }

  push(classes, args.extraClass);
  return classString(classes);
}

export function commandPaletteBackdropClassNames(args = {}) {
  const classes = ["fomio-command-palette-backdrop"];
  push(classes, args.backdropClass);
  return classString(classes);
}

export function searchSheetClassNames(args = {}) {
  const variant = normalizeSheetVariant(args);
  const classes = ["fomio-search-sheet", `fomio-search-sheet--${variant}`];
  push(classes, args.extraClass);
  return classString(classes);
}

export function searchSheetBackdropClass(args = {}) {
  if (args.backdropClass) {
    return args.backdropClass;
  }

  return normalizeSheetVariant(args) === "desktop"
    ? "fomio-search-sheet__backdrop"
    : null;
}

export function ephemeralSheetClassNames(args = {}) {
  const classes = ["fomio-ephemeral-sheet"];

  if (args.variant) {
    classes.push(`fomio-ephemeral-sheet--${args.variant}`);
  }

  if (args.side) {
    classes.push(`fomio-ephemeral-sheet--${args.side}`);
  }

  push(classes, args.extraClass ?? args.panelClass);
  return classString(classes);
}

export function ephemeralSheetBackdropClassNames(args = {}) {
  const classes = ["fomio-ephemeral-sheet-backdrop"];

  if (args.variant) {
    classes.push(`fomio-ephemeral-sheet-backdrop--${args.variant}`);
  }

  push(classes, args.backdropClass);
  return classString(classes);
}

export function normalizeNotificationsMenuSource(source) {
  return source === "mobile" ? "mobile" : "desktop";
}

export function notificationsMenuClassNames(source, extraClass) {
  const classes = [
    "fomio-notifications-menu",
    `fomio-notifications-menu--${normalizeNotificationsMenuSource(source)}`,
  ];
  push(classes, extraClass);
  return classString(classes);
}
