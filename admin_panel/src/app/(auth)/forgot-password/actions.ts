"use server";

import { API_URL } from "@/lib/api/config";

export async function recoverAdminPassword(mobile: string, code?: string, newPassword?: string) {
  const reset = code !== undefined && newPassword !== undefined;
  try {
    const response = await fetch(`${API_URL}/auth/admin/password/${reset ? "reset" : "otp"}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(reset ? { mobile, code, new_password: newPassword } : { mobile }),
      cache: "no-store",
    });
    if (!response.ok) {
      const body = await response.json().catch(() => null);
      return { ok: false, message: (body?.error?.message as string) ?? "সার্ভার অনুরোধ গ্রহণ করেনি।" };
    }
    return { ok: true, message: reset ? "পাসওয়ার্ড পরিবর্তন হয়েছে।" : "নিবন্ধিত নম্বর হলে SMS কোড পাঠানো হয়েছে।" };
  } catch {
    return { ok: false, message: "সার্ভারে যোগাযোগ করা যায়নি।" };
  }
}
