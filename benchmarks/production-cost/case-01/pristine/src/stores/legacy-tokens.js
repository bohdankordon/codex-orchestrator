const valid = new Set(["legacy-old"]);
let n = 0;

export const legacyTokens = {
  valid(t) {
    return valid.has(t);
  },
  async rotate(oldToken) {
    if (!valid.has(oldToken)) throw new Error("invalid");
    const next = `legacy-next-${++n}`;
    valid.add(next);
    return next;
  }
};
