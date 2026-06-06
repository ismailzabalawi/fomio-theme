const AVATAR_SIZE_CLASSES = {
  xs: "fomio-avatar--xs",
  sm: "fomio-avatar--sm",
  md: "fomio-avatar--md",
  lg: "fomio-avatar--lg",
  xl: "fomio-avatar--xl",
};

const AVATAR_IMAGE_SIZES = {
  xs: "small",
  sm: "small",
  md: "large",
  lg: "large",
  xl: "large",
};

const AVATAR_PALETTE_CLASSES = {
  terra: "fomio-avatar--terra",
  violet: "fomio-avatar--violet",
  sage: "fomio-avatar--sage",
  slate: "fomio-avatar--slate",
  warm: "fomio-avatar--warm",
};

const CARD_VARIANT_CLASSES = {
  elevated: "fomio-card",
  raised: "fomio-card",
  default: "fomio-card",
  flat: "fomio-card fomio-card--flat",
};

const BADGE_VARIANT_CLASSES = {
  default: "default",
  neutral: "default",
  teret: "teret",
  primary: "primary",
  accent: "accent",
  success: "success",
  warning: "warning",
  danger: "danger",
};

function push(classes, value) {
  if (!value) {
    return;
  }

  classes.push(value);
}

export function normalizeAvatarSize(args = {}) {
  return args.size ?? "md";
}

export function normalizeAvatarPalette(args = {}) {
  return args.palette ?? args.variant ?? "terra";
}

export function avatarClassNames(args = {}) {
  const classes = [
    "fomio-avatar",
    AVATAR_SIZE_CLASSES[normalizeAvatarSize(args)] || AVATAR_SIZE_CLASSES.md,
    AVATAR_PALETTE_CLASSES[normalizeAvatarPalette(args)] ||
      AVATAR_PALETTE_CLASSES.terra,
  ];

  push(classes, args.extraClass);
  return classes.join(" ");
}

export function avatarImageSize(args = {}) {
  return args.imageSize ?? AVATAR_IMAGE_SIZES[normalizeAvatarSize(args)] ?? "large";
}

export function hasAvatarBadge(args = {}) {
  return Boolean(args.online || args.badgeCount);
}

export function normalizeCardVariant(args = {}) {
  return args.variant ?? args.surface ?? "elevated";
}

export function cardClassNames(args = {}) {
  const classes = [
    CARD_VARIANT_CLASSES[normalizeCardVariant(args)] || CARD_VARIANT_CLASSES.elevated,
  ];

  if (args.interactive) {
    classes.push("fomio-card--interactive");
  }

  if (args.disabled) {
    classes.push("is-disabled");
  }

  push(classes, args.extraClass);
  return classes.join(" ");
}

export function listItemClassNames(args = {}) {
  const classes = ["fomio-list__item"];
  const variant = args.variant;

  if (args.isActive ?? args.active) {
    classes.push("fomio-list__item--active");
  }

  if (args.isDanger || args.danger || variant === "danger") {
    classes.push("fomio-list__item--danger");
  }

  if (args.isDisabled ?? args.disabled) {
    classes.push("fomio-list__item--disabled");
  }

  push(classes, args.extraClass);
  return classes.join(" ");
}

export function listSectionHeaderClassNames(args = {}) {
  const classes = ["fomio-list__section-header"];
  push(classes, args.extraClass);
  return classes.join(" ");
}

export function normalizeIdentitySize(args = {}) {
  if (args.size) {
    return args.size;
  }

  if (args.large) {
    return "lg";
  }

  return "md";
}

export function identityClassNames(args = {}) {
  const classes = ["fomio-identity"];

  if (normalizeIdentitySize(args) === "lg") {
    classes.push("fomio-identity--lg");
  }

  if (args.showAvatar === false) {
    classes.push("fomio-identity--avatarless");
  }

  push(classes, args.extraClass);
  return classes.join(" ");
}

export function normalizeBadgeVariant(args = {}) {
  return args.variant ?? args.tone ?? "default";
}

export function badgeClassNames(args = {}) {
  const classes = ["fomio-badge"];

  push(
    classes,
    BADGE_VARIANT_CLASSES[normalizeBadgeVariant(args)] ||
      BADGE_VARIANT_CLASSES.default
  );

  if (args.size) {
    classes.push(`fomio-badge--${args.size}`);
  }

  if (args.withDot || args.dot) {
    classes.push("fomio-badge--with-dot");
  }

  push(classes, args.extraClass);
  return classes.join(" ");
}

export function metaRowClassNames(args = {}) {
  const classes = ["fomio-meta-row"];

  if (args.emphasized) {
    classes.push("fomio-meta-row--emphasized");
  }

  push(classes, args.extraClass);
  return classes.join(" ");
}

export function emptyStateClassNames(args = {}) {
  const classes = ["fomio-empty-state"];

  if (args.centered || args.variant === "centered") {
    classes.push("fomio-empty-state--centered");
  }

  if (args.inline || args.variant === "inline") {
    classes.push("fomio-empty-state--inline");
  }

  push(classes, args.extraClass);
  return classes.join(" ");
}
