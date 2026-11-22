import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { API_URL, SESSION_COOKIE } from "./config";

/** Error returned by the backend, with its Bangla message. */
export class ApiError extends Error {
  constructor(
    public code: string,
    message: string,
    public status: number,
    public details?: unknown,
  ) {
    super(message);
  }
}

type Method = "GET" | "POST" | "PUT" | "PATCH" | "DELETE";

async function token(): Promise<string> {
  const value = (await cookies()).get(SESSION_COOKIE)?.value;
  if (!value) redirect("/login");
  return value;
}

/**
 * Server-only call to the FastAPI backend with the admin's token.
 * 401 → back to login. Other errors throw ApiError with the server's message.
 * Never cached: admin numbers must always be fresh.
 */
async function call<T>(method: Method, path: string, body?: unknown): Promise<T> {
  const t = await token();
  let res: Response;
  try {
    res = await fetch(`${API_URL}${path}`, {
      method,
      headers: { Authorization: `Bearer ${t}`, ...(body === undefined ? {} : { "Content-Type": "application/json" }) },
      body: body === undefined ? undefined : JSON.stringify(body),
      cache: "no-store",
    });
  } catch {
    throw new ApiError("server_unreachable", "সার্ভারের সাথে যোগাযোগ করা যাচ্ছে না। ব্যাকএন্ড চালু আছে কিনা দেখুন, তারপর আবার চেষ্টা করুন।", 0);
  }
  if (res.status === 401) redirect("/login?expired=1");
  const data = await res.json().catch(() => null);
  if (!res.ok) {
    throw new ApiError(data?.error?.code ?? "error", data?.error?.message ?? "কিছু একটা ভুল হয়েছে। আবার চেষ্টা করুন।", res.status, data?.error?.details);
  }
  return data as T;
}

export const api = {
  get: <T>(path: string) => call<T>("GET", path),
  post: <T>(path: string, body: unknown = {}) => call<T>("POST", path, body),
  put: <T>(path: string, body: unknown) => call<T>("PUT", path, body),
  patch: <T>(path: string, body: unknown) => call<T>("PATCH", path, body),
};

/** Login without a token (used by the login Server Action). */
export async function loginRequest(identifier: string, password: string) {
  try {
    const res = await fetch(`${API_URL}/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ identifier, password }),
      cache: "no-store",
    });
    const data = await res.json().catch(() => null);
    if (!res.ok) return { ok: false as const, message: (data?.error?.message as string) ?? "লগইন হয়নি।" };
    return { ok: true as const, token: data.access_token as string, user: data.user as { role: string; name: string } };
  } catch {
    return { ok: false as const, message: "সার্ভারের সাথে যোগাযোগ করা যাচ্ছে না। ব্যাকএন্ড চালু আছে কিনা দেখুন।" };
  }
}

/** Result shape every Server Action returns to the client. */
export type ActionResult<T = unknown> = { ok: true; data: T; message?: string } | { ok: false; message: string; code?: string };

/** Runs a backend call inside a Server Action and turns errors into a friendly result. */
export async function toResult<T>(fn: () => Promise<T>, message?: string): Promise<ActionResult<T>> {
  try {
    return { ok: true, data: await fn(), message };
  } catch (e) {
    if (e instanceof ApiError) return { ok: false, message: e.message, code: e.code };
    throw e; // redirects (401) and real bugs keep propagating
  }
}

/** For Server Components: load data, or get the backend's message to show instead. */
export async function load<T>(fn: () => Promise<T>): Promise<{ data: T; error?: undefined } | { data?: undefined; error: string }> {
  try {
    return { data: await fn() };
  } catch (e) {
    if (e instanceof ApiError) return { error: e.message };
    throw e; // redirects and real bugs keep propagating
  }
}
