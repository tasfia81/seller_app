import { cookies } from "next/headers";
import { API_URL, SESSION_COOKIE } from "@/lib/api/config";

export async function GET(_request: Request, context: RouteContext<"/api/files/returns/[id]">) {
  const { id } = await context.params;
  const token = (await cookies()).get(SESSION_COOKIE)?.value;
  if (!token) return new Response("লগইন করুন।", { status: 401 });
  if (!/^[\w-]+$/.test(id)) return new Response("ভুল অনুরোধ।", { status: 400 });
  const response = await fetch(`${API_URL}/admin/returns/${id}/photo`, {
    headers: { Authorization: `Bearer ${token}` }, cache: "no-store",
  });
  if (!response.ok) return new Response("ছবি পাওয়া যায়নি।", { status: response.status });
  return new Response(response.body, {
    headers: { "Content-Type": response.headers.get("Content-Type") ?? "image/jpeg", "Cache-Control": "no-store, private" },
  });
}
