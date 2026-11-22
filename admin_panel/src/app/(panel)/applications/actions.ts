"use server";

import { refresh } from "next/cache";
import { api, toResult } from "@/lib/api/server";

const path = (id: string, action: string) => `/admin/applications/${encodeURIComponent(id)}/${action}`;

async function act(id: string, action: string, body: unknown, message: string) {
  const r = await toResult(() => api.post(path(id, action), body), message);
  if (r.ok) refresh();
  return r;
}

export async function startReview(id: string) {
  return act(id, "start-review", {}, "যাচাই শুরু হয়েছে।");
}

export async function approveApplication(id: string) {
  return act(id, "approve", {}, "অনুমোদন দেওয়া হয়েছে। সেলার এখন লগইন করতে পারবেন।");
}

export async function rejectApplication(id: string, reason: string) {
  return act(id, "reject", { reason }, "আবেদন বাতিল হয়েছে।");
}

export async function requestInfo(id: string, fields: string[], message: string) {
  return act(id, "request-info", { fields, message }, "আরও তথ্য চাওয়া হয়েছে। সেলার অ্যাপে দেখতে পাবেন।");
}

/** Full NID — the backend writes this view to the audit log. */
export async function revealNid(id: string) {
  return toResult(() => api.post<{ nid_number: string }>(path(id, "reveal-nid")));
}
