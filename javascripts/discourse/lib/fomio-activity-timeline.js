export const LABEL_KEYS_BY_ACTION_TYPE = {
  1: "liked",
  2: "liked",
  4: "created_byte",
  5: "replied",
  6: "replied",
  7: "replied",
  9: "replied",
};

export const ICONS_BY_ACTION_KEY = {
  created_byte: "fomio-ph-note-pencil",
  replied: "fomio-ph-arrow-bend-up-left",
  liked: "fomio-ph-heart",
};

export function valueFor(object, key) {
  if (!object) {
    return null;
  }

  if (typeof object.get === "function") {
    return object.get(key);
  }

  return object[key];
}

export function actionKeyFromActionType(actionType) {
  if (actionType == null) {
    return null;
  }

  return LABEL_KEYS_BY_ACTION_TYPE[actionType] ?? null;
}

export function actionKeyFromItem(item) {
  const actionType = valueFor(item, "action_type");
  if (actionType == null) {
    return null;
  }

  return LABEL_KEYS_BY_ACTION_TYPE[actionType] ?? null;
}

export function iconForActionKey(actionKey) {
  return ICONS_BY_ACTION_KEY[actionKey] || "fomio-ph-rows";
}

/**
 * Prepends the timeline type label into native metadata (M1 meta-row merge).
 * Idempotent per stream row — safe across infinite scroll appends.
 */
export function bindTimelineTypeLabelToMetadata(prefixElement) {
  if (!prefixElement || typeof document === "undefined") {
    return;
  }

  const row = prefixElement.closest(".post-list-item, .user-stream-item");
  if (!row || row.dataset.fomioTimelineMetaBound === "true") {
    return;
  }

  const typeLabel = prefixElement.querySelector(".fomio-activity-timeline-type-label");
  const metadata = row.querySelector(".post-list-item__metadata");

  if (!typeLabel || !metadata) {
    return;
  }

  metadata.prepend(typeLabel);
  row.dataset.fomioTimelineMetaBound = "true";
}

/**
 * Prepends the timeline type label into native teret/meta row on activity Bytes.
 * Idempotent per topic row — safe across infinite scroll appends.
 */
export function bindBytesTypeLabelToMeta(prefixElement) {
  if (!prefixElement || typeof document === "undefined") {
    return;
  }

  const row = prefixElement.closest("tr.topic-list-item");
  if (!row || row.dataset.fomioBytesMetaBound === "true") {
    return;
  }

  const typeLabel = prefixElement.querySelector(".fomio-activity-timeline-type-label");
  const metaRow = row.querySelector(".link-bottom-line");

  if (!typeLabel || !metaRow) {
    return;
  }

  metaRow.prepend(typeLabel);
  row.dataset.fomioBytesMetaBound = "true";
}
