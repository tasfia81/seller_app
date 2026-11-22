"use client";

import { useState } from "react";
import { Avatar, KV, Note } from "@/components/ui/bits";
import { ActionButton } from "@/components/ui/feedback";
import { bnDigits } from "@/lib/format";

const RETURNS = [
  { id: "r1", seller: "রাকিব হাসান", product: "পোলো টি-শার্ট (XL)", qty: 2, given: 10, reason: "ক্ষতিগ্রস্ত — বৃষ্টিতে ভিজে দাগ", date: "আজ ১১:০৫", status: ["অপেক্ষমাণ", "wa"], ref: "বর-২১০৪", photo: true },
  { id: "r2", seller: "মিম আক্তার", product: "বেসিক টি-শার্ট (M)", qty: 8, given: 10, reason: "দিন শেষের ফেরত", date: "আজ ১০:৩০", status: ["অপেক্ষমাণ", "wa"], ref: "বর-২০৯৮", photo: false },
  { id: "r3", seller: "সাকিব হোসেন", product: "জগার প্যান্ট (L)", qty: 3, given: 5, reason: "দিন শেষের ফেরত", date: "গতকাল", status: ["অনুমোদিত · গ্রহণ বাকি", "inf"], ref: "বর-২০৯২", photo: false },
];

export function ReturnsView() {
  const [tab, setTab] = useState<"returns" | "damaged">("returns");
  const [selId, setSelId] = useState("r1");
  const sel = RETURNS.find((r) => r.id === selId)!;

  return (
    <>
      <div className="tabs" role="tablist">
        <button type="button" role="tab" aria-selected={tab === "returns"} className={`tab${tab === "returns" ? " on" : ""}`} onClick={() => setTab("returns")}>ফেরতের অনুরোধ <span className="ch wa">৩</span></button>
        <button type="button" role="tab" aria-selected={tab === "damaged"} className={`tab${tab === "damaged" ? " on" : ""}`} onClick={() => setTab("damaged")}>ক্ষতিগ্রস্ত / হারানো <span className="ch er">২</span></button>
      </div>
      {tab === "returns" ? (
        <div className="two">
          <div className="a">
            <div className="tw">
              <table style={{ minWidth: 680 }}>
                <thead><tr><th>সেলার</th><th>পণ্য</th><th className="n">পরিমাণ</th><th>কারণ</th><th>তারিখ</th><th>অবস্থা</th></tr></thead>
                <tbody>
                  {RETURNS.map((r) => (
                    <tr key={r.id} className={`click${r.id === selId ? " sel" : ""}`} onClick={() => setSelId(r.id)} tabIndex={0} onKeyDown={(e) => e.key === "Enter" && setSelId(r.id)}>
                      <td><div className="sl"><Avatar name={r.seller} /><b>{r.seller}</b></div></td>
                      <td>{r.product}</td><td className="n">{bnDigits(r.qty)}</td><td>{r.reason.split(" — ")[0]}</td><td>{r.date}</td>
                      <td><span className={`ch ${r.status[1]}`}>{r.status[0]}</span></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
          <div className="b">
            <section className="drawer">
              <div className="sh"><h2 className="h2">ফেরতের বিস্তারিত</h2><span className={`ch ${sel.status[1]}`}>{sel.status[0]}</span></div>
              <div className="sl"><Avatar name={sel.seller} /><div><b>{sel.seller}</b><span className="mu">বরাদ্দ #{sel.ref} · {sel.date}</span></div></div>
              <KV label="পণ্য">{sel.product}</KV>
              <KV label="দেওয়া ছিল">{bnDigits(sel.given)} পিস</KV>
              <KV label="ফেরত চাইছেন">{bnDigits(sel.qty)} পিস</KV>
              <KV label="কারণ">{sel.reason}</KV>
              {sel.photo ? <div className="doc"><div className="pv">সেলারের দেওয়া ছবি</div></div> : null}
              <Note icon="box">অনুমোদনের পর গুদামে হাতে পেয়ে “পেয়েছি” চাপলে তবেই স্টক থেকে বাদ যাবে বা ক্ষতিগ্রস্ত তালিকায় যাবে।</Note>
              <div className="f"><label htmlFor="to">পণ্য কোথায় যাবে</label><select id="to" className="in" defaultValue={sel.photo ? "damaged" : "stock"}><option value="damaged">ক্ষতিগ্রস্ত স্টক</option><option value="stock">গুদামে বিক্রিযোগ্য স্টক</option></select></div>
              {sel.status[1] === "inf" ? (
                <ActionButton className="btn full" confirm={{ title: "পণ্য হাতে পেয়েছেন?", message: `${bnDigits(sel.qty)} পিস ${sel.product} গুদামে বুঝে নিয়েছেন।`, label: "পেয়েছি" }}>পণ্য হাতে পেয়েছি</ActionButton>
              ) : (
                <div className="actions">
                  <ActionButton>অনুমোদন দিন</ActionButton>
                  <ActionButton className="btn r" confirm={{ title: "ফেরত বাতিল করবেন?", message: "পণ্য সেলারের স্টকেই থাকবে।", label: "বাতিল", danger: true }}>বাতিল</ActionButton>
                </div>
              )}
            </section>
          </div>
        </div>
      ) : (
        <>
          <div className="tw">
            <table style={{ minWidth: 760 }}>
              <thead><tr><th>পণ্য</th><th>সেলার</th><th className="n">পরিমাণ</th><th className="n">আনুমানিক ক্রয়মূল্য</th><th>কারণ</th><th>অবস্থা</th><th /></tr></thead>
              <tbody>
                <tr><td>জার্সি (M)</td><td>সাকিব হোসেন</td><td className="n">৩</td><td className="n">৳১,০৫০</td><td>গরমিল — খুঁজে পাওয়া যায়নি</td><td><span className="ch er">যাচাই বাকি</span></td><td className="n"><ActionButton className="btn g sm" confirm={{ title: "সমন্বয় রেকর্ড করবেন?", message: "৩ পিস জার্সি হারানো হিসেবে স্টক থেকে বাদ যাবে। সেলারের কাছ থেকে টাকা কাটা হবে না।", label: "রেকর্ড করুন" }}>সমন্বয় রেকর্ড</ActionButton></td></tr>
                <tr><td>জগার প্যান্ট</td><td>সাকিব হোসেন</td><td className="n">১</td><td className="n">৳৩৬০</td><td>সেলাই ছেঁড়া</td><td><span className="ch nu">রেকর্ড হয়েছে</span></td><td /></tr>
              </tbody>
            </table>
          </div>
          <div className="mu">ক্ষতির টাকা সেলারের কাছ থেকে নিজে থেকে কাটা হয় না — ব্যবসার নিয়ম ঠিক করে আলাদাভাবে সিদ্ধান্ত নিতে হবে।</div>
        </>
      )}
    </>
  );
}
