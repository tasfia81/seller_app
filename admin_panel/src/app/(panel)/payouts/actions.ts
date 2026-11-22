"use server";

import { refresh } from "next/cache";
import { api, toResult } from "@/lib/api/server";

export async function createPayout(data: { seller_id: string; amount: number; method: string; reference: string | null; note: string | null; client_request_id: string }) {
  const r = await toResult(() => api.post("/admin/payouts", data), "পেমেন্ট রেকর্ড হয়েছে।");
  if (r.ok) refresh();
  return r;
}
