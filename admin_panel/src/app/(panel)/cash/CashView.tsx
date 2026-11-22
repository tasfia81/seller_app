"use client";

import { useState } from "react";
import { Avatar, EmptyState, KV, Note, StatusChip } from "@/components/ui/bits";
import { ActionButton } from "@/components/ui/feedback";
import { bnDigits, money, parseMoney } from "@/lib/format";
import { paymentLabel, requestStatus } from "@/lib/labels";
import type { CashHandover, RequestStatus } from "@/lib/types";

const TABS: { id: RequestStatus; label: string }[] = [
  { id: "pending", label: "যাচাই বাকি" },
  { id: "verified", label: "যাচাই হয়েছে" },
  { id: "rejected", label: "প্রত্যাখ্যাত" },
];

export function CashView({ items }: { items: CashHandover[] }) {
  const [tab, setTab] = useState<RequestStatus>("pending");
  const list = items.filter((h) => h.status === tab);
  const [selId, setSelId] = useState(items[0]?.id);
  const sel = list.find((h) => h.id === selId) ?? list[0];
  const [received, setReceived] = useState<Record<string, string>>({});
  const recv = sel ? parseMoney(received[sel.id] ?? bnDigits(sel.amount)) : null;
  const diff = sel && recv !== null ? sel.amount - recv : 0;
  const invalid = recv === null || recv <= 0 || (sel ? recv > sel.amount : false);

  return (
    <div className="two">
      <div className="a">
        <div className="tabs" role="tablist" aria-label="জমার অবস্থা">
          {TABS.map((t) => {
            const n = items.filter((h) => h.status === t.id).length;
            return (
              <button key={t.id} type="button" role="tab" aria-selected={tab === t.id} className={`tab${tab === t.id ? " on" : ""}`} onClick={() => setTab(t.id)}>
                {t.label} {n ? <span className={`ch ${requestStatus[t.id][1]}`}>{bnDigits(n)}</span> : null}
              </button>
            );
          })}
        </div>
        <div className="tw">
          {list.length === 0 ? (
            <EmptyState icon="cash" title="এই তালিকায় কিছু নেই" />
          ) : (
            <table style={{ minWidth: 700 }}>
              <thead><tr><th>সেলার</th><th className="n">টাকা</th><th>মাধ্যম</th><th>রেফারেন্স</th><th>জমার সময়</th><th>অবস্থা</th></tr></thead>
              <tbody>
                {list.map((h) => (
                  <tr key={h.id} className={`click${sel?.id === h.id ? " sel" : ""}`} onClick={() => setSelId(h.id)} tabIndex={0} onKeyDown={(e) => e.key === "Enter" && setSelId(h.id)}>
                    <td><div className="sl"><Avatar name={h.seller} /><b>{h.seller}</b></div></td>
                    <td className="n"><b>{money(h.amount)}</b></td>
                    <td>{paymentLabel[h.method]}</td>
                    <td className="mu">{h.reference ?? "—"}</td>
                    <td>{h.time}</td>
                    <td><StatusChip value={requestStatus[h.status]} /></td>
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
            <div className="sh"><h2 className="h2">জমার বিস্তারিত</h2><StatusChip value={requestStatus[sel.status]} /></div>
            <div className="sl"><Avatar name={sel.seller} /><div><b>{sel.seller}</b><span className="mu">{sel.time} জমা দিয়েছেন</span></div></div>
            <KV label="জমার কথা বলেছেন">{money(sel.amount)}</KV>
            <KV label="মাধ্যম">{paymentLabel[sel.method]}</KV>
            <KV label="রেফারেন্স">{sel.reference ?? "—"}</KV>
            <KV label="সেলারের নোট">{sel.note ?? "—"}</KV>
            {sel.status === "pending" ? (
              <>
                <div className="f">
                  <label htmlFor="rc">আসলে পেয়েছেন <i>*</i></label>
                  <input id="rc" className={`in${invalid ? " e" : ""}`} value={received[sel.id] ?? bnDigits(sel.amount)} onChange={(e) => setReceived({ ...received, [sel.id]: e.target.value })} inputMode="decimal" />
                  {invalid ? <span className="err">০ থেকে {money(sel.amount)}-এর মধ্যে পরিমাণ দিন।</span> : null}
                </div>
                {!invalid && diff > 0 ? (
                  <Note kind="danger" icon="alert">{money(diff)} কম পাওয়া গেছে। যাচাই করলে {money(recv!)} গ্রহণ হবে আর {money(diff)} সেলারের বাকিতে থেকে যাবে।</Note>
                ) : null}
                <div className="f"><label htmlFor="nt">মন্তব্য</label><input id="nt" className="in" placeholder="যেমন: বাকি ২০০ টাকা কাল দেবেন" /></div>
                <div className="actions">
                  <ActionButton disabled={invalid} confirm={{ title: "ক্যাশ গ্রহণ নিশ্চিত করবেন?", message: `${sel.seller}-এর কাছ থেকে ${money(recv ?? 0)} হাতে পেয়েছেন।`, label: "নিশ্চিত করুন" }}>
                    {money(recv ?? 0)} গ্রহণ নিশ্চিত করুন
                  </ActionButton>
                  <ActionButton className="btn r" confirm={{ title: "জমা প্রত্যাখ্যান করবেন?", message: "সেলারের বাকি ক্যাশ যেমন আছে তেমন থাকবে।", label: "প্রত্যাখ্যান", danger: true }}>প্রত্যাখ্যান</ActionButton>
                </div>
                <div className="mu">সার্ভার নিশ্চিত করলেই কেবল “যাচাই হয়েছে” দেখাবে।</div>
              </>
            ) : (
              <div className="tl"><i style={{ background: sel.status === "verified" ? "#168447" : "#D64545" }} /><div><div className="t1">{sel.status === "verified" ? "যাচাই করেছেন তানভীর আহমেদ" : "প্রত্যাখ্যান করেছেন তানভীর আহমেদ"}</div><div className="mu">{sel.time}</div></div></div>
            )}
          </section>
        </div>
      ) : null}
    </div>
  );
}
