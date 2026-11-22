"use client";

import { useState } from "react";
import { Avatar, KV, Note, StatusChip } from "@/components/ui/bits";
import { ActionButton } from "@/components/ui/feedback";
import { bnDigits, money } from "@/lib/format";
import { policyLabel, settlementStatus } from "@/lib/labels";
import type { InventoryPolicy, SettlementStatus } from "@/lib/types";

type Row = {
  id: string; seller: string; status: SettlementStatus; policy: InventoryPolicy;
  tx: number; sales: number; sold: number; cash: number; verified: number;
  given: number; returned: number; found: number; earning: string;
};

const ROWS: Row[] = [
  { id: "sakib", seller: "সাকিব হোসেন", status: "discrepancy", policy: "dailyReturn", tx: 19, sales: 6800, sold: 15, cash: 6400, verified: 1500, given: 23, returned: 0, found: 5, earning: "প্রতি পিস ৳২৫ × ১৫ = ৳৩৭৫" },
  { id: "rakib", seller: "রাকিব হাসান", status: "closed", policy: "dailyReturn", tx: 21, sales: 7950, sold: 20, cash: 6200, verified: 6200, given: 30, returned: 10, found: 0, earning: "লাভের ৪০% = ৳৭৯০" },
  { id: "nusrat", seller: "নুসরাত জাহান", status: "submitted", policy: "carryForward", tx: 22, sales: 8120, sold: 21, cash: 7100, verified: 7100, given: 33, returned: 0, found: 12, earning: "দৈনিক ৳৫০০ + পিসে ৳১০ × ২১ = ৳৭১০" },
  { id: "mim", seller: "মিম আক্তার", status: "review", policy: "dailyReturn", tx: 14, sales: 5210, sold: 14, cash: 4900, verified: 4600, given: 20, returned: 6, found: 0, earning: "দৈনিক ৳৪৫০" },
];
const FILTERS: (SettlementStatus | "all")[] = ["all", "open", "submitted", "review", "discrepancy", "closed"];

export function SettlementsView() {
  const [filter, setFilter] = useState<SettlementStatus | "all">("all");
  const list = ROWS.filter((r) => filter === "all" || r.status === filter);
  const [selId, setSelId] = useState("sakib");
  const r = ROWS.find((x) => x.id === selId)!;
  const expected = r.given - r.sold - r.returned;
  const missing = r.policy === "dailyReturn" ? expected - r.found : 0;
  const cashDue = r.cash - r.verified;
  const blocked = r.status !== "closed" && (cashDue > 0 || (r.policy === "dailyReturn" && expected > 0));

  return (
    <>
      <div className="pills" role="group" aria-label="অবস্থা">
        {FILTERS.map((f) => (
          <button key={f} type="button" className={`pill${filter === f ? " on" : ""}`} onClick={() => setFilter(f)}>{f === "all" ? "সব" : settlementStatus[f][0]}</button>
        ))}
      </div>
      <div className="tw">
        <table style={{ minWidth: 760 }}>
          <thead><tr><th>সেলার</th><th>তারিখ</th><th className="n">মোট বিক্রি</th><th className="n">বাকি ক্যাশ</th><th className="n">স্টক বাকি</th><th>স্টকের নিয়ম</th><th>অবস্থা</th></tr></thead>
          <tbody>
            {list.map((x) => (
              <tr key={x.id} className={`click${x.id === selId ? " sel" : ""}`} onClick={() => setSelId(x.id)} tabIndex={0} onKeyDown={(e) => e.key === "Enter" && setSelId(x.id)}>
                <td><div className="sl"><Avatar name={x.seller} /><b>{x.seller}</b></div></td>
                <td>২১ নভেম্বর</td>
                <td className="n">{money(x.sales)}</td>
                <td className="n">{money(x.cash - x.verified)}</td>
                <td className="n">{bnDigits(x.given - x.sold - x.returned)} পিস</td>
                <td>{policyLabel[x.policy]}</td>
                <td><StatusChip value={settlementStatus[x.status]} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 14 }}>
        <div className="sh"><h2 className="h2">{r.seller} · ২১ নভেম্বর</h2><StatusChip value={settlementStatus[r.status]} /></div>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(250px, 1fr))", gap: 14 }}>
          <div><div className="t1" style={{ marginBottom: 4 }}>বিক্রি</div><KV label="লেনদেন">{bnDigits(r.tx)}টি</KV><KV label="মোট বিক্রি">{money(r.sales)}</KV><KV label="বিক্রিত পণ্য">{bnDigits(r.sold)} পিস</KV></div>
          <div><div className="t1" style={{ marginBottom: 4 }}>ক্যাশ</div><KV label="সংগ্রহ করা ক্যাশ">{money(r.cash)}</KV><KV label="যাচাই হওয়া জমা">{money(r.verified)}</KV><KV label="বাকি"><span style={cashDue ? { color: "#85560C" } : undefined}>{money(cashDue)}</span></KV></div>
          <div><div className="t1" style={{ marginBottom: 4 }}>স্টক</div><KV label="দেওয়া">{bnDigits(r.given)} পিস</KV><KV label="বিক্রি / ফেরত">{bnDigits(r.sold)} / {bnDigits(r.returned)}</KV><KV label="থাকার কথা">{bnDigits(expected)} পিস</KV>{r.policy === "dailyReturn" && expected > 0 ? <KV label="পাওয়া গেছে"><span style={missing ? { color: "#A92F2F" } : undefined}>{bnDigits(r.found)} পিস{missing ? ` (${bnDigits(missing)} কম)` : ""}</span></KV> : null}</div>
          <div><div className="t1" style={{ marginBottom: 4 }}>আয়</div><KV label="হিসাব">{r.earning}</KV><KV label="অনুমোদিত আয়">{r.status === "closed" ? "হ্যাঁ" : "বাকি"}</KV></div>
        </div>
        {r.status === "closed" ? (
          <Note>এই দিনের হিসাব বন্ধ হয়েছে।</Note>
        ) : blocked ? (
          <Note kind="danger" icon="flag">
            {missing > 0 ? `${bnDigits(missing)} পিস পণ্য পাওয়া যাচ্ছে না। ` : ""}
            {cashDue > 0 ? `${money(cashDue)} ক্যাশ জমা হয়নি। ` : ""}
            “{policyLabel[r.policy]}” নিয়মে দিন বন্ধের আগে এগুলো মেটাতে হবে বা ব্যতিক্রম হিসেবে রেকর্ড করতে হবে।
          </Note>
        ) : null}
        {r.status !== "closed" ? (
          <div className="actions">
            <ActionButton disabled={blocked} confirm={{ title: "হিসাব অনুমোদন করে দিন বন্ধ করবেন?", message: "বন্ধের পর এই দিনের বিক্রি আর যোগ করা যাবে না।", label: "দিন বন্ধ করুন" }}>হিসাব অনুমোদন ও দিন বন্ধ</ActionButton>
            <ActionButton className="btn o">সংশোধন চাই</ActionButton>
            <ActionButton className="btn g" confirm={{ title: "অনুমোদিত ব্যতিক্রম রেকর্ড করবেন?", message: "কারণসহ রেকর্ড হবে এবং অডিট লগে থাকবে।", label: "রেকর্ড করুন" }}>অনুমোদিত ব্যতিক্রম রেকর্ড</ActionButton>
          </div>
        ) : null}
        <div className="mu">“পরের দিনে চলবে” নিয়মের সেলারদের বাকি স্টক দিন বন্ধের পরও তাদের নামেই থাকে।</div>
      </section>
    </>
  );
}
