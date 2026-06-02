import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  isAuthPath,
  isDiscourseNativePath,
  isFomioShellPath,
  normalizePath,
} from "../javascripts/discourse/lib/fomio-route-mode.js";

describe("fomio-route-mode", () => {
  it("normalizes query strings and trailing slashes", () => {
    assert.equal(normalizePath("/admin/users/?foo=1"), "/admin/users");
    assert.equal(normalizePath("/latest/?order=created"), "/latest");
  });

  it("classifies auth routes separately from shell routes", () => {
    assert.equal(isAuthPath("/login?fomio_web=1"), true);
    assert.equal(isDiscourseNativePath("/login?fomio_web=1"), false);
    assert.equal(isFomioShellPath("/login?fomio_web=1"), false);
  });

  it("keeps admin routes in native discourse mode", () => {
    assert.equal(isAuthPath("/admin"), false);
    assert.equal(isDiscourseNativePath("/admin"), true);
    assert.equal(isFomioShellPath("/admin"), false);
    assert.equal(isDiscourseNativePath("/admin/users/2/soma"), true);
  });

  it("treats reader routes as fomio shell surfaces", () => {
    assert.equal(isFomioShellPath("/latest"), true);
    assert.equal(isFomioShellPath("/c/design/12"), true);
    assert.equal(isFomioShellPath("/u/ismail"), true);
  });
});
