"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import { Avatar, EmptyState, KV, Note } from "@/components/ui/bits";
import { ConfirmDialog, useToast } from "@/components/ui/feedback";
import { HANDOVER_METHOD_LABELS } from "@/lib/api/labels";
import type { ApiCashOverview, ApiHandover, ApiHandoverStatus } from "@/lib/api/types";
import { bnDateTime, bnDigits, money, parseMoney } from "@/lib/format";
import { rejectHandover, verifyHandover } from "./actions";

const TABS: { id: ApiHandoverStatus; label: string; tone: string }[] = [
  { id: "pending", label: "যাচাই বাকি", tone: "wa" },
  { id: "verified", label: "যাচাই হয়েছে", tone: "ok" },
  { id: "rejected", label: "প্রত্যাখ্যাত", tone: "er" },
];
const chip = (s: ApiHandoverStatus) => {
  const t = TABS.find((x) => x.id === s)!;
  return <span className={`ch ${t.tone}`}>{t.label}</span>;
};

export function CashView({ items, sellers, tab, selectedId }: { items: ApiHandover[]; sellers: ApiCashOverview["sellers"]; tab: ApiHandoverStatus; selectedId?: string }) {
  const router = useRouter();
  const toast = useToast();
  const [pending, start] = useTransition();
  const list = items.filter((h) => h.status === tab);
  const sel = list.find((h) => h.id === selectedId) ?? list[0];
  const [received, setReceived] = useState(sel ? bnDigits(sel.amount) : "");
  const [note, setNote] = useState("");
  const [confirm, setConfirm] = useState<null | "verify" | "reject">(null);
  const recv = parseMoney(received);
  const invalid = !sel || recv === null || recv <= 0 || recv > sel.amount;
  const diff = sel && recv !== null ? sel.amount - recv : 0;
  const open = (id: string) => router.push(`/cash?tab=${tab}&id=${id}`, { scroll: false });

  const run = (kind: "verify" | "reject") =>
    sel &&
    start(async () => {
      const r = kind === "verify" ? await verifyHandover(sel.id, recv ?? 0, note) : await rejectHandover(sel.id, note);
      toast(r.ok ? (r.message ?? "সম্পন্ন হয়েছে।") : r.message, !r.ok);
    });

  return (
    <>
      <div className="two">
        <div className="a">
          <div className="tabs" role="tablist" aria-label="জমার অবস্থা">
            {TABS.map((t) => {
              const n = items.filter((h) => h.status === t.id).length;
              return (
                <Link key={t.id} role="tab" aria-selected={tab === t.id} className={`tab${tab === t.id ? " on" : ""}`} href={`/cash?tab=${t.id}`} style={{ textDecoration: "none" }}>
                  {t.label} {n ? <span className={`ch ${t.tone}`}>{bnDigits(n)}</span> : null}
                </Link>
              );
            })}
          </div>
          <div className="tw">
            {list.length === 0 ? (
              <EmptyState icon="cash" title="এই তালিকায় কিছু নেই" text={tab === "pending" ? "সেলার অ্যাপ থেকে ক্যাশ জমা দিলে এখানে যাচাইয়ের জন্য আসবে।" : undefined} />
            ) : (
              <table style={{ minWidth: 700 }}>
                <thead><tr><th>সেলার</th><th className="n">টাকা</th><th>মাধ্যম</th><th>রেফারেন্স</th><th>জমার সময়</th><th>অবস্থা</th></tr></thead>
                <tbody>
                  {list.map((h) => (
                    <tr key={h.id} className={`click${sel?.id === h.id ? " sel" : ""}`} onClick={() => open(h.id)} tabIndex={0} onKeyDown={(e) => e.key === "Enter" && open(h.id)}>
                      <td><div className="sl"><Avatar name={h.seller_name} /><b>{h.seller_name}</b></div></td>
                      <td className="n"><b>{money(h.amount)}</b></td>
                      <td>{HANDOVER_METHOD_LABELS[h.method] ?? h.method}</td>
                      <td className="mu">{h.reference ?? "—"}</td>
                      <td>{bnDateTime(h.submitted_at)}</td>
                      <td>{chip(h.status)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
          <section className="cd">
            <h2 className="h2" style={{ marginBottom: 8 }}>সেলারভিত্তিক ক্যাশ</h2>
            {sellers.length === 0 ? (
              <div className="mu">এখনো কোনো সেলারের কাছে ক্যাশ বিক্রি নেই।</div>
            ) : (
              <div className="tw">
                <table style={{ minWidth: 560 }}>
                  <thead><tr><th>সেলার</th><th className="n">সংগ্রহ</th><th className="n">যাচাই হয়েছে</th><th className="n">অপেক্ষায়</th><th className="n">বাকি</th></tr></thead>
                  <tbody>
                    {sellers.map((s) => (
                      <tr key={s.seller_id}>
                        <td><Link href={`/sellers/${s.seller_id}`}>{s.seller_name}</Link></td>
                        <td className="n">{money(s.collected)}</td>
                        <td className="n">{money(s.verified)}</td>
                        <td className="n">{money(s.pending_verification)}</td>
                        <td className="n"><b style={s.due > 0 ? { color: "#85560C" } : undefined}>{money(s.due)}</b></td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </section>
        </div>
        {sel ? (
          <div className="b">
            <section className="drawer">
              <div className="sh"><h2 className="h2">জমার বিস্তারিত</h2>{chip(sel.status)}</div>
              <div className="sl"><Avatar name={sel.seller_name} /><div><b>{sel.seller_name}</b><span className="mu">{bnDateTime(sel.submitted_at)} জমা দিয়েছেন</span></div></div>
              <KV label="জমার কথা বলেছেন">{money(sel.amount)}</KV>
              <KV label="মাধ্যম">{HANDOVER_METHOD_LABELS[sel.method] ?? sel.method}</KV>
              <KV label="রেফারেন্স">{sel.reference ?? "—"}</KV>
              <KV label="সেলারের নোট">{sel.note ?? "—"}</KV>
              {sel.status === "pending" ? (
                <>
                  <div className="f">
                    <label htmlFor="rc">আসলে পেয়েছেন <i>*</i></label>
                    <input id="rc" className={`in${invalid ? " e" : ""}`} value={received} onChange={(e) => setReceived(e.target.value)} inputMode="decimal" />
                    {invalid ? <span className="err">০ থেকে {money(sel.amount)}-এর মধ্যে পরিমাণ দিন।</span> : null}
                  </div>
                  {!invalid && diff > 0 ? <Note kind="danger" icon="alert">{money(diff)} কম পাওয়া গেছে। যাচাই করলে {money(recv!)} গ্রহণ হবে আর {money(diff)} সেলারের বাকিতে থেকে যাবে।</Note> : null}
                  <div className="f"><label htmlFor="nt">মন্তব্য</label><input id="nt" className="in" value={note} onChange={(e) => setNote(e.target.value)} placeholder="যেমন: বাকি ২০০ টাকা কাল দেবেন" /></div>
                  <div className="actions">
                    <button type="button" className="btn" disabled={invalid || pending} onClick={() => setConfirm("verify")}>{money(recv ?? 0)} গ্রহণ নিশ্চিত করুন</button>
                    <button type="button" className="btn r" disabled={pending} onClick={() => setConfirm("reject")}>প্রত্যাখ্যান</button>
                  </div>
                </>
              ) : (
                <>
                  {sel.status === "verified" ? <KV label="গ্রহণ করা হয়েছে">{money(sel.received_amount ?? 0)}{sel.shortfall ? ` (${money(sel.shortfall)} কম)` : ""}</KV> : null}
                  {[...sel.history].reverse().map((h, k) => (
                    <div key={k} className="tl"><i style={{ background: h.action === "verified" ? "#168447" : "#D64545" }} /><div><div className="t1">{h.action === "verified" ? "যাচাই করেছেন" : "প্রত্যাখ্যান করেছেন"} {h.by}</div><div className="mu">{bnDateTime(h.at)}{h.note ? ` · ${h.note}` : ""}</div></div></div>
                  ))}
                </>
              )}
            </section>
          </div>
        ) : null}
      </div>
      {sel ? (
        <>
          <ConfirmDialog open={confirm === "verify"} title="ক্যাশ গ্রহণ নিশ্চিত করবেন?" message={`${sel.seller_name}-এর কাছ থেকে ${money(recv ?? 0)} হাতে পেয়েছেন।`} confirmLabel="নিশ্চিত করুন" onConfirm={() => run("verify")} onClose={() => setConfirm(null)} />
          <ConfirmDialog open={confirm === "reject"} title="জমা প্রত্যাখ্যান করবেন?" message="সেলারের বাকি ক্যাশ যেমন আছে তেমন থাকবে।" confirmLabel="প্রত্যাখ্যান" danger onConfirm={() => run("reject")} onClose={() => setConfirm(null)} />
        </>
      ) : null}
    </>
  );
}
