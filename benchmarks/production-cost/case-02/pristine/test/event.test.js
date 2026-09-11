import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import { parseEvent } from "../src/event/parser.js";

test("persisted event", () => {
  const e = JSON.parse(fs.readFileSync(new URL("../fixtures/persisted-event.json", import.meta.url)));
  assert.equal(parseEvent(e), "hello");
});
