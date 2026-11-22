"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { PERIODS, type Period } from "@/components/dashboard/DateFilter";
import { EmptyState, KV, Kpi, Note } from "@/components/ui/bits";
import type { ApiSale, ApiSalesList, ApiSellerRow } from "@/lib/api/types";
import { PAYMENT_LABELS } from "@/lib/api/labels";
import { bnDateTime, bnDigits, money } from "@/lib/format";

type Filters = { period: Period; seller: string; payment: string; id?: string };

function href(f: Filters) {
  const q = new URLSearchParams({ period: f.period });
  if (f.seller) q.set("seller", f.seller);
  if (f.payment) q.set("payment", f.payment);
  if (f.id) q.set("id", f.id);
  return `/sales?${q}`;
}

const statusChip = (s: ApiSale) => <span className={`ch ${s.status === "confirmed" ? "ok" : "wa"}`}>{s.status_label}</span>;

export function SalesMonitor({ period, seller, payment, list, sellers, selected }: Filters & { list: ApiSalesList; sellers: ApiSellerRow[]; selected: ApiSale | null }) {
  const router = useRouter();
  const f: Filters = { period, seller, payment };
  const sm = list.summary;
  const sel = selected;

  return (
    <>
      <div className="sh">
        <div className="pills" role="group" aria-label="সময় বাছুন">
          {PERIODS.map((p) => (
            <Link key={p.id} href={href({ ...f, period: p.id })} className={`pill${period === p.id ? " on" : ""}`} aria-current={period === p.id ? "true" : undefined} style={{ textDecoration: "none" }}>{p.label}</Link>
          ))}
        </div>
        <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
          <select className="in" aria-label="সেলার" style={{ width: "auto", minWidth: 150, height: 36 }} value={seller} onChange={(e) => router.push(href({ ...f, seller: e.target.value }))}>
            <option value="">সব সেলার</option>
            {sellers.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
          </select>
          <select className="in" aria-label="পেমেন্ট" style={{ width: "auto", minWidth: 140, height: 36 }} value={payment} onChange={(e) => router.push(href({ ...f, payment: e.target.value }))}>
            <option value="">সব পেমেন্ট</option>
            {Object.entries(PAYMENT_LABELS).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
          </select>
        </div>
      </div>
      <div className="kpis">
        <Kpi label="মোট বিক্রি" value={money(sm.total)} />
        <Kpi label="লেনদেন" value={bnDigits(sm.count)} />
        <Kpi label="বিক্রিত পরিমাণ" value={bnDigits(sm.quantity)} />
        <Kpi label="মোট লাভ" value={money(sm.gross_profit ?? 0)} />
        <Kpi label="সেলারদের আয়" value={money(sm.seller_earnings ?? 0)} />
      </div>
      <div className="two">
        <div className="a">
          <div className="tw">
            {list.items.length === 0 ? (
              <EmptyState icon="receipt" title="এই সময়/ফিল্টারে কোনো বিক্রি নেই" text="সেলার অ্যাপ থেকে বিক্রি হলে এখানে দেখা যাবে।" />
            ) : (
              <table style={{ minWidth: 760 }}>
                <thead><tr><th>রসিদ</th><th>সময়</th><th>সেলার</th><th>পণ্য</th><th className="n">পরিমাণ</th><th className="n">টাকা</th><th>পেমেন্ট</th><th>অবস্থা</th></tr></thead>
                <tbody>
                  {list.items.map((s) => {
                    const go = () => router.push(href({ ...f, id: s.id }), { scroll: false });
                    return (
                      <tr key={s.id} className={`click${sel?.id === s.id ? " sel" : ""}`} onClick={go} tabIndex={0} onKeyDown={(e) => e.key === "Enter" && go()}>
                        <td><b style={{ fontWeight: 600 }}>{s.receipt_no}</b></td>
                        <td>{bnDateTime(s.created_at)}</td>
                        <td>{s.seller_name}</td>
                        <td>{s.product_name}</td>
                        <td className="n">{bnDigits(s.quantity)}</td>
                        <td className="n"><b>{money(s.total)}</b></td>
                        <td>{s.payment_label}</td>
                        <td>{statusChip(s)}</td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            )}
          </div>
        </div>
        {sel ? (
          <div className="b">
            <section className="drawer">
              <div className="sh"><h2 className="h2">রসিদ {sel.receipt_no}</h2>{statusChip(sel)}</div>
              <div className="mu">{bnDateTime(sel.created_at)} · {sel.seller_name}</div>
              <KV label="পণ্য">{sel.product_name}</KV>
              <KV label="পরিমাণ × দাম">{bnDigits(sel.quantity)} × {money(sel.unit_price)}</KV>
              <KV label="মোট বিক্রি">{money(sel.total)}</KV>
              <KV label="ক্রয়মূল্য (বিক্রির সময়ের)">{money(sel.cost_total ?? 0)}</KV>
              <KV label="মোট লাভ"><span style={{ color: "#0F6A38" }}>{money(sel.gross_profit ?? 0)}</span></KV>
              <KV label="সেলারের আয়">{money(sel.commission ?? 0)}</KV>
              <KV label="পেমেন্ট">{sel.payment_label}</KV>
              <KV label="টাকা গেছে">{sel.money_destination === "seller_cash" ? "সেলারের হাতে (জমা দিতে হবে)" : "ব্যবসার অ্যাকাউন্টে"}</KV>
              {sel.note ? <KV label="নোট">{sel.note}</KV> : null}
              {sel.corrected && sel.original ? (
                <Note kind="warn">সংশোধিত বিক্রি। মূল: {bnDigits(sel.original.qty)} × {money(sel.original.unit_price)} · {PAYMENT_LABELS[sel.original.payment] ?? sel.original.payment}</Note>
              ) : null}
              {sel.money_destination !== "seller_cash" ? <Note>বিকাশ/নগদে সরাসরি ব্যবসায় আসা টাকা সেলারের বাকি ক্যাশে যোগ হয় না।</Note> : null}
              {sel.corrections?.length ? (
                <div>
                  <div className="mu" style={{ marginBottom: 4 }}>সংশোধনের অনুরোধ</div>
                  {sel.corrections.map((c) => (
                    <div key={c.id} className="tl"><i style={{ background: c.status === "approved" ? "#168447" : c.status === "rejected" ? "#A92F2F" : "#E6A23C" }} /><div><div className="t1">{c.reason}</div><div className="mu">{bnDateTime(c.created_at)} · {c.status === "approved" ? "অনুমোদিত" : c.status === "rejected" ? "বাতিল" : "অপেক্ষমাণ"}</div></div></div>
                  ))}
                  <Link className="btn g sm" href="/corrections">সংশোধনের পেজে যান</Link>
                </div>
              ) : null}
            </section>
          </div>
        ) : null}
      </div>
    </>
  );
}
