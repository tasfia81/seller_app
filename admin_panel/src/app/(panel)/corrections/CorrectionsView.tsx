"use client";

import Link from "next/link";
import { useState, useTransition } from "react";
import { EmptyState, KV, Note } from "@/components/ui/bits";
import { ConfirmDialog, useToast } from "@/components/ui/feedback";
import type { ApiCorrection } from "@/lib/api/types";
import { PAYMENT_LABELS } from "@/lib/api/labels";
import { bnDateTime, bnDigits, money } from "@/lib/format";
import { decideCorrection } from "./actions";

export type CorrectionTab = "open" | "approved" | "rejected";

const TAB_LABEL: Record<CorrectionTab, string> = { open: "অপেক্ষমাণ", approved: "অনুমোদিত", rejected: "বাতিল" };
const inTab = (c: ApiCorrection, t: CorrectionTab) => (t === "open" ? c.status === "pending" || c.status === "clarification" : c.status === t);
const chip = (c: ApiCorrection) =>
  c.status === "approved" ? <span className="ch ok">অনুমোদিত</span> : c.status === "rejected" ? <span className="ch er">বাতিল</span> : c.status === "clarification" ? <span className="ch inf">প্রশ্ন করা হয়েছে</span> : <span className="ch wa">অপেক্ষমাণ</span>;

function rows(c: ApiCorrection) {
  const after = { ...c.current, ...c.requested };
  const pay = (p: string) => PAYMENT_LABELS[p] ?? p;
  return [
    { label: "পরিমাণ", before: bnDigits(c.current.qty), after: bnDigits(after.qty) },
    { label: "একক দাম", before: money(c.current.unit_price), after: money(after.unit_price) },
    { label: "মোট", before: money(c.current.qty * c.current.unit_price), after: money(after.qty * after.unit_price) },
    { label: "পেমেন্ট", before: pay(c.current.payment), after: pay(after.payment) },
  ];
}

function summary(c: ApiCorrection) {
  const parts: string[] = [];
  if (c.requested.qty !== undefined) parts.push(`পরিমাণ ${bnDigits(c.current.qty)} → ${bnDigits(c.requested.qty)}`);
  if (c.requested.unit_price !== undefined) parts.push(`দাম ${money(c.current.unit_price)} → ${money(c.requested.unit_price)}`);
  if (c.requested.payment !== undefined) parts.push(`পেমেন্ট ${PAYMENT_LABELS[c.current.payment] ?? c.current.payment} → ${PAYMENT_LABELS[c.requested.payment] ?? c.requested.payment}`);
  return parts.join(" · ");
}

function impact(c: ApiCorrection) {
  const out: string[] = [];
  const cashMethods = ["cash", "other"];
  const after = { ...c.current, ...c.requested };
  const cashBefore = cashMethods.includes(c.current.payment) ? c.current.qty * c.current.unit_price : 0;
  const cashAfter = cashMethods.includes(after.payment) ? after.qty * after.unit_price : 0;
  const d = cashAfter - cashBefore;
  if (d > 0) out.push(`সেলারের বাকি ক্যাশ ${money(d)} বাড়বে।`);
  if (d < 0) out.push(`সেলারের বাকি ক্যাশ ${money(-d)} কমবে।`);
  const q = after.qty - c.current.qty;
  if (q < 0) out.push(`${bnDigits(-q)} ইউনিট সেলারের স্টকে ফিরবে।`);
  if (q > 0) out.push(`সেলারের স্টক থেকে আরও ${bnDigits(q)} ইউনিট কাটা যাবে।`);
  return out.length ? `অনুমোদন দিলে ${out.join(" ")}` : "অনুমোদন দিলে বিক্রির হিসাব নতুন তথ্যে বদলাবে।";
}

