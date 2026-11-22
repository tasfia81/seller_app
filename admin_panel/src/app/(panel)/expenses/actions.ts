"use server";

import { refresh } from "next/cache";
import { api, toResult } from "@/lib/api/server";

export async function addExpense(data: { category: string; amount: number; date: string; description: string; seller_id: string | null; product_id: string | null }) {
  const r = await toResult(() => api.post("/admin/expenses", data), "খরচ সংরক্ষণ হয়েছে।");
  if (r.ok) refresh();
  return r;
}
