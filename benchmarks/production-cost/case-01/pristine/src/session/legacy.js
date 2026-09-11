import { legacyTokens } from "../stores/legacy-tokens.js";

export async function legacyRotate(req, res) {
  const refreshToken = await legacyTokens.rotate(req.body.refreshToken);
  res.json({ refreshToken });
}
