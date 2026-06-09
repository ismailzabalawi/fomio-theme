const listeners = new Set();
let state = {
  filter: "inbox",
  activeGroupName: null,
  activeGroupFilter: "inbox",
  searchQuery: "",
  masterScrollTop: 0,
};

function notify() {
  listeners.forEach((listener) => listener({ ...state }));
}

export function subscribeMessagesState(listener) {
  listeners.add(listener);
  listener({ ...state });

  return () => {
    listeners.delete(listener);
  };
}

export function setMessagesState(patch) {
  state = { ...state, ...patch };
  notify();
}

export function getMessagesState() {
  return { ...state };
}

export function resetMessagesState() {
  state = {
    filter: "inbox",
    activeGroupName: null,
    activeGroupFilter: "inbox",
    searchQuery: "",
    masterScrollTop: 0,
  };
  notify();
}
