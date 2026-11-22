"use client";

import { useState, useTransition } from "react";
import { Avatar, EmptyState, Note } from "@/components/ui/bits";
import { useToast } from "@/components/ui/feedback";
import { HANDOVER_METHOD_LABELS } from "@/lib/api/labels";
import type { ApiPayoutsOverview } from "@/lib/api/types";
import { bnDateTime, money, parseMoney } from "@/lib/format";
import { createPayout } from "./actions";

const METHODS = Object.entries(HANDOVER_METHOD_LABELS);
const newKey = () => crypto.randomUUID();

export function PayoutsView({ data }: { data: ApiPayoutsOverview }) {
  const toast = useToast();
  const [pending, start] = useTransition();
  const [sellerId, setSellerId] = useState(data.sellers.find((r) => r.outstanding > 0)?.seller_id ?? data.sellers[0]?.seller_id ?? "");
  const [amount, setAmount] = useState("");
  const [method, setMethod] = useState("in_person");
  const [ref, setRef] = useState("");
  const [requestKey, setRequestKey] = useState(newKey);
  const row = data.sellers.find((r) => r.seller_id === sellerId);
  const payable = row?.outstanding ?? 0;
  const amt = parseMoney(amount);
  const error = !row ? "সেলার বাছুন।" : amt === null || amt <= 0 ? "সঠিক পরিমাণ দিন।" : amt > payable ? `দেওয়া যাবে সর্বোচ্চ ${money(payable)}।` : method !== "in_person" && !ref.trim() ? "লেনদেন নম্বর দিন।" : null;

  const submit = () => {
    if (error || pending || !row) return;
    start(async () => {
      const r = await createPayout({ seller_id: row.seller_id, amount: amt!, method, reference: ref.trim() || null, note: null, client_request_id: requestKey });
      toast(r.ok ? (r.message ?? "সম্পন্ন হয়েছে।") : r.message, !r.ok);
      if (r.ok) {
        setAmount("");
        setRef("");
        setRequestKey(newKey());
      }
    });
  };

  return (
    <div className="two">
      <div className="a">
        <h2 className="h2">সেলারভিত্তিক বাকি</h2>
        <div className="tw">
          {data.sellers.length === 0 ? (
            <EmptyState icon="users" title="কোনো সেলার নেই" />
          ) : (
            <table style={{ minWidth: 700 }}>
              <thead><tr><th>সেলার</th><th className="n">অর্জিত</th><th className="n">অনুমোদিত</th><th className="n">পরিশোধিত</th><th className="n">বাকি</th><th /></tr></thead>
              <tbody>
                {data.sellers.map((r) => (
                  <tr key={r.seller_id} className={r.seller_id === sellerId ? "sel" : undefined}>
                    <td><div className="sl"><Avatar name={r.seller_name} /><b>{r.seller_name}</b></div></td>
                    <td className="n">{money(r.earned)}</td><td className="n">{money(r.approved)}</td><td className="n">{money(r.paid)}</td>
                    <td className="n"><b style={r.outstanding ? { color: "#0F6A38" } : undefined}>{money(r.outstanding)}</b></td>
                    <td className="n">{r.outstanding > 0 ? <button type="button" className="btn sm" onClick={() => setSellerId(r.seller_id)}>পেমেন্ট দিন</button> : <button type="button" className="btn g sm" disabled>বাকি নেই</button>}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
        <Note>দিনের হিসাব অনুমোদন হলে সেলারের আয় “অনুমোদিত” হয় — শুধু অনুমোদিত আয় থেকেই পেমেন্ট দেওয়া যায়।</Note>
        <h2 className="h2">পেমেন্টের ইতিহাস</h2>
        <div className="tw">
          {data.history.length === 0 ? (
            <EmptyState icon="cash" title="এখনো কোনো পেমেন্ট হয়নি" />
          ) : (
            <table style={{ minWidth: 640 }}>
              <thead><tr><th>সময়</th><th>সেলার</th><th className="n">টাকা</th><th>মাধ্যম</th><th>রেফারেন্স</th><th>দিয়েছেন</th></tr></thead>
              <tbody>
                {data.history.map((h) => (
                  <tr key={h.id}><td>{bnDateTime(h.at)}</td><td>{h.seller_name}</td><td className="n">{money(h.amount)}</td><td>{HANDOVER_METHOD_LABELS[h.method] ?? h.method}</td><td className="mu">{h.reference ?? "—"}</td><td>{h.by}</td></tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
      <div className="b">
        <section className="drawer">
          <h2 className="h2">নতুন পেমেন্ট</h2>
          <div className="f"><label htmlFor="s">সেলার</label><select id="s" className="in" value={sellerId} onChange={(e) => setSellerId(e.target.value)}>{data.sellers.map((r) => <option key={r.seller_id} value={r.seller_id}>{r.seller_name}</option>)}</select></div>
          <div style={{ background: "#F4FAF6", borderRadius: 12, padding: "10px 12px", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <span className="mu">দেওয়া যাবে (অনুমোদিত বাকি)</span>
            <b style={{ fontSize: 18, color: "#0F6A38" }}>{money(payable)}</b>
          </div>
          <div className="f">
            <label htmlFor="a">পেমেন্টের পরিমাণ <i>*</i></label>
            <input id="a" className="in" value={amount} onChange={(e) => setAmount(e.target.value)} inputMode="decimal" />
            <span className="hint">আংশিক পেমেন্ট দেওয়া যায়{amt && amt <= payable ? ` · বাকি থাকবে ${money(payable - amt)}` : ""}</span>
          </div>
          <div className="f">
            <span className="lb">মাধ্যম <i>*</i></span>
            <div className="pills">{METHODS.map(([id, label]) => <button key={id} type="button" className={`pill${method === id ? " sel" : ""}`} aria-pressed={method === id} onClick={() => setMethod(id)}>{label}</button>)}</div>
          </div>
          <div className="f"><label htmlFor="r">লেনদেন নম্বর{method !== "in_person" ? <i> *</i> : null}</label><input id="r" className="in" placeholder="যেমন: TX7H2M" value={ref} onChange={(e) => setRef(e.target.value)} /></div>
          {amount && error ? <span className="err">{error}</span> : null}
          <button type="button" className="btn full" disabled={!!error || pending} onClick={submit}>{pending ? "রেকর্ড হচ্ছে…" : `${money(amt ?? 0)} পেমেন্ট রেকর্ড করুন`}</button>
          <div className="mu">এখানে শুধু দেওয়া পেমেন্টের রেকর্ড রাখা হয় — কোনো টাকা পাঠানো হয় না। একই অনুরোধ দুবার রেকর্ড হয় না।</div>
        </section>
      </div>
    </div>
  );
}
