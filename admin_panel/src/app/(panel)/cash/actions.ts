"use server";

import { refresh } from "next/cache";
import { api, toResult } from "@/lib/api/server";

export async function verifyHandover(id: string, received: number, note: string) {
  const r = await toResult(() => api.post(`/admin/cash/handovers/${encodeURIComponent(id)}/verify`, { received_amount: received, note: note.trim() || null }), "ক্যাশ গ্রহণ নিশ্চিত হয়েছে।");
  if (r.ok) refresh();
  return r;
}

export async function rejectHandover(id: string, note: string) {
  const r = await toResult(() => api.post(`/admin/cash/handovers/${encodeURIComponent(id)}/reject`, { note: note.trim() || null }), "জমা প্রত্যাখ্যান করা হয়েছে।");
  if (r.ok) refresh();
  return r;
}
