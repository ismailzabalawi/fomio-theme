// Executes the adapter against the pinned core Toolbar, not a copy of it.
// Host-only dependencies are stubbed; this does not test Ember or a browser.
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { stripTypeScriptTypes } from "node:module";
import { test } from "node:test";
import { groupComposerFormatting } from "../javascripts/discourse/lib/fomio-composer-format.js";

assert.ok(process.env.DISCOURSE_SRC, "Set DISCOURSE_SRC to the 7b4f0970 export");
const source = await readFile(
  `${process.env.DISCOURSE_SRC}/frontend/discourse/app/lib/composer/toolbar.ts`,
  "utf8"
);
const executable = stripTypeScriptTypes(source).replace(
  /^import[\s\S]*?from\s+"[^"]+";\s*/gm,
  ""
);
const { default: Toolbar } = await import(
  `data:text/javascript,${encodeURIComponent(`
    const customPopupMenuOptions = [];
    const translateModKey = (value) => value;
    const waitForClosedKeyboard = async () => {};
    const PLATFORM_KEY_MODIFIER = "Ctrl";
    const i18n = (key) => key;
    ${executable}
  `)}`
);

const copy = { title: "theme.format", label: "Format" };
function fixture({ composerEvents = true, touch = false } = {}) {
  const events = [];
  const toolbar = new Toolbar({
    showLink: true,
    capabilities: { touch },
    siteSettings: { support_mixed_text_direction: true },
  });
  const event = {
    state: { inBold: true },
    selected: { start: 5, end: 10, value: "hello" },
    applySurround: (...args) => events.push(["surround", ...args]),
    applyHeading: (...args) => events.push(["heading", ...args]),
    applyList: (...args) => events.push(["list", ...args]),
    formatCode: () => events.push(["code"]),
    toggleDirection: () => events.push(["direction"]),
  };
  toolbar.context = {
    composerEvents,
    newToolbarEvent: (trim) => { events.push(["selection", trim]); return event; },
    send: (name, value) => events.push(["send", name, value]),
    appEvents: { trigger: (name, button) => events.push([name, button.id]) },
  };
  return { toolbar, events, event };
}
const allButtons = (toolbar) => toolbar.groups.flatMap((group) => group.buttons);
const menu = (toolbar) => allButtons(toolbar)
  .find((button) => button.id === "fomio-composer-format").popupMenu;

test("retains native commands, shortcuts, trimLeading and active formatting", async () => {
  const { toolbar, events, event } = fixture();
  const bold = toolbar.shortcuts["ctrl+b"];
  assert.equal(groupComposerFormatting(toolbar, copy), true);
  assert.equal(toolbar.shortcuts["ctrl+b"], bold);
  const option = menu(toolbar).options().find((item) => item.name === "bold");
  assert.equal(option.active(event), true);
  await menu(toolbar).action(option);
  assert.deepEqual(events[0], ["selection", true]);
  assert.deepEqual(events[1], ["surround", "**", "**", "bold_text"]);
  assert.deepEqual(events[2], ["d-editor:toolbar-button-clicked", "bold"]);
});

test("heading and list choices still invoke native popup commands", async () => {
  const { toolbar, events } = fixture();
  groupComposerFormatting(toolbar, copy);
  for (const name of ["heading-2", "list-bullet"]) {
    await menu(toolbar).action(menu(toolbar).options().find((item) => item.name === name));
  }
  assert.ok(events.some((event) => event[0] === "heading" && event[1] === 2));
  assert.ok(events.some((event) => event[0] === "list" && event[1] === "* "));
});

test("native link dialog receives its original toolbar event", async () => {
  const { toolbar, events, event } = fixture();
  groupComposerFormatting(toolbar, copy);
  await menu(toolbar).action(menu(toolbar).options().find((item) => item.name === "link"));
  assert.deepEqual(events[1], ["send", "showLinkModal", event]);
});

test("closing the formatting menu never issues an editor command", async () => {
  const { toolbar, events } = fixture();
  groupComposerFormatting(toolbar, copy);
  const close = menu(toolbar).options().find((item) => item.name === "fomio-format-close");
  assert.equal(close.label, "close");
  await menu(toolbar).action(close);
  assert.deepEqual(events, []);
});

test("leaves plugin buttons and subsequently added upload/options in place", () => {
  const { toolbar } = fixture();
  toolbar.addButton({ id: "plugin-tool", group: "extras", action: () => {} });
  const pluginButton = allButtons(toolbar).find((button) => button.id === "plugin-tool");
  groupComposerFormatting(toolbar, copy);
  toolbar.addButton({ id: "upload", group: "insertions", action: () => {} });
  toolbar.addButton({ id: "options", group: "extras", action: () => {} });
  assert.ok(allButtons(toolbar).includes(pluginButton));
  assert.deepEqual(allButtons(toolbar).map((button) => button.id), [
    "upload", "fomio-composer-format", "plugin-tool", "options",
  ]);
  assert.equal(groupComposerFormatting(toolbar, copy), false);
});

test("does not alter non-composer editors or unsupported toolbar shapes", () => {
  const { toolbar } = fixture({ composerEvents: false });
  const original = allButtons(toolbar);
  assert.equal(groupComposerFormatting(toolbar, copy), false);
  assert.deepEqual(allButtons(toolbar), original);
  assert.equal(groupComposerFormatting({ context: { composerEvents: true } }, copy), false);
});

test("respects native touch availability and reevaluates conditional tools", () => {
  const { toolbar } = fixture({ touch: true });
  const bold = allButtons(toolbar).find((button) => button.id === "bold");
  let allowed = true;
  bold.condition = () => allowed;
  groupComposerFormatting(toolbar, copy);
  assert.ok(!menu(toolbar).options().some((item) => item.name === "code"));
  assert.ok(menu(toolbar).options().some((item) => item.name === "bold"));
  allowed = false;
  assert.ok(!menu(toolbar).options().some((item) => item.name === "bold"));
});
