"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState, type FormEvent } from "react";
import { Icon } from "@/components/ui/Icon";

export function LoginForm() {
  const router = useRouter();
  const [show, setShow] = useState(false);
  const [id, setId] = useState("");
  const [pw, setPw] = useState("");
  const [errors, setErrors] = useState<{ id?: string; pw?: string }>({});
  const [loading, setLoading] = useState(false);

  const submit = (e: FormEvent) => {
    e.preventDefault();
    const next: typeof errors = {};
    if (!id.trim()) next.id = "মোবাইল নম্বর বা ইমেইল দিন।";
    if (!pw) next.pw = "পাসওয়ার্ড দিন।";
    setErrors(next);
    if (Object.keys(next).length) return;
    // Demo: no real authentication yet — opens the dashboard.
    setLoading(true);
    router.push("/dashboard");
  };

  return (
    <form className="auth-box" onSubmit={submit} noValidate aria-label="অ্যাডমিন লগইন">
      <div>
        <h1 style={{ margin: "0 0 6px", fontSize: 26, fontWeight: 700 }}>লগইন করুন</h1>
        <p className="mu" style={{ margin: 0, fontSize: 14 }}>আপনার মোবাইল নম্বর বা ইমেইল দিয়ে</p>
      </div>
      <div className="f">
        <label htmlFor="id">মোবাইল নম্বর বা ইমেইল</label>
        <input id="id" className={`in${errors.id ? " e" : ""}`} value={id} onChange={(e) => setId(e.target.value)} placeholder="01XXXXXXXXX বা email@example.com" autoComplete="username" />
        {errors.id ? <span className="err">{errors.id}</span> : null}
      </div>
      <div className="f">
        <label htmlFor="pw">পাসওয়ার্ড</label>
        <div style={{ position: "relative" }}>
          <input id="pw" className={`in${errors.pw ? " e" : ""}`} type={show ? "text" : "password"} value={pw} onChange={(e) => setPw(e.target.value)} autoComplete="current-password" style={{ paddingRight: 52 }} />
          <button type="button" className="ib" aria-label={show ? "পাসওয়ার্ড লুকান" : "পাসওয়ার্ড দেখুন"} onClick={() => setShow(!show)} style={{ position: "absolute", right: 0, top: -1, color: "#5F6C64" }}>
            <Icon name="eye" />
          </button>
        </div>
        {errors.pw ? <span className="err">{errors.pw}</span> : null}
      </div>
      <div className="sh">
        <label className="ck">
          <input type="checkbox" defaultChecked /> এই ডিভাইসে মনে রাখুন
        </label>
        <Link href="/forgot-password" style={{ fontSize: 13.5, fontWeight: 600, textDecoration: "none", padding: "10px 0" }}>
          পাসওয়ার্ড ভুলে গেছেন?
        </Link>
      </div>
      <button type="submit" className="btn full" style={{ height: 50, fontSize: 16 }} disabled={loading}>
        {loading ? "লগইন হচ্ছে…" : "লগইন করুন"}
      </button>
      <div className="info">
        <Icon name="shield" size={18} />
        <span>ডেমো: এখন যেকোনো তথ্য দিলেই ড্যাশবোর্ড খুলবে। সার্ভার চালু হলে আসল যাচাই হবে।</span>
      </div>
    </form>
  );
}
