"use server";

import { refresh } from "next/cache";
import { API_URL } from "@/lib/api/config";
import { api, toResult } from "@/lib/api/server";

export async function replySupport(id: string, text: string, requestId: string) {
  const r = await toResult(() => api.post(`/admin/support/threads/${encodeURIComponent(id)}/messages`, { text, client_request_id: requestId }), "উত্তর পাঠানো হয়েছে।");
  if (r.ok) refresh();
  return r;
}

export async function setSupportStatus(id: string, action: "resolve" | "reopen") {
  const r = await toResult(
    () => api.post(`/admin/support/threads/${encodeURIComponent(id)}/${action}`),
    action === "resolve" ? "সমাধান হয়েছে হিসেবে বন্ধ করা হলো।" : "কথোপকথন আবার খোলা হলো।",
  );
  if (r.ok) refresh();
  return r;
}


export async function openSupportLive() {
  const result = await toResult(() => api.post<{ ticket: string }>("/support/live-ticket"));
  if (!result.ok) return result;
  const url = new URL(process.env.SUPPORT_LIVE_URL ?? API_URL);
  if (!process.env.SUPPORT_LIVE_URL) {
    url.pathname = `${url.pathname.replace(/\/$/, "")}/support/live`;
    url.protocol = url.protocol === "https:" ? "wss:" : "ws:";
  }
  return { ok: true as const, ticket: result.data.ticket, url: url.toString() };
}
