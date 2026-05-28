const listeners = new Set();
let isOpen = false;

function notify() {
  listeners.forEach((listener) => listener(isOpen));
}

export function openDesktopSearchPalette() {
  if (isOpen) {
    return;
  }

  isOpen = true;
  notify();
}

export function closeDesktopSearchPalette() {
  if (!isOpen) {
    return;
  }

  isOpen = false;
  notify();
}

export function subscribeDesktopSearchPalette(listener) {
  listeners.add(listener);
  listener(isOpen);

  return () => {
    listeners.delete(listener);
  };
}
