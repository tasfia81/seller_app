import { cookies } from "next/headers";
import { API_URL, SESSION_COOKIE } from "@/lib/api/config";

const KINDS = new Set(["nid_front", "nid_back", "photo"]);

/** Streams an applicant's document from the backend with the admin's token. Never cached. */
export async function GET(_req: Request, ctx: RouteContext<"/api/files/applications/[id]/[kind]">) {
  const { id, kind } = await ctx.params;
  const token = (await cookies()).get(SESSION_COOKIE)?.value;
  if (!token) return new Response("লগইন করুন।", { status: 401 });
  if (!KINDS.has(kind) || !/^[\w-]+$/.test(id)) return new Response("ভুল অনুরোধ।", { status: 400 });
  const res = await fetch(`${API_URL}/admin/applications/${id}/documents/${kind}`, { headers: { Authorization: `Bearer ${token}` }, cache: "no-store" });
  if (!res.ok) return new Response("ছবি পাওয়া যায়নি।", { status: res.status });
  return new Response(res.body, {
    headers: { "Content-Type": res.headers.get("Content-Type") ?? "image/jpeg", "Cache-Control": "no-store, private" },
  });
}
