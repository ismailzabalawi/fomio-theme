import { apiInitializer } from "discourse/lib/api";

/**
 * fomio-ui-components — interactive behaviour layer for the Fomio UI
 * component library defined in common.scss.
 *
 * Responsibilities:
 *   1. Dropdown — toggle aria-expanded; close on outside click / Escape;
 *      keyboard navigation; ArrowRight opens nested submenus.
 *   2. Tabs — click selects tab, manages aria-selected + panel visibility;
 *      Left/Right/Home/End keyboard navigation.
 *   3. Switch — click toggles aria-checked.
 *   4. Chip — click toggles aria-pressed; single-select within a
 *      [data-chip-group="single"] container.
 *   5. Surface observer — IntersectionObserver transitions
 *      .fomio-surface--hidden → .fomio-surface--observed on scroll.
 *
 * All state lives in aria attributes so SCSS can key off them without
 * extra JS-managed class names. Exceptions: .fomio-surface--hidden /
 * --observed carry CSS initial values that must exist before first paint.
 *
 * All handlers use event delegation on document — one listener per event
 * type for the full session lifetime, regardless of route changes.
 */

// ── Dropdown ───────────────────────────────────────────────────────────────

function openDropdown(trigger) {
  trigger.setAttribute("aria-expanded", "true");
  const panel = getDropdownPanel(trigger);
  if (panel) {
    panel.removeAttribute("inert");
    focusFirstDropdownItem(panel);
  }
}

function closeDropdown(trigger) {
  trigger.setAttribute("aria-expanded", "false");
  const panel = getDropdownPanel(trigger);
  if (panel) {
    panel.setAttribute("inert", "");
  }
}

function getDropdownPanel(trigger) {
  const wrapper = trigger.closest(".fomio-dropdown");
  return wrapper ? wrapper.querySelector(".fomio-dropdown__panel") : null;
}

function getOpenDropdownTrigger(root) {
  return root.querySelector(".fomio-dropdown__trigger[aria-expanded='true']");
}

function focusFirstDropdownItem(panel) {
  const first = panel.querySelector(
    ".fomio-dropdown__item:not([aria-disabled='true']):not([disabled])"
  );
  first?.focus();
}

function dropdownFocusableItems(panel) {
  return Array.from(
    panel.querySelectorAll(
      ".fomio-dropdown__item:not([aria-disabled='true']):not([disabled])"
    )
  );
}

function openSubmenu(item) {
  item.setAttribute("aria-expanded", "true");
  const subPanel = item.querySelector("[data-submenu-panel]");
  if (subPanel) {
    const firstItem = subPanel.querySelector(
      ".fomio-dropdown__item:not([aria-disabled='true'])"
    );
    firstItem?.focus();
  }
}

function closeSubmenu(item) {
  item.setAttribute("aria-expanded", "false");
}

function handleDropdownClick(event) {
  const trigger = event.target.closest(".fomio-dropdown__trigger");

  if (trigger) {
    event.stopPropagation();
    const isOpen = trigger.getAttribute("aria-expanded") === "true";

    // Close any other open top-level dropdown first
    const currentOpen = getOpenDropdownTrigger(document);
    if (currentOpen && currentOpen !== trigger) {
      closeDropdown(currentOpen);
    }

    isOpen ? closeDropdown(trigger) : openDropdown(trigger);
    return;
  }

  // Click outside — close the open dropdown
  const openTrigger = getOpenDropdownTrigger(document);
  if (openTrigger) {
    const wrapper = openTrigger.closest(".fomio-dropdown");
    if (wrapper && !wrapper.contains(event.target)) {
      closeDropdown(openTrigger);
    }
  }
}

