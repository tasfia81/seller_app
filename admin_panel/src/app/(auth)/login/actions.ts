"use server";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { SESSION_COOKIE } from "@/lib/api/config";
import { loginRequest } from "@/lib/api/server";

export type LoginState = { error?: string; identifier?: string; fieldErrors?: { id?: string; pw?: string } };

export async function loginAction(_prev: LoginState, form: FormData): Promise<LoginState> {
  const identifier = String(form.get("identifier") ?? "").trim();
  const password = String(form.get("password") ?? "");
  const remember = form.get("remember") === "on";
  const fieldErrors: LoginState["fieldErrors"] = {};
  if (!identifier) fieldErrors.id = "মোবাইল নম্বর বা ইমেইল দিন।";
  if (!password) fieldErrors.pw = "পাসওয়ার্ড দিন।";
  if (fieldErrors.id || fieldErrors.pw) return { fieldErrors, identifier };

  const res = await loginRequest(identifier, password);
  if (!res.ok) return { error: res.message, identifier };
  if (res.user.role !== "admin") return { identifier, error: "এই প্যানেল শুধু অ্যাডমিনদের জন্য। সেলার বা বিনিয়োগকারী হলে মোবাইল অ্যাপ ব্যবহার করুন।" };

  (await cookies()).set(SESSION_COOKIE, res.token, {
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    ...(remember ? { maxAge: 60 * 60 * 72 } : {}), // otherwise a browser-session cookie
  });
  redirect("/dashboard");
}

export async function logoutAction() {
  (await cookies()).delete(SESSION_COOKIE);
  redirect("/login");
}
