import assert from "node:assert/strict";
import { test } from "node:test";
import {
  BAR_HIDE_DELTA_Y,
  BAR_HIDE_START_Y,
  BAR_MIN_SCROLLABLE,
  BAR_SHOW_DELTA_Y,
  nextBottomBarHidden,
} from "../javascripts/discourse/lib/fomio-bottom-bar-scroll.js";

const room = BAR_MIN_SCROLLABLE;

test("stays visible when hiding is not allowed", () => {
  assert.equal(
    nextBottomBarHidden({
      y: 400,
      previousY: 200,
      hidden: true,
      scrollableHeight: room,
      allowHide: false,
    }),
    false
  );
});

test("stays visible when the page is too short to scroll", () => {
  assert.equal(
    nextBottomBarHidden({
      y: 400,
      previousY: 200,
      hidden: false,
      scrollableHeight: room - 1,
      allowHide: true,
    }),
    false
  );
});

test("stays visible near the top of the page", () => {
  assert.equal(
    nextBottomBarHidden({
      y: BAR_HIDE_START_Y,
      previousY: 0,
      hidden: true,
      scrollableHeight: room,
      allowHide: true,
    }),
    false
  );
});

test("hides after a downward move past the top band", () => {
  assert.equal(
    nextBottomBarHidden({
      y: BAR_HIDE_START_Y + 1,
      previousY: BAR_HIDE_START_Y + 1 - BAR_HIDE_DELTA_Y,
      hidden: false,
      scrollableHeight: room,
      allowHide: true,
    }),
    true
  );
});

test("shows again after an upward move", () => {
  assert.equal(
    nextBottomBarHidden({
      y: 400,
      previousY: 400 + BAR_SHOW_DELTA_Y,
      hidden: true,
      scrollableHeight: room,
      allowHide: true,
    }),
    false
  );
});

test("keeps the current state for a small move", () => {
  assert.equal(
    nextBottomBarHidden({
      y: 300,
      previousY: 299,
      hidden: true,
      scrollableHeight: room,
      allowHide: true,
    }),
    true
  );
});