function handleDropdownKeydown(event) {
  const { key } = event;

  // Escape — close open dropdown (or submenu first)
  if (key === "Escape") {
    // Check for open submenu first
    const openSubmenuItem = document.querySelector(
      ".fomio-dropdown__item[data-submenu][aria-expanded='true']"
    );
    if (openSubmenuItem) {
      closeSubmenu(openSubmenuItem);
      openSubmenuItem.focus();
      event.preventDefault();
      return;
    }

    const openTrigger = getOpenDropdownTrigger(document);
    if (openTrigger) {
      closeDropdown(openTrigger);
      openTrigger.focus();
      event.preventDefault();
    }
    return;
  }

  // Keys while focus is on the dropdown trigger
  const trigger = event.target.closest(".fomio-dropdown__trigger");
  if (trigger && (key === "ArrowDown" || key === "Enter" || key === " ")) {
    event.preventDefault();
    if (trigger.getAttribute("aria-expanded") !== "true") {
      openDropdown(trigger);
    } else {
      const panel = getDropdownPanel(trigger);
      if (panel) {
        focusFirstDropdownItem(panel);
      }
    }
    return;
  }

  // Keys while focus is inside a dropdown panel
  const panel = event.target.closest(".fomio-dropdown__panel");
  if (!panel) {
    return;
  }

  const items = dropdownFocusableItems(panel);
  const current = document.activeElement;
  const idx = items.indexOf(current);

  if (key === "ArrowDown") {
    event.preventDefault();
    (items[idx + 1] ?? items[0])?.focus();
  } else if (key === "ArrowUp") {
    event.preventDefault();
    (items[idx - 1] ?? items[items.length - 1])?.focus();
  } else if (key === "ArrowRight" && current?.hasAttribute("data-submenu")) {
    event.preventDefault();
    openSubmenu(current);
  } else if (key === "ArrowLeft") {
    // Close the submenu and return focus to its trigger
    const submenuPanel = event.target.closest("[data-submenu-panel]");
    if (submenuPanel) {
      event.preventDefault();
      const parentItem = submenuPanel.closest("[data-submenu]");
      if (parentItem) {
        closeSubmenu(parentItem);
        parentItem.focus();
      }
    }
  } else if (key === "Tab") {
    // Close panel; let focus leave naturally
    const wrapper = panel.closest(".fomio-dropdown");
    const wrapperTrigger = wrapper?.querySelector(".fomio-dropdown__trigger");
    if (wrapperTrigger) {
      closeDropdown(wrapperTrigger);
    }
  }
}

// ── Tabs ───────────────────────────────────────────────────────────────────

function selectTab(trigger) {
  const list = trigger.closest(".fomio-tabs__list");
  if (!list) {
    return;
  }

  // Deselect all sibling triggers
  list
    .querySelectorAll(".fomio-tabs__trigger[aria-selected='true']")
    .forEach((t) => {
      t.setAttribute("aria-selected", "false");
      // Hide the panel it controls
      const panelId = t.getAttribute("aria-controls");
      if (panelId) {
        const panel = document.getElementById(panelId);
        if (panel) {
          panel.setAttribute("aria-hidden", "true");
          panel.classList.remove("fomio-tabs__panel--active");
        }
      }
    });

  // Select this trigger
  trigger.setAttribute("aria-selected", "true");
  const targetId = trigger.getAttribute("aria-controls");
  if (targetId) {
    const targetPanel = document.getElementById(targetId);
    if (targetPanel) {
      targetPanel.setAttribute("aria-hidden", "false");
      targetPanel.classList.add("fomio-tabs__panel--active");
    }
  }
}

function handleTabClick(event) {
  const trigger = event.target.closest(".fomio-tabs__trigger");
  if (trigger) {
    selectTab(trigger);
  }
}

function handleTabKeydown(event) {
  const trigger = event.target.closest(".fomio-tabs__trigger");
  if (!trigger) {
    return;
  }

  const list = trigger.closest(".fomio-tabs__list");
  if (!list) {
    return;
  }

  const triggers = Array.from(
    list.querySelectorAll(".fomio-tabs__trigger:not([disabled])")
  );
  const idx = triggers.indexOf(trigger);

  if (event.key === "ArrowRight") {
    event.preventDefault();
    const next = triggers[idx + 1] ?? triggers[0];
    next?.focus();
    selectTab(next);
  } else if (event.key === "ArrowLeft") {
    event.preventDefault();
    const prev = triggers[idx - 1] ?? triggers[triggers.length - 1];
    prev?.focus();
    selectTab(prev);
  } else if (event.key === "Home") {
    event.preventDefault();
    triggers[0]?.focus();
    selectTab(triggers[0]);
  } else if (event.key === "End") {
    event.preventDefault();
    triggers[triggers.length - 1]?.focus();
    selectTab(triggers[triggers.length - 1]);
  }
}

