"use server";

import { refresh } from "next/cache";
import { api, toResult } from "@/lib/api/server";

export async function sendAdminMessage(payload: {
  audience: string;
  recipient_ids: string[];
  title: string;
  body: string;
  client_request_id: string;
}) {
  const result = await toResult(() => api.post("/admin/messages", payload), "বার্তা পাঠানো হয়েছে।");
  if (result.ok) refresh();
  return result;
}
