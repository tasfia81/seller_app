"use server";

import { refresh } from "next/cache";
import { api, toResult } from "@/lib/api/server";

const DONE = { approve: "সংশোধন অনুমোদিত হয়েছে।", reject: "সংশোধন বাতিল হয়েছে।", clarify: "সেলারের কাছে প্রশ্ন পাঠানো হয়েছে।" } as const;

export async function decideCorrection(id: string, decision: keyof typeof DONE, note: string) {
  const r = await toResult(() => api.post(`/admin/corrections/${encodeURIComponent(id)}/${decision}`, { note: note.trim() || null }), DONE[decision]);
  if (r.ok) refresh();
  return r;
}