// ── Switch ─────────────────────────────────────────────────────────────────

function handleSwitchClick(event) {
  const sw = event.target.closest(
    ".fomio-switch[role='switch']:not([aria-disabled='true']):not(.fomio-switch--disabled)"
  );
  if (!sw) {
    return;
  }
  const checked = sw.getAttribute("aria-checked") === "true";
  sw.setAttribute("aria-checked", checked ? "false" : "true");
}

function handleSwitchKeydown(event) {
  if (event.key !== " " && event.key !== "Enter") {
    return;
  }
  const sw = event.target.closest(".fomio-switch[role='switch']");
  if (sw) {
    event.preventDefault();
    handleSwitchClick({ target: sw });
  }
}

// ── Chip ───────────────────────────────────────────────────────────────────

function handleChipClick(event) {
  const chip = event.target.closest(
    ".fomio-chip[role='button']:not([aria-disabled='true']):not(.fomio-chip--disabled)"
  );
  if (!chip) {
    return;
  }

  const pressed = chip.getAttribute("aria-pressed") === "true";

  // Single-select group — deselect siblings before toggling
  const group = chip.closest("[data-chip-group='single']");
  if (group) {
    group
      .querySelectorAll(".fomio-chip[aria-pressed='true']")
      .forEach((c) => c.setAttribute("aria-pressed", "false"));
    // In a single-select group pressing the already-active chip keeps it active
    chip.setAttribute("aria-pressed", "true");
  } else {
    chip.setAttribute("aria-pressed", pressed ? "false" : "true");
  }
}

// ── Surface observer ───────────────────────────────────────────────────────

let surfaceObserver = null;

function setupSurfaceObserver() {
  if (typeof IntersectionObserver === "undefined") {
    document
      .querySelectorAll(".fomio-surface--hidden")
      .forEach(revealSurface);
    return;
  }

  surfaceObserver = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          revealSurface(entry.target);
          surfaceObserver.unobserve(entry.target);
        }
      });
    },
    {
      rootMargin: "0px 0px -48px 0px",
      threshold: 0.1,
    }
  );

  observeHiddenSurfaces();
}

function observeHiddenSurfaces() {
  if (!surfaceObserver) {
    return;
  }
  document.querySelectorAll(".fomio-surface--hidden").forEach((el) => {
    surfaceObserver.observe(el);
  });
}

function revealSurface(el) {
  el.classList.remove("fomio-surface--hidden");
  el.classList.add("fomio-surface--observed");
}

function rescanSurfaces() {
  observeHiddenSurfaces();
}

// ── Manual surface state helpers ───────────────────────────────────────────
// GJS connectors can trigger state changes via data attributes without
// importing this module (themes cannot cross-import lib/ files).
//
//   data-fomio-surface-observe="true"   → reveal immediately
//   data-fomio-surface-dormant="true"   → set to dormant

function applyManualSurfaceAttributes() {
  document
    .querySelectorAll("[data-fomio-surface-observe='true']")
    .forEach((el) => {
      el.removeAttribute("data-fomio-surface-observe");
      el.classList.remove("fomio-surface--hidden", "fomio-surface--dormant");
      el.classList.add("fomio-surface--observed");
    });

  document
    .querySelectorAll("[data-fomio-surface-dormant='true']")
    .forEach((el) => {
      el.removeAttribute("data-fomio-surface-dormant");
      el.classList.remove("fomio-surface--observed", "fomio-surface--hidden");
      el.classList.add("fomio-surface--dormant");
    });
}

// ── Initializer ────────────────────────────────────────────────────────────

export default apiInitializer("1.8.0", (api) => {
  // All handlers use event delegation on document — persists across routes
  document.addEventListener("click", handleDropdownClick);
  document.addEventListener("keydown", handleDropdownKeydown);
  document.addEventListener("click", handleTabClick);
  document.addEventListener("keydown", handleTabKeydown);
  document.addEventListener("click", handleSwitchClick);
  document.addEventListener("keydown", handleSwitchKeydown);
  document.addEventListener("click", handleChipClick);

  setupSurfaceObserver();
  applyManualSurfaceAttributes();

  api.onPageChange(() => {
    rescanSurfaces();
    applyManualSurfaceAttributes();
  });
});
