"use server";

import { refresh } from "next/cache";
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

