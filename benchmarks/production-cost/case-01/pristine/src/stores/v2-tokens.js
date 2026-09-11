const valid = new Set(["v2-old"]);
let n = 0;

export const v2Tokens = {
  valid(t) {
    return valid.has(t);
  },
  async rotate(oldToken) {
    if (!valid.has(oldToken)) throw new Error("invalid");
    valid.delete(oldToken);
    const next = `v2-next-${++n}`;
    valid.add(next);
    return next;
  }
};
