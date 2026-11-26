"use client";

import { useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { recoverAdminPassword } from "./actions";

const ascii = (value: string) => value.replace(/[০-৯]/g, (digit) => String(digit.charCodeAt(0) - 0x09e6));

export function ForgotFlow() {
  const router = useRouter();
  const [mobile, setMobile] = useState("");
  const [code, setCode] = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [sent, setSent] = useState(false);
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState("");

  async function send(reset: boolean) {
    const number = ascii(mobile).replace(/\D/g, "").replace(/^88(?=01)/, "");
    if (!/^01[3-9]\d{8}$/.test(number)) {
      setMessage("সঠিক মোবাইল নম্বর দিন।");
      return;
    }
    const otp = ascii(code);
    if (reset && (!/^\d{6}$/.test(otp) || password.length < 8 || !/\d/.test(password) || password !== confirm)) {
      setMessage("৬ সংখ্যার কোড এবং সংখ্যা-সহ অন্তত ৮ অক্ষরের মিল থাকা পাসওয়ার্ড দিন।");
      return;
    }
    setBusy(true);
    try {
      const result = await recoverAdminPassword(number, reset ? otp : undefined, reset ? password : undefined);
      setMessage(result.message);
      if (result.ok && reset) router.replace("/login");
      if (result.ok && !reset) setSent(true);
    } finally {
      setBusy(false);
    }
  }

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    void send(sent);
  }

  return <form className="f" onSubmit={submit}>
    <h1 className="h2">পাসওয়ার্ড পুনরুদ্ধার</h1>
    <label>নিবন্ধিত মোবাইল নম্বর<input className="in" value={mobile} inputMode="tel" disabled={sent || busy}
      onChange={(event) => setMobile(event.target.value)} required /></label>
    {sent ? <>
      <label>SMS কোড<input className="in" value={code} inputMode="numeric" autoComplete="one-time-code"
        maxLength={6} onChange={(event) => setCode(event.target.value)} required /></label>
      <label>নতুন পাসওয়ার্ড<input className="in" type="password" autoComplete="new-password"
        value={password} onChange={(event) => setPassword(event.target.value)} required /></label>
      <label>আবার লিখুন<input className="in" type="password" autoComplete="new-password"
        value={confirm} onChange={(event) => setConfirm(event.target.value)} required /></label>
      <button className="btn g" type="button" disabled={busy} onClick={() => void send(false)}>আবার কোড পাঠান</button>
      <button className="btn g" type="button" disabled={busy} onClick={() => { setSent(false); setCode(""); }}>নম্বর বদলান</button>
    </> : null}
    <button className="btn full" disabled={busy} type="submit">{sent ? "পাসওয়ার্ড সংরক্ষণ" : "কোড পাঠান"}</button>
    {message ? <p role="status">{message}</p> : null}
  </form>;
}
