"use client";

import { useState } from "react";
import { Note } from "@/components/ui/bits";
import { ActionButton } from "@/components/ui/feedback";
import { bnDigits, money, parseMoney } from "@/lib/format";
import type { CompensationModel } from "@/lib/types";
import { sellers } from "@/lib/demo-data";

const MODELS: { id: CompensationModel; title: string; text: string }[] = [
  { id: "profit", title: "লাভের ভাগ", text: "প্রতিটি বিক্রির লাভের নির্দিষ্ট শতাংশ" },
  { id: "daily", title: "দৈনিক মজুরি", text: "কাজের দিনে নির্দিষ্ট টাকা" },
  { id: "perUnit", title: "প্রতি পিস কমিশন", text: "প্রতি বিক্রিত ইউনিটে নির্দিষ্ট টাকা" },
  { id: "hybrid", title: "মিশ্র", text: "মজুরি + পিস বোনাস বা লাভের ভাগ" },
];

export function CompensationForm() {
  const [seller, setSeller] = useState("rakib");
  const [model, setModel] = useState<CompensationModel>("profit");
  const [percent, setPercent] = useState("৫০");
  const [wage, setWage] = useState("৫০০");
  const [perUnit, setPerUnit] = useState("২৫");
  const [reason, setReason] = useState("");
  const [effective, setEffective] = useState("2026-12-01");

  const pct = parseMoney(percent);
  const pctError = model === "profit" || model === "hybrid" ? (pct === null || pct <= 0 || pct > 100 ? "১ থেকে ১০০-এর মধ্যে শতাংশ দিন।" : null) : null;
  const current = sellers.find((s) => s.id === seller);
  const newRule =
    model === "profit" ? `লাভের ${bnDigits(pct ?? 0)}%` :
    model === "daily" ? `দৈনিক ${money(parseMoney(wage) ?? 0)}` :
    model === "perUnit" ? `প্রতি পিসে ${money(parseMoney(perUnit) ?? 0)}` :
    `দৈনিক ${money(parseMoney(wage) ?? 0)} + লাভের ${bnDigits(pct ?? 0)}%`;
  const canSave = !pctError && reason.trim().length > 0;

  return (
    <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 14 }}>
      <div className="sh">
        <h2 className="h2">নতুন আয়ের নিয়ম</h2>
        <span className="ch inf">বর্তমান: {current?.compensation}</span>
      </div>
      <div className="f" style={{ maxWidth: 360 }}>
        <label htmlFor="sl">সেলার</label>
        <select id="sl" className="in" value={seller} onChange={(e) => setSeller(e.target.value)}>
          {sellers.filter((s) => s.status !== "inactive").map((s) => <option key={s.id} value={s.id}>{s.name} · {s.mobile}</option>)}
        </select>
      </div>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))", gap: 10 }} role="radiogroup" aria-label="আয়ের ধরন">
        {MODELS.map((m) => (
          <label key={m.id} className={`opt${model === m.id ? " on" : ""}`}>
            <input type="radio" name="model" checked={model === m.id} onChange={() => setModel(m.id)} />
            <span><b>{m.title}</b>{m.text}</span>
          </label>
        ))}
      </div>
      <div className="fg">
        {model === "profit" || model === "hybrid" ? (
          <div className="f">
            <label htmlFor="pc">লাভের কত শতাংশ <i>*</i></label>
            <input id="pc" className={`in${pctError ? " e" : ""}`} value={percent} onChange={(e) => setPercent(e.target.value)} inputMode="decimal" />
            {pctError ? <span className="err">{pctError}</span> : null}
          </div>
        ) : null}
        {model === "daily" || model === "hybrid" ? (
          <div className="f"><label htmlFor="wg">দৈনিক মজুরি (৳) <i>*</i></label><input id="wg" className="in" value={wage} onChange={(e) => setWage(e.target.value)} inputMode="decimal" /><span className="hint">কাজের দিন অ্যাডমিন অনুমোদন দিলে যোগ হবে</span></div>
        ) : null}
        {model === "perUnit" ? (
          <div className="f"><label htmlFor="pu">প্রতি পিসে কমিশন (৳) <i>*</i></label><input id="pu" className="in" value={perUnit} onChange={(e) => setPerUnit(e.target.value)} inputMode="decimal" /></div>
        ) : null}
        <div className="f"><label htmlFor="ef">কার্যকর তারিখ <i>*</i></label><input id="ef" type="date" className="in" value={effective} onChange={(e) => setEffective(e.target.value)} /><span className="hint">আগের দিনগুলোর আয় বদলাবে না</span></div>
      </div>

      {model === "profit" || model === "hybrid" ? (
        <div>
          <div className="mu" style={{ marginBottom: 6 }}>উদাহরণ হিসাব (জার্সি, ১ পিস)</div>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(120px, 1fr))", gap: 8, background: "#F7F9F8", borderRadius: 12, padding: 12 }}>
            {[["ক্রয়মূল্য", money(350)], ["বিক্রয়মূল্য", money(450)], ["মোট লাভ", money(100)], ["সেলারের ভাগ", money(((pct ?? 0) / 100) * 100)]].map(([l, v], i) => (
              <div key={l} style={{ display: "flex", flexDirection: "column", fontSize: 12, color: "#5F6C64" }}>{l}<b style={{ fontSize: 16, color: i === 3 ? "#0F6A38" : "#17251D" }}>{v}</b></div>
            ))}
          </div>
          <div className="mu" style={{ marginTop: 6 }}>চূড়ান্ত হিসাব সার্ভার করবে — এটা শুধু বোঝার জন্য।</div>
        </div>
      ) : null}

      <div className="f">
        <label htmlFor="rs">পরিবর্তনের কারণ <i>*</i></label>
        <input id="rs" className="in" value={reason} onChange={(e) => setReason(e.target.value)} placeholder="যেমন: ৩ মাস ভালো পারফরম্যান্সের জন্য ভাগ বাড়ানো হলো" />
      </div>
      <Note kind="warn"><b>নিশ্চিত করুন:</b> {current?.compensation} → {newRule} · {bnDigits(effective)} থেকে কার্যকর · আগের অর্জিত আয় যেমন আছে তেমন থাকবে।</Note>
      <div style={{ display: "flex", justifyContent: "flex-end" }}>
        <ActionButton disabled={!canSave} confirm={{ title: "আয়ের নিয়ম বদলাবেন?", message: `${current?.name}: ${newRule}। এটা অডিট লগে থাকবে।`, label: "সংরক্ষণ করুন" }}>
          নিয়ম সংরক্ষণ করুন
        </ActionButton>
      </div>
    </section>
  );
}
