"use server";

import { refresh } from "next/cache";
import { api, toResult } from "@/lib/api/server";

export async function saveCompensation(id: string, rule: {
  model: "profit" | "daily" | "per_unit" | "hybrid";
  profit_percent: number | null;
  daily_wage: number | null;
  per_unit: number | null;
  effective_from: string;
  reason: string;
}) {
  const result = await toResult(
    () => api.put(`/admin/sellers/${encodeURIComponent(id)}/compensation`, rule),
    "আয়ের নিয়ম সংরক্ষিত হয়েছে।",
  );
  if (result.ok) refresh();
  return result;
}
