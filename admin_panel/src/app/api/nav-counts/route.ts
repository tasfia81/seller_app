import { api, ApiError } from "@/lib/api/server";

/** Sidebar badge counts (items waiting for an admin), proxied with the session token. */
export async function GET() {
  try {
    const counts = await api.get<Record<string, number>>("/admin/nav-counts");
    return Response.json(counts, { headers: { "Cache-Control": "no-store, private" } });
  } catch (e) {
    if (e instanceof ApiError) return Response.json({}, { status: e.status || 502 });
    throw e;
  }
}
