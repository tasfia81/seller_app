"use server";

import { refresh } from "next/cache";
import { api, toResult } from "@/lib/api/server";

export async function receiveStock(data: {
  product_id: string;
  variant: string | null;
  quantity: number;
  unit_cost: number;
  supplier: string | null;
  batch_ref: string | null;
}) {
  const r = await toResult(() => api.post<{ warehouse_qty: number; total_cost: number }>("/admin/inventory/receipts", data), "স্টক গুদামে যোগ হয়েছে।");
  if (r.ok) refresh();
  return r;
}
