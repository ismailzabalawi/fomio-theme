const BUTTON_VARIANT_CLASSES = {
  primary: "fomio-btn-primary",
  secondary: "fomio-btn-secondary",
  ghost: "fomio-btn-ghost",
  danger: "fomio-btn-danger",
  destructive: "fomio-btn-danger",
  tonal: "fomio-btn--tonal",
  plain: "fomio-btn--plain",
  outline: "fomio-btn--outline",
};

function push(classes, value) {
  if (!value) {
    return;
  }

  classes.push(value);
}

function classString(classes) {
  return classes.join(" ");
}

export function isControlLoading(args = {}) {
  return Boolean(args.loading ?? args.isLoading);
}

export function isControlDisabled(args = {}) {
  return Boolean(args.disabled || isControlLoading(args));
}

export function buttonClassNames(args = {}) {
  const classes = ["fomio-btn"];
  push(
    classes,
    BUTTON_VARIANT_CLASSES[args.variant] || BUTTON_VARIANT_CLASSES.primary
  );

  if (args.size === "sm") {
    classes.push("fomio-btn--sm");
  } else if (args.size === "lg") {
    classes.push("fomio-btn--lg");
  }

  if (args.block) {
    classes.push("fomio-btn--block");
  }

  if (args.iconOnly) {
    classes.push("fomio-btn--icon");
  }

  if (isControlLoading(args)) {
    classes.push("is-loading", "fomio-btn--loading");
  }

  if (args.isActive) {
    classes.push("is-active");
  }

  if (args.isOpen) {
    classes.push("is-open");
  }

  push(classes, args.extraClass);
  return classString(classes);
}

export function fieldClassNames(baseClass, args = {}) {
  const classes = [baseClass];

  if (isControlDisabled(args)) {
    classes.push(`${baseClass}--disabled`);
  }

  if (args.invalid || args.error) {
    classes.push(`${baseClass}--error`);
  }

  if (args.valid) {
    classes.push(`${baseClass}--success`);
  }

  push(classes, args.extraClass);
  return classString(classes);
}

export function fieldLabelClassNames(baseClass, args = {}) {
  const classes = [baseClass];

  if (args.required) {
    classes.push(`${baseClass}--required`);
  }

  return classString(classes);
}

export function fieldHintClassNames(args = {}, tone = "default") {
  const classes = ["fomio-hint"];

  if (tone === "error" || args.error) {
    classes.push("is-error");
  } else if (tone === "success" || args.valid || args.success) {
    classes.push("is-success");
  }

  return classString(classes);
}

export function inputClassNames(args = {}, extraClasses = []) {
  const classes = ["fomio-input"];

  if (args.leadingIcon) {
    classes.push("has-prefix");
  }

  if (args.trailingIcon || isControlLoading(args)) {
    classes.push("has-suffix");
  }

  if (args.invalid || args.error) {
    classes.push("is-error");
  }

  if (args.valid) {
    classes.push("is-success");
  }

  if (args.size && args.size !== "md") {
    classes.push(`fomio-input--${args.size}`);
  }

  if (args.variant) {
    classes.push(`fomio-input--${args.variant}`);
  }

  for (const className of extraClasses) {
    push(classes, className);
  }

  push(classes, args.inputClass);
  return classString(classes);
}

export function wrapClassNames(baseClass, args = {}, extraClasses = []) {
  const classes = [baseClass];

  if (args.size && args.size !== "md") {
    classes.push(`${baseClass}--${args.size}`);
  }

  if (args.variant) {
    classes.push(`${baseClass}--${args.variant}`);
  }

  if (isControlDisabled(args)) {
    classes.push("is-disabled");
  }

  if (isControlLoading(args)) {
    classes.push("is-loading");
  }

  for (const className of extraClasses) {
    push(classes, className);
  }

  push(classes, args.wrapperClass);
  return classString(classes);
}
