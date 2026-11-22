"use client";

import Link from "next/link";
import { useActionState, useState } from "react";
import { Icon } from "@/components/ui/Icon";
import { loginAction, type LoginState } from "./actions";

export function LoginForm({ expired }: { expired?: boolean }) {
  const [state, action, pending] = useActionState<LoginState, FormData>(loginAction, {});
  const [show, setShow] = useState(false);
  const fe = state.fieldErrors ?? {};

  return (
    <form className="auth-box" action={action} noValidate aria-label="অ্যাডমিন লগইন">
      <div>
        <h1 style={{ margin: "0 0 6px", fontSize: 26, fontWeight: 700 }}>লগইন করুন</h1>
        <p className="mu" style={{ margin: 0, fontSize: 14 }}>আপনার মোবাইল নম্বর বা ইমেইল দিয়ে</p>
      </div>
      {expired && !state.error ? (
        <div className="warn" role="status"><Icon name="clock" size={18} /><span>সেশন শেষ হয়েছে। আবার লগইন করুন।</span></div>
      ) : null}
      {state.error ? (
        <div className="danger" role="alert"><Icon name="alert" size={18} /><span>{state.error}</span></div>
      ) : null}
      <div className="f">
        <label htmlFor="id">মোবাইল নম্বর বা ইমেইল</label>
        <input id="id" name="identifier" defaultValue={state.identifier} className={`in${fe.id ? " e" : ""}`} placeholder="01XXXXXXXXX বা email@example.com" autoComplete="username" />
        {fe.id ? <span className="err">{fe.id}</span> : null}
      </div>
      <div className="f">
        <label htmlFor="pw">পাসওয়ার্ড</label>
        <div style={{ position: "relative" }}>
          <input id="pw" name="password" className={`in${fe.pw ? " e" : ""}`} type={show ? "text" : "password"} autoComplete="current-password" style={{ paddingRight: 52 }} />
          <button type="button" className="ib" aria-label={show ? "পাসওয়ার্ড লুকান" : "পাসওয়ার্ড দেখুন"} onClick={() => setShow(!show)} style={{ position: "absolute", right: 0, top: -1, color: "#5F6C64" }}>
            <Icon name="eye" />
          </button>
        </div>
        {fe.pw ? <span className="err">{fe.pw}</span> : null}
      </div>
      <div className="sh">
        <label className="ck">
          <input type="checkbox" name="remember" defaultChecked /> এই ডিভাইসে মনে রাখুন
        </label>
        <Link href="/forgot-password" style={{ fontSize: 13.5, fontWeight: 600, textDecoration: "none", padding: "10px 0" }}>
          পাসওয়ার্ড ভুলে গেছেন?
        </Link>
      </div>
      <button type="submit" className="btn full" style={{ height: 50, fontSize: 16 }} disabled={pending}>
        {pending ? "লগইন হচ্ছে…" : "লগইন করুন"}
      </button>
      <div className="info">
        <Icon name="shield" size={18} />
        <span>শুধু অনুমোদিত অ্যাডমিনদের জন্য। আপনার প্রতিটি কাজ অডিট লগে থাকে।</span>
      </div>
    </form>
  );
}
