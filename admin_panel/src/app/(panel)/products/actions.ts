"use server";

import { refresh } from "next/cache";
import { redirect } from "next/navigation";
import { api, toResult } from "@/lib/api/server";
import type { ApiProduct, ApiUnit } from "@/lib/api/types";

const enc = encodeURIComponent;

export async function createCategory(name: string) {
  const r = await toResult(() => api.post("/admin/categories", { name }), "ক্যাটাগরি যোগ হয়েছে।");
  if (r.ok) refresh();
  return r;
}

export async function renameCategory(id: string, name: string) {
  const r = await toResult(() => api.patch(`/admin/categories/${enc(id)}`, { name }), "নাম বদলানো হয়েছে।");
  if (r.ok) refresh();
  return r;
}

export async function archiveCategory(id: string, archive: boolean) {
  const r = await toResult(() => api.post(`/admin/categories/${enc(id)}/${archive ? "archive" : "restore"}`), archive ? "আর্কাইভ হয়েছে।" : "আবার চালু হয়েছে।");
  if (r.ok) refresh();
  return r;
}

export interface ProductInput {
  name: string;
  category_id: string;
  sku: string;
  description: string | null;
  unit: ApiUnit;
  quantity_step: number;
  unit_cost: number;
  price: number;
  min_price: number | null;
  max_price: number | null;
  price_editable: boolean;
  variant_label: string | null;
  variants: string[];
  low_stock_at: number;
  track_stock: boolean;
  track_expiry: boolean;
  discount_allowed: boolean;
  active: boolean;
}

/** Create, or update an existing product (SKU, unit and step can't change once sold). */
export async function saveProduct(id: string | null, data: ProductInput) {
  if (!id) {
    const r = await toResult(() => api.post<ApiProduct>("/admin/products", data));
    if (!r.ok) return r;
    redirect("/products");
  }
  const changes = {
    name: data.name, category_id: data.category_id, description: data.description, unit_cost: data.unit_cost, price: data.price,
    min_price: data.min_price, max_price: data.max_price, price_editable: data.price_editable, variants: data.variants,
    low_stock_at: data.low_stock_at, discount_allowed: data.discount_allowed, active: data.active,
  };
  const r = await toResult(() => api.patch<ApiProduct>(`/admin/products/${enc(id)}`, changes));
  if (!r.ok) return r;
  redirect("/products");
}
