"use server";

import { api, toResult } from "@/lib/api/server";
import type { FormResult } from "@/components/ui/ApiForm";
import { logoutAction } from "@/app/(auth)/login/actions";

export async function changePassword(_: FormResult | null, form: FormData): Promise<FormResult> {
  const next = String(form.get("new_password") ?? "");
  if (next !== form.get("confirm")) return { ok: false, message: "নতুন পাসওয়ার্ড দুটি মিলছে না।" };
  const result = await toResult(() => api.put("/auth/password", {
    current_password: String(form.get("current_password") ?? ""),
    new_password: next,
  }));
  if (result.ok) await logoutAction();
  return { ok: false, message: result.message ?? "পাসওয়ার্ড বদলানো যায়নি।" };
}

export async function revokeSessions(): Promise<FormResult> {
  const result = await toResult(() => api.post("/auth/sessions/revoke"));
  if (result.ok) await logoutAction();
  return { ok: false, message: result.message ?? "সেশন বন্ধ করা যায়নি।" };
}
