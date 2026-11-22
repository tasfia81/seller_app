"use server";

import { refresh } from "next/cache";
import { api, toResult } from "@/lib/api/server";
import type { ApiPolicy, ApiSellerStatus } from "@/lib/api/types";

const base = (id: string) => `/admin/sellers/${encodeURIComponent(id)}`;

export async function updateSeller(
  id: string,
  changes: { mobile?: string; present_address?: string; policy?: ApiPolicy; can_edit_price?: boolean; can_discount?: boolean; can_take_digital?: boolean },
) {
  const r = await toResult(() => api.patch(base(id), changes), "তথ্য সংরক্ষণ হয়েছে।");
  if (r.ok) refresh();
  return r;
}

export async function setSellerStatus(id: string, status: ApiSellerStatus) {
  const label = status === "active" ? "সেলার আবার চালু হয়েছে।" : status === "suspended" ? "সেলার স্থগিত হয়েছে — সব ডিভাইস থেকে লগআউট হয়েছে।" : "সেলার নিষ্ক্রিয় হয়েছে।";
  const r = await toResult(() => api.post(`${base(id)}/status/${status}`), label);
  if (r.ok) refresh();
  return r;
}

export async function revokeSessions(id: string) {
  return toResult(() => api.post(`${base(id)}/revoke-sessions`), "সব ডিভাইস থেকে লগআউট করানো হয়েছে।");
}
