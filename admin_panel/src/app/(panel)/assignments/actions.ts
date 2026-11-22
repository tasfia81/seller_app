"use server";

import { refresh } from "next/cache";
import { redirect } from "next/navigation";
import { api, toResult } from "@/lib/api/server";
import type { ApiAssignment } from "@/lib/api/types";

export async function createAssignment(data: {
  seller_id: string;
  items: { product_id: string; variant: string | null; quantity: number }[];
  price_mode: "fixed" | "flexible";
  discount_allowed: boolean;
  policy: "seller_default" | "daily_return" | "carry_forward";
}) {
  const r = await toResult(() => api.post<ApiAssignment>("/admin/assignments", data));
  if (!r.ok) return r;
  redirect(`/assignments/${r.data.id}`);
}

export async function cancelAssignment(id: string) {
  const r = await toResult(() => api.post(`/admin/assignments/${encodeURIComponent(id)}/cancel`), "বরাদ্দ বাতিল হয়েছে, স্টক গুদামে ফিরেছে।");
  if (r.ok) refresh();
  return r;
}

export async function moveSellerStock(
  kind: "recall" | "seller_to_seller" | "damage",
  data: { seller_id: string; to_seller_id?: string; product_id: string; variant: string | null; quantity: number; reason: string },
) {
  const r =
    kind === "damage"
      ? await toResult(() => api.post("/admin/inventory/damages", { product_id: data.product_id, variant: data.variant, quantity: data.quantity, seller_id: data.seller_id, reason: data.reason }), "ক্ষতি রেকর্ড হয়েছে।")
      : await toResult(
          () => api.post("/admin/inventory/transfers", { kind, ...data, to_seller_id: kind === "seller_to_seller" ? data.to_seller_id : null }),
          kind === "recall" ? "ফেরত ডাকা হয়েছে — গুদামে হাতে পেলে “ফেরত ও ক্ষতি” পেজে “পেয়েছি” দিন।" : "অন্য সেলারের জন্য নতুন বরাদ্দ তৈরি হয়েছে (হস্তান্তর বাকি)।",
        );
  if (r.ok) refresh();
  return r;
}

export async function closeAssignment(id: string) {
  const r = await toResult(() => api.post(`/admin/assignments/${encodeURIComponent(id)}/close`), "বরাদ্দ বন্ধ হয়েছে।");
  if (r.ok) refresh();
  return r;
}
