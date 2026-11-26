"use server";

import { api, toResult } from "@/lib/api/server";

export async function revealInvestorNid(id: string) {
  return toResult(() => api.post<{ nid_number: string }>(
    `/admin/investor-applications/${encodeURIComponent(id)}/reveal-nid`,
  ));
}
