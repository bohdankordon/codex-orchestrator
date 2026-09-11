import { legacyRotate } from "./legacy.js";
import { v2Rotate } from "./v2.js";

export function rotateHandler(cfg) {
  return cfg.sessionV2 ? v2Rotate : legacyRotate;
}
