export function parseEvent(e) {
  if (e.version !== 2) throw new Error("unsupported event version");
  if (typeof e.value !== "string") throw new Error("invalid value");
  return e.value;
}
