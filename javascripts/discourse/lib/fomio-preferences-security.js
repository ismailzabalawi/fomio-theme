function normalizeLabel(value) {
  return String(value ?? "")
    .trim()
    .replace(/\s+/g, " ");
}

export function isPreferencesSecurityPath(pathname = "") {
  return (
    /^\/my\/preferences\/security(?:\/|$)/.test(pathname) ||
    /^\/u\/[^/]+\/preferences\/security(?:\/|$)/.test(pathname)
  );
}

export function isPreferencesProfilePath(pathname = "") {
  return (
    /^\/my\/preferences\/profile(?:\/|$)/.test(pathname) ||
    /^\/u\/[^/]+\/preferences\/profile(?:\/|$)/.test(pathname)
  );
}

export function resolveSecurityActionVariant(
  label,
  { revokeLabel, undoLabel } = {}
) {
  const normalized = normalizeLabel(label);

  if (!normalized) {
    return null;
  }

  if (normalized === normalizeLabel(revokeLabel)) {
    return "danger";
  }

  if (normalized === normalizeLabel(undoLabel)) {
    return "secondary";
  }

  return null;
}
