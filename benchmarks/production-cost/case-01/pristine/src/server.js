import { config } from "./config.js";
import { rotateHandler } from "./session/handler.js";

export function routes(router, env = process.env) {
  router.post("/session/rotate", rotateHandler(config(env)));
}
