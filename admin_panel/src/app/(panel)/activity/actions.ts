"use server";

import { api, toResult } from "@/lib/api/server";

export async function markNotificationsRead() {
  return toResult(() => api.post("/admin/notifications/read"));
}
