import { v2Tokens } from "../stores/v2-tokens.js";

export async function v2Rotate(req, res) {
  const refreshToken = await v2Tokens.rotate(req.body.refreshToken);
  res.json({ refreshToken });
}
