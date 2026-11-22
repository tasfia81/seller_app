"use client";

import { useState } from "react";
import { Avatar } from "@/components/ui/bits";
import { useToast } from "@/components/ui/feedback";
import { money, parseMoney } from "@/lib/format";

const ROWS = [
  { id: "rakib", name: "রাকিব হাসান", earned: 12480, approved: 10620, paid: 8000 },
  { id: "nusrat", name: "নুসরাত জাহান", earned: 14200, approved: 14200, paid: 10000 },
  { id: "sakib", name: "সাকিব হোসেন", earned: 9875, approved: 8250, paid: 8250 },
  { id: "mim", name: "মিম আক্তার", earned: 9000, approved: 9000, paid: 7200 },
];
const HISTORY = [
  ["১৪ নভেম্বর", "রাকিব হাসান", 5000, "বিকাশ", "TX5Q81"],
  ["১৪ নভেম্বর", "নুসরাত জাহান", 10000, "ব্যাংক", "BRAC-2291"],
  ["৭ নভেম্বর", "রাকিব হাসান", 3000, "অফিসে হাতে", "—"],
] as const;
const METHODS = ["অফিসে হাতে", "বিকাশ", "নগদ", "ব্যাংক"];

export function PayoutsView() {
  const toast = useToast();
  const [sellerId, setSellerId] = useState("rakib");
  const [amount, setAmount] = useState("২,০০০");
  const [method, setMethod] = useState("বিকাশ");
  const [ref, setRef] = useState("");
  const [submitted, setSubmitted] = useState(false);
  const row = ROWS.find((r) => r.id === sellerId)!;
  const payable = row.approved - row.paid;
  const amt = parseMoney(amount);
  const error = amt === null || amt <= 0 ? "সঠিক পরিমাণ দিন।" : amt > payable ? `দেওয়া যাবে সর্বোচ্চ ${money(payable)}।` : method !== "অফিসে হাতে" && !ref.trim() ? "লেনদেন নম্বর দিন।" : null;

  const submit = () => {
    if (error || submitted) return;
    setSubmitted(true); // UI lock against double submission; backend enforces idempotency.
    toast("ডেমো: পেমেন্ট রেকর্ড সার্ভার চালু হলে সংরক্ষণ হবে। এখন কোনো টাকা পাঠানো বা রেকর্ড হয়নি।");
    setTimeout(() => setSubmitted(false), 2500);
  };

  return (
    <div className="two">
      <div className="a">
        <h2 className="h2">সেলারভিত্তিক বাকি</h2>
        <div className="tw">
          <table style={{ minWidth: 700 }}>
            <thead><tr><th>সেলার</th><th className="n">অর্জিত</th><th className="n">অনুমোদিত</th><th className="n">পরিশোধিত</th><th className="n">বাকি</th><th /></tr></thead>
            <tbody>
              {ROWS.map((r) => {
                const left = r.approved - r.paid;
                return (
                  <tr key={r.id} className={r.id === sellerId ? "sel" : undefined}>
                    <td><div className="sl"><Avatar name={r.name} /><b>{r.name}</b></div></td>
                    <td className="n">{money(r.earned)}</td><td className="n">{money(r.approved)}</td><td className="n">{money(r.paid)}</td>
                    <td className="n"><b style={left ? { color: "#0F6A38" } : undefined}>{money(left)}</b></td>
                    <td className="n">{left ? <button type="button" className="btn sm" onClick={() => setSellerId(r.id)}>পেমেন্ট দিন</button> : <button type="button" className="btn g sm" disabled>বাকি নেই</button>}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
        <h2 className="h2">পেমেন্টের ইতিহাস</h2>
        <div className="tw">
          <table style={{ minWidth: 640 }}>
            <thead><tr><th>তারিখ</th><th>সেলার</th><th className="n">টাকা</th><th>মাধ্যম</th><th>রেফারেন্স</th><th>অবস্থা</th></tr></thead>
            <tbody>
              {HISTORY.map((h) => (
                <tr key={h[0] + h[1] + h[2]}><td>{h[0]}</td><td>{h[1]}</td><td className="n">{money(h[2])}</td><td>{h[3]}</td><td className="mu">{h[4]}</td><td><span className="ch ok">পরিশোধিত</span></td></tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
      <div className="b">
        <section className="drawer">
          <h2 className="h2">নতুন পেমেন্ট</h2>
          <div className="f"><label htmlFor="s">সেলার</label><select id="s" className="in" value={sellerId} onChange={(e) => setSellerId(e.target.value)}>{ROWS.map((r) => <option key={r.id} value={r.id}>{r.name}</option>)}</select></div>
          <div style={{ background: "#F4FAF6", borderRadius: 12, padding: "10px 12px", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <span className="mu">দেওয়া যাবে (অনুমোদিত বাকি)</span>
            <b style={{ fontSize: 18, color: "#0F6A38" }}>{money(payable)}</b>
          </div>
          <div className="f">
            <label htmlFor="a">পেমেন্টের পরিমাণ <i>*</i></label>
            <input id="a" className={`in${error && error !== "লেনদেন নম্বর দিন।" ? " e" : ""}`} value={amount} onChange={(e) => setAmount(e.target.value)} inputMode="decimal" />
            <span className="hint">আংশিক পেমেন্ট দেওয়া যায়{amt && amt <= payable ? ` · বাকি থাকবে ${money(payable - amt)}` : ""}</span>
          </div>
          <div className="f">
            <span className="lb">মাধ্যম <i>*</i></span>
            <div className="pills">{METHODS.map((m) => <button key={m} type="button" className={`pill${method === m ? " sel" : ""}`} onClick={() => setMethod(m)}>{m}</button>)}</div>
          </div>
          <div className="f"><label htmlFor="r">লেনদেন নম্বর</label><input id="r" className="in" placeholder="যেমন: TX7H2M" value={ref} onChange={(e) => setRef(e.target.value)} /></div>
          {error ? <span className="err">{error}</span> : null}
          <button type="button" className="btn full" disabled={!!error || submitted} onClick={submit}>
            {submitted ? "পাঠানো হচ্ছে…" : `${money(amt ?? 0)} পেমেন্ট রেকর্ড করুন`}
          </button>
          <div className="mu">একবার চাপলেই বাটন বন্ধ হয়ে যায়, যাতে একই পেমেন্ট দুবার না হয়। সীমা আর দ্বিগুণ-পেমেন্ট সার্ভারও আটকাবে।</div>
        </section>
      </div>
    </div>
  );
}
