"use client";

import Link from "next/link";
import { useState } from "react";
import { Icon } from "@/components/ui/Icon";
import { EmptyState, KV, Kpi, Note } from "@/components/ui/bits";
import { ActionButton, Pills } from "@/components/ui/feedback";
import { bnDigits, money } from "@/lib/format";
import { paymentLabel } from "@/lib/labels";
import type { PaymentMethod, Sale } from "@/lib/types";

export function SalesMonitor({ items }: { items: Sale[] }) {
  const [seller, setSeller] = useState("");
  const [payment, setPayment] = useState<PaymentMethod | "">("");
  const list = items.filter((s) => (!seller || s.seller === seller) && (!payment || s.payment === payment));
  const [selId, setSelId] = useState(items[0]?.id);
  const sel = list.find((s) => s.id === selId) ?? list[0];

  const total = list.reduce((a, s) => a + s.qty * s.unitPrice, 0);
  const qty = list.reduce((a, s) => a + s.qty, 0);
  const profit = list.reduce((a, s) => a + s.qty * (s.unitPrice - s.cost), 0);
  const commission = list.reduce((a, s) => a + s.qty * (s.unitPrice - s.cost) * s.commissionRate, 0);
  const sellers = [...new Set(items.map((s) => s.seller))];

  return (
    <>
      <div className="sh">
        <Pills label="সময়" options={["আজ", "গতকাল", "সপ্তাহ", "মাস", "তারিখ"]} />
        <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
          <select className="in" aria-label="সেলার" style={{ width: "auto", minWidth: 150, height: 36 }} value={seller} onChange={(e) => setSeller(e.target.value)}>
            <option value="">সব সেলার</option>
            {sellers.map((s) => <option key={s}>{s}</option>)}
          </select>
          <select className="in" aria-label="পেমেন্ট" style={{ width: "auto", minWidth: 140, height: 36 }} value={payment} onChange={(e) => setPayment(e.target.value as PaymentMethod | "")}>
            <option value="">সব পেমেন্ট</option>
            <option value="cash">ক্যাশ</option><option value="bkash">বিকাশ</option><option value="nagad">নগদ</option>
          </select>
        </div>
      </div>
      <div className="kpis">
        <Kpi label="মোট বিক্রি" value={money(total)} />
        <Kpi label="লেনদেন" value={bnDigits(list.length)} />
        <Kpi label="বিক্রিত পণ্য" value={`${bnDigits(qty)} পিস`} />
        <Kpi label="মোট লাভ" value={money(profit)} />
        <Kpi label="সেলারদের কমিশন" value={money(commission)} />
      </div>
      <div className="two">
        <div className="a">
          <div className="mu" style={{ display: "flex", gap: 6, alignItems: "center" }}><Icon name="clock" size={16} />সার্ভার চালু হলে নতুন বিক্রি নিজে থেকে উপরে যোগ হবে — পেজ রিফ্রেশ করতে হবে না।</div>
          <div className="tw">
            {list.length === 0 ? (
              <EmptyState icon="receipt" title="এই ফিল্টারে কোনো বিক্রি নেই" />
            ) : (
              <table style={{ minWidth: 760 }}>
                <thead><tr><th>বিক্রি নম্বর</th><th>সময়</th><th>সেলার</th><th>পণ্য</th><th className="n">পরিমাণ</th><th className="n">টাকা</th><th>পেমেন্ট</th><th>অবস্থা</th></tr></thead>
                <tbody>
                  {list.map((s) => (
                    <tr key={s.id} className={`click${sel?.id === s.id ? " sel" : ""}`} onClick={() => setSelId(s.id)} tabIndex={0} onKeyDown={(e) => e.key === "Enter" && setSelId(s.id)}>
                      <td><b style={{ fontWeight: 600 }}>#{s.id}</b></td>
                      <td>{s.time}</td><td>{s.seller}</td><td>{s.product}</td>
                      <td className="n">{bnDigits(s.qty)}</td>
                      <td className="n"><b>{money(s.qty * s.unitPrice)}</b></td>
                      <td>{paymentLabel[s.payment]}</td>
                      <td>{s.status === "confirmed" ? <span className="ch ok">নিশ্চিত</span> : <span className="ch wa">সংশোধন চাওয়া</span>}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
        {sel ? (
          <div className="b">
            <section className="drawer">
              <div className="sh"><h2 className="h2">বিক্রি #{sel.id}</h2>{sel.status === "confirmed" ? <span className="ch ok">নিশ্চিত</span> : <span className="ch wa">সংশোধন চাওয়া</span>}</div>
              <div className="mu">আজ {sel.time} · {sel.seller}</div>
              <KV label="পণ্য">{sel.product}</KV>
              <KV label="পরিমাণ × দাম">{bnDigits(sel.qty)} × {money(sel.unitPrice)}</KV>
              <KV label="মোট বিক্রি">{money(sel.qty * sel.unitPrice)}</KV>
              <KV label="ক্রয়মূল্য (বিক্রির সময়ের)">{money(sel.qty * sel.cost)}</KV>
              <KV label="মোট লাভ"><span style={{ color: "#0F6A38" }}>{money(sel.qty * (sel.unitPrice - sel.cost))}</span></KV>
              <KV label="সেলারের কমিশন">{sel.commissionRate ? `${money(sel.qty * (sel.unitPrice - sel.cost) * sel.commissionRate)} (${bnDigits(sel.commissionRate * 100)}%)` : "অন্য নিয়মে"}</KV>
              <KV label="পেমেন্ট">{paymentLabel[sel.payment]}</KV>
              <KV label="টাকা গেছে">{sel.payment === "cash" ? "সেলারের হাতে (জমা দিতে হবে)" : "ব্যবসার অ্যাকাউন্টে"}</KV>
              {sel.payment !== "cash" ? <Note>বিকাশ/নগদে সরাসরি ব্যবসায় আসা টাকা সেলারের বাকি ক্যাশে যোগ হয় না।</Note> : null}
              <div className="actions">
                <ActionButton className="btn g sm">রসিদ</ActionButton>
                <Link className="btn g sm" href="/corrections">সংশোধনের ইতিহাস</Link>
              </div>
              <ActionButton className="btn r full" confirm={{ title: "রিফান্ড বা সমন্বয় শুরু করবেন?", message: "মূল বিক্রি মুছবে না — আলাদা সমন্বয় লেনদেন যোগ হবে এবং অডিট লগে থাকবে।", label: "শুরু করুন", danger: true }}>
                অনুমোদিত রিফান্ড / সমন্বয়
              </ActionButton>
            </section>
          </div>
        ) : null}
      </div>
    </>
  );
}