export function CorrectionsView({ all, tab, selectedId }: { all: ApiCorrection[]; tab: CorrectionTab; selectedId?: string }) {
  const toast = useToast();
  const [pending, start] = useTransition();
  const [note, setNote] = useState("");
  const [confirm, setConfirm] = useState<null | "approve" | "reject">(null);
  const list = all.filter((c) => inTab(c, tab));
  const r = list.find((c) => c.id === selectedId) ?? list[0];
  const openCount = all.filter((c) => inTab(c, "open")).length;

  const decide = (d: "approve" | "reject" | "clarify") => {
    if (!r) return;
    if (d === "clarify" && note.trim().length < 3) return toast("কী জানতে চান তা মন্তব্যে লিখুন।", true);
    start(async () => {
      const res = await decideCorrection(r.id, d, note);
      toast(res.ok ? (res.message ?? "সম্পন্ন হয়েছে।") : res.message, !res.ok);
      if (res.ok) setNote("");
    });
  };

  return (
    <>
      <div className="tabs" role="tablist" aria-label="অবস্থা">
        {(Object.keys(TAB_LABEL) as CorrectionTab[]).map((t) => (
          <Link key={t} role="tab" aria-selected={tab === t} className={`tab${tab === t ? " on" : ""}`} href={`/corrections?tab=${t}`} style={{ textDecoration: "none" }}>
            {TAB_LABEL[t]}{t === "open" && openCount ? <> <span className="ch wa">{bnDigits(openCount)}</span></> : null}
          </Link>
        ))}
      </div>
      {!r ? (
        <div className="cd"><EmptyState icon="receipt" title={tab === "open" ? "কোনো অপেক্ষমাণ অনুরোধ নেই" : "এখানে কিছু নেই"} text="সেলার অ্যাপ থেকে কোনো বিক্রি সংশোধন চাইলে এখানে আসবে।" /></div>
      ) : (
        <div className="two">
          <div className="b">
            {list.map((x) => (
              <Link key={x.id} href={`/corrections?tab=${tab}&id=${x.id}`} scroll={false} className={`card-btn${x.id === r.id ? " on" : ""}`} style={{ textDecoration: "none", color: "inherit" }}>
                <div className="sh" style={{ width: "100%" }}><b className="t1">{x.receipt_no}</b>{chip(x)}</div>
                <span className="mu">{x.seller_name} · {bnDateTime(x.created_at)}</span>
                <span style={{ fontSize: 13.5 }}>{summary(x)}</span>
              </Link>
            ))}
          </div>
          <div className="a">
            <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 14 }}>
              <div className="sh"><h2 className="h2">{r.receipt_no} সংশোধন</h2><Link className="btn g sm" href={`/sales?period=month&id=${r.sale_id}`}>মূল বিক্রি দেখুন</Link></div>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))", gap: 12 }}>
                <div style={{ border: "1px solid #E4EBE6", borderRadius: 12, padding: 12 }}>
                  <div className="mu" style={{ marginBottom: 6 }}>অনুরোধের সময়ের হিসাব</div>
                  {rows(r).map((x) => <KV key={x.label} label={x.label}>{x.before}</KV>)}
                </div>
                <div style={{ border: "2px solid #E6A23C", background: "#FFFCF5", borderRadius: 12, padding: 12 }}>
                  <div className="mu" style={{ marginBottom: 6 }}>সেলার যা চাইছেন</div>
                  {rows(r).map((x) => <KV key={x.label} label={x.label}><span style={x.before !== x.after ? { color: "#85560C", fontWeight: 600 } : undefined}>{x.after}</span></KV>)}
                </div>
              </div>
              <KV label="সেলার">{r.seller_name}</KV>
              <KV label="কারণ">{r.reason}</KV>
              <KV label="অনুরোধের সময়">{bnDateTime(r.created_at)}</KV>
              {r.admin_note ? <KV label="অ্যাডমিনের মন্তব্য">{r.admin_note}</KV> : null}
              {r.decided_at ? <KV label="সিদ্ধান্ত">{r.decided_by} · {bnDateTime(r.decided_at)}</KV> : null}
              {inTab(r, "open") ? (
                <>
                  <Note kind="warn" icon="cash">{impact(r)} মূল বিক্রি মুছবে না — সংশোধন আলাদা রেকর্ড হিসেবে থাকবে।</Note>
                  <div className="f"><label htmlFor="nt">আপনার মন্তব্য</label><textarea id="nt" className="in" value={note} onChange={(e) => setNote(e.target.value)} placeholder="যেমন: নগদ অ্যাকাউন্টে টাকা আসেনি, মিলিয়ে দেখা হয়েছে" /></div>
                  <div className="actions">
                    <button type="button" className="btn" disabled={pending} onClick={() => setConfirm("approve")}>অনুমোদন দিন</button>
                    <button type="button" className="btn o" disabled={pending || r.status === "clarification"} onClick={() => decide("clarify")}>আরও জানতে চাই</button>
                    <button type="button" className="btn r" disabled={pending} onClick={() => setConfirm("reject")}>বাতিল করুন</button>
                  </div>
                </>
              ) : null}
            </section>
          </div>
        </div>
      )}
      <ConfirmDialog open={confirm === "approve"} title="সংশোধন অনুমোদন দেবেন?" message={r ? impact(r) : ""} confirmLabel="অনুমোদন দিন" onConfirm={() => decide("approve")} onClose={() => setConfirm(null)} />
      <ConfirmDialog open={confirm === "reject"} title="সংশোধন বাতিল করবেন?" message="মূল বিক্রি যেমন আছে তেমন থাকবে।" confirmLabel="বাতিল করুন" danger onConfirm={() => decide("reject")} onClose={() => setConfirm(null)} />
    </>
  );
}
