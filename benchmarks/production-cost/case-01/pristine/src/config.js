export function config(env = process.env) {
  return { sessionV2: env.SESSION_V2 === "1" };
}
