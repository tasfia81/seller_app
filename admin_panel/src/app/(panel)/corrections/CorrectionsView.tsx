"use client";

import Link from "next/link";
import { useState } from "react";
import { KV, Note } from "@/components/ui/bits";
import { ActionButton, Tabs } from "@/components/ui/feedback";

const REQUESTS = [
  { id: "বি-১০৪৭১", product: "ক্রিকেট ক্যাপ", seller: "মিম আক্তার", when: "আজ ১০:০৫", summary: "পেমেন্ট নগদ নয়, ক্যাশ ছিল", before: ["ক্রিকেট ক্যাপ × ১", "৳১৮০", "নগদ"], after: ["ক্রিকেট ক্যাপ × ১", "৳১৮০", "ক্যাশ"], changed: 2, reason: "কাস্টমার শেষে ক্যাশ দিয়েছেন, ভুল করে নগদ চাপা হয়েছিল", impact: "অনুমোদন দিলে মিমের বাকি ক্যাশ ৳১৮০ বাড়বে।" },
  { id: "বি-১০৪৩৩", product: "জার্সি (M)", seller: "সাকিব হোসেন", when: "গতকাল ১৭:২০", summary: "পরিমাণ ২ নয়, ১ হবে", before: ["জার্সি (M) × ২", "৳৯০০", "ক্যাশ"], after: ["জার্সি (M) × ১", "৳৪৫০", "ক্যাশ"], changed: 0, reason: "একই বিক্রি দুবার গোনা হয়েছিল", impact: "অনুমোদন দিলে ১ পিস সাকিবের স্টকে ফিরবে, বাকি ক্যাশ ৳৪৫০ কমবে।" },
];

export function CorrectionsView() {
  const [selId, setSelId] = useState(REQUESTS[0].id);
  const r = REQUESTS.find((x) => x.id === selId)!;
  const rows = ["পণ্য", "টাকা", "পেমেন্ট"];
  return (
    <>
      <Tabs label="অবস্থা" tabs={[{ id: "p", label: <>অপেক্ষমাণ <span className="ch wa">২</span></> }, { id: "a", label: "অনুমোদিত" }, { id: "r", label: "বাতিল" }]} />
      <div className="two">
        <div className="b">
          {REQUESTS.map((x) => (
            <button key={x.id} type="button" className={`card-btn${x.id === selId ? " on" : ""}`} onClick={() => setSelId(x.id)}>
              <div className="sh" style={{ width: "100%" }}><b className="t1">#{x.id} · {x.product}</b><span className="ch wa">অপেক্ষমাণ</span></div>
              <span className="mu">{x.seller} · {x.when}</span>
              <span style={{ fontSize: 13.5 }}>{x.summary}</span>
            </button>
          ))}
        </div>
        <div className="a">
          <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 14 }}>
            <div className="sh"><h2 className="h2">#{r.id} সংশোধন</h2><Link className="btn g sm" href="/sales">মূল বিক্রি দেখুন</Link></div>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))", gap: 12 }}>
              <div style={{ border: "1px solid #E4EBE6", borderRadius: 12, padding: 12 }}>
                <div className="mu" style={{ marginBottom: 6 }}>বর্তমান (নিশ্চিত)</div>
                {rows.map((l, i) => <KV key={l} label={l}>{r.before[i]}</KV>)}
              </div>
              <div style={{ border: "2px solid #E6A23C", background: "#FFFCF5", borderRadius: 12, padding: 12 }}>
                <div className="mu" style={{ marginBottom: 6 }}>সেলার যা চাইছেন</div>
                {rows.map((l, i) => <KV key={l} label={l}><span style={r.before[i] !== r.after[i] ? { color: "#85560C" } : undefined}>{r.after[i]}</span></KV>)}
              </div>
            </div>
            <KV label="সেলার">{r.seller}</KV>
            <KV label="কারণ">{r.reason}</KV>
            <Note kind="warn" icon="cash">{r.impact} মূল বিক্রি মুছবে না — একটি সংশোধন রেকর্ড যোগ হবে।</Note>
            <div className="f"><label htmlFor="nt">আপনার মন্তব্য</label><textarea id="nt" className="in" placeholder="যেমন: নগদ অ্যাকাউন্টে টাকা আসেনি, মিলিয়ে দেখা হয়েছে" /></div>
            <div className="actions">
              <ActionButton confirm={{ title: "সংশোধন অনুমোদন দেবেন?", message: r.impact, label: "অনুমোদন দিন" }}>অনুমোদন দিন</ActionButton>
              <ActionButton className="btn o">আরও জানতে চাই</ActionButton>
              <ActionButton className="btn r" confirm={{ title: "সংশোধন বাতিল করবেন?", message: "মূল বিক্রি যেমন আছে তেমন থাকবে।", label: "বাতিল করুন", danger: true }}>বাতিল করুন</ActionButton>
            </div>
          </section>
          <section className="cd">
            <h2 className="h2" style={{ marginBottom: 4 }}>এই বিক্রির সংশোধনের ইতিহাস</h2>
            <div className="tl"><i style={{ background: "#E6A23C" }} /><div><div className="t1">সংশোধনের অনুরোধ</div><div className="mu">{r.when} · {r.seller}</div></div></div>
            <div className="tl"><i style={{ background: "#168447" }} /><div><div className="t1">বিক্রি নিশ্চিত</div><div className="mu">সিস্টেম</div></div></div>
          </section>
        </div>
      </div>
    </>
  );
}
