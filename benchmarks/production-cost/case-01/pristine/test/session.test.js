import test from "node:test";
import assert from "node:assert/strict";
import { legacyTokens } from "../src/stores/legacy-tokens.js";
import { v2Tokens } from "../src/stores/v2-tokens.js";

test("legacy rotation issues a valid new token", async () => {
  const next = await legacyTokens.rotate("legacy-old");
  assert.equal(legacyTokens.valid(next), true);
});

test("v2 rotation revokes the presented token", async () => {
  const next = await v2Tokens.rotate("v2-old");
  assert.equal(v2Tokens.valid(next), true);
  assert.equal(v2Tokens.valid("v2-old"), false);
});
