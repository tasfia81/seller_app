"use client";

import { useState } from "react";
import { Avatar, EmptyState, KV, Note, StatusChip } from "@/components/ui/bits";
import { ActionButton, useToast } from "@/components/ui/feedback";
import { bnDigits, money, parseMoney } from "@/lib/format";
import { withdrawalStatus, type WithdrawalRequest } from "@/lib/investors";

type Row = WithdrawalRequest & { name: string; capital: number; uninvested: number; via: string };

export function WithdrawalsView({ rows }: { rows: Row[] }) {
  const toast = useToast();
  const [tab, setTab] = useState<"open" | "done">("open");
  const list = rows.filter((r) => (tab === "open" ? r.status === "pending" || r.status === "approved" : r.status === "paid" || r.status === "rejected"));
  const [selId, setSelId] = useState(rows.find((r) => r.status === "pending")?.id);
  const sel = rows.find((r) => r.id === selId && r.status === "pending");
  const payRow = rows.find((r) => r.status === "approved");
  const [payRef, setPayRef] = useState("");
  const [paying, setPaying] = useState(false);
  const [reason, setReason] = useState("");

  const first = sel ? Math.min(sel.uninvested, sel.amount) : 0;
  const [firstAmt, setFirstAmt] = useState(first ? bnDigits(first) : "");
  const firstVal = parseMoney(firstAmt) ?? 0;
  const second = sel ? sel.amount - firstVal : 0;
  const planError = sel && (firstVal < 0 || firstVal > Math.min(sel.uninvested, sel.amount)) ? `প্রথম কিস্তি সর্বোচ্চ ${money(Math.min(sel.uninvested, sel.amount))} (খাটেনি টাকা)।` : null;

  return (
    <>
      <div className="tabs" role="tablist" aria-label="অনুরোধের অবস্থা">
        <button type="button" role="tab" aria-selected={tab === "open"} className={`tab${tab === "open" ? " on" : ""}`} onClick={() => setTab("open")}>খোলা</button>
        <button type="button" role="tab" aria-selected={tab === "done"} className={`tab${tab === "done" ? " on" : ""}`} onClick={() => setTab("done")}>সম্পন্ন ও বাতিল</button>
      </div>
      <div className="two">
        <div className="a">
          {list.length === 0 ? (
            <div className="cd"><EmptyState icon="ret" title="এই তালিকায় কোনো অনুরোধ নেই" /></div>
          ) : (
            <div className="tw">
              <table>
                <thead><tr><th>বিনিয়োগকারী</th><th className="n">চাওয়া</th><th>চাওয়ার তারিখ</th><th>শেষ সীমা</th><th>অবস্থা</th><th /></tr></thead>
                <tbody>
                  {list.map((r) => (
                    <tr key={r.id} className={r.id === sel?.id ? "sel" : undefined}>
                      <td><div className="sl"><Avatar name={r.name} /><b>{r.name}</b></div></td>
                      <td className="n">{money(r.amount)}</td>
                      <td>{r.requested}</td>
                      <td>{r.deadline}</td>
                      <td><StatusChip value={withdrawalStatus[r.status]} /></td>
                      <td className="n">
                        {r.status === "pending" ? <button type="button" className="btn g sm" onClick={() => { setSelId(r.id); setFirstAmt(bnDigits(Math.min(r.uninvested, r.amount))); }}>খুলুন</button> : null}
                        {r.status === "paid" ? <span className="mu">পরিশোধ {r.paidOn}</span> : null}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
          {sel ? (
            <section className="cd">
              <h2 className="h2" style={{ marginBottom: 8 }}>{sel.name}-এর টাকা এখন কোথায়</h2>
              <div className="kvg">
                <KV label="সক্রিয় মূলধন">{money(sel.capital)}</KV>
                <KV label="খাটেনি — এখনই দেওয়া যায়">{money(sel.uninvested)}</KV>
                <KV label="স্টকে আটকে আছে">{money(sel.capital - sel.uninvested)}</KV>
              </div>
            </section>
          ) : null}
        </div>
        <div className="b">
          {sel ? (
            <section className="drawer">
              <h2 className="h2">সিদ্ধান্ত ও সময়সূচি</h2>
              <KV label="চাওয়া">{money(sel.amount)} · {sel.via}</KV>
              <KV label="কারণ (উনি লিখেছেন)">{sel.reason}</KV>
              <div className="f">
                <label htmlFor="k1">কিস্তি ১ · খাটেনি থেকে (৩ দিনে)</label>
                <input id="k1" className={`in${planError ? " e" : ""}`} inputMode="decimal" value={firstAmt} onChange={(e) => setFirstAmt(e.target.value)} />
              </div>
              <div className="f">
                <span className="lb">কিস্তি ২ · বিক্রি থেকে ({sel.deadline}-এর মধ্যে)</span>
                <input className="in" value={money(Math.max(0, second))} readOnly aria-label="কিস্তি ২ পরিমাণ" />
                <span className="hint">ওনার স্টক বিক্রি হলে সেই টাকা নতুন স্টকে না লাগিয়ে এখানে জমবে</span>
              </div>
              {planError ? <span className="err">{planError}</span> : null}
              <Note>অনুমোদনের পর ফেরতের অংশে ওনার টাকায় নতুন স্টক কেনা বন্ধ থাকবে। ফেরত অংশের লাভ হিসাব বন্ধের দিন পর্যন্ত গোনা হবে।</Note>
              <div className="f"><label htmlFor="rj">বাতিলের কারণ</label><textarea id="rj" className="in" value={reason} onChange={(e) => setReason(e.target.value)} placeholder="বাতিল করলে লিখুন" /></div>
              <div className="actions">
                <ActionButton disabled={!!planError} confirm={{ title: "অনুমোদন দেবেন?", message: `${sel.name}-কে সময়সূচি পাঠানো হবে: ${money(firstVal)} প্রথমে, বাকি ${money(Math.max(0, second))} ${sel.deadline}-এর মধ্যে।`, label: "অনুমোদন দিন" }}>
                  অনুমোদন ও সময়সূচি পাঠান
                </ActionButton>
                <ActionButton className="btn r" disabled={reason.trim().length < 5} confirm={{ title: "অনুরোধ বাতিল করবেন?", message: "কারণসহ বার্তা ওনার অ্যাপে যাবে।", label: "বাতিল করুন", danger: true }}>
                  বাতিল (কারণসহ)
                </ActionButton>
              </div>
            </section>
          ) : null}
          {payRow ? (
            <section className="drawer">
              <h2 className="h2">পেমেন্ট রেকর্ড · {payRow.name}</h2>
              <KV label="পরিমাণ">{money(payRow.amount)}</KV>
              <KV label="মাধ্যম">{payRow.via}</KV>
              <div className="f"><label htmlFor="pr">ব্যাংক রেফারেন্স <i>*</i></label><input id="pr" className="in" placeholder="যেমন: FT2611250412" value={payRef} onChange={(e) => setPayRef(e.target.value)} /></div>
              <button
                type="button"
                className="btn full"
                disabled={!payRef.trim() || paying}
                onClick={() => {
                  setPaying(true);
                  toast("ডেমো: সার্ভার যুক্ত হলে পরিশোধ রেকর্ড হবে ও রসিদ যাবে। এখন কোনো টাকা পাঠানো বা রেকর্ড হয়নি।");
                  setTimeout(() => setPaying(false), 2500);
                }}
              >
                {paying ? "পাঠানো হচ্ছে…" : `${money(payRow.amount)} পরিশোধ রেকর্ড করুন`}
              </button>
              <div className="mu">একবার চাপলেই বাটন বন্ধ; রসিদ ওনার অ্যাপে যাবে।</div>
            </section>
          ) : null}
        </div>
      </div>
    </>
  );
}
