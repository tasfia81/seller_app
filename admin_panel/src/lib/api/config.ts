/** Where the FastAPI backend lives (server-side only). */
export const API_URL = (process.env.API_URL ?? "http://127.0.0.1:8000/api/v1").replace(/\/$/, "");

/** httpOnly cookie that holds the admin's login token. */
export const SESSION_COOKIE = "ss_admin";
