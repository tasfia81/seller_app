"use client";

import Link from "next/link";
import { useState } from "react";
import { Icon, type IconName } from "@/components/ui/Icon";

type N = { id: string; cat: string; icon: IconName; bg: string; fg: string; title: string; text: string; href: string; unread: boolean };
const INITIAL: N[] = [
  { id: "1", cat: "আবেদন", icon: "doc", bg: "#E6EFFD", fg: "#1D4FB8", title: "নতুন সেলার আবেদন", text: "ফাহিম রহমান আবেদন করেছেন · ০৯:১৫", href: "/applications", unread: true },
  { id: "2", cat: "টাকা", icon: "cash", bg: "#FCF0DA", fg: "#85560C", title: "ক্যাশ জমা যাচাইয়ের অপেক্ষায়", text: "রাকিব হাসান · ৳৩,২০০ · ১১:৩০", href: "/cash", unread: true },
  { id: "3", cat: "স্টক", icon: "flag", bg: "#FBE5E5", fg: "#A92F2F", title: "দিনের হিসাবে গরমিল", text: "সাকিব হোসেন · ৩ পিস জার্সি কম", href: "/settlements", unread: true },
  { id: "4", cat: "স্টক", icon: "alert", bg: "#FCF0DA", fg: "#85560C", title: "কম স্টক", text: "ক্রিকেট ক্যাপ · গুদামে ৮ পিস", href: "/inventory", unread: false },
  { id: "5", cat: "স্টক", icon: "ret", bg: "#ECEFED", fg: "#45524A", title: "ফেরতের অনুরোধ", text: "রাকিব হাসান · ২ পিস পোলো", href: "/returns", unread: false },
  { id: "6", cat: "বিক্রি", icon: "edit", bg: "#ECEFED", fg: "#45524A", title: "বিক্রি সংশোধনের অনুরোধ", text: "মিম আক্তার · #বি-১০৪৭১", href: "/corrections", unread: false },
];
const LOG = [
  ["আজ ১১:৪০", "ok", "ক্যাশ যাচাই", "নুসরাত জাহান", "৳৪,০০০ গ্রহণ"],
  ["আজ ১০:১২", "inf", "পরিচয়পত্র দেখা", "আবেদন #আবে-০০৪৮", "পুরো নম্বর দেখা হয়েছে"],
  ["আজ ০৯:৪০", "nu", "দাম পরিবর্তন", "পোলো টি-শার্ট", "৳৪০০ → ৳৩৮০"],
  ["আজ ০৮:১০", "nu", "স্টক বরাদ্দ", "#বর-২১০৪ · রাকিব", "৪০ পিস"],
  ["গতকাল ১৯:২০", "ok", "দিন বন্ধ", "রাকিব · ২০ নভেম্বর", "খোলা → বন্ধ"],
  ["গতকাল ১২:০০", "nu", "কমিশন পরিবর্তন", "নুসরাত জাহান", "দৈনিক ৳৪৫০ → ৳৫০০ + পিসে ৳১০"],
  ["১৮ নভেম্বর", "ok", "সেলার অনুমোদন", "মিম আক্তার", "আবেদন → অনুমোদিত"],
] as const;
const CATS = ["সব", "আবেদন", "বিক্রি", "স্টক", "টাকা"];

export function ActivityView() {
  const [items, setItems] = useState(INITIAL);
  const [cat, setCat] = useState("সব");
  const list = items.filter((n) => cat === "সব" || n.cat === cat);
  const unread = items.some((n) => n.unread);

  return (
    <div className="two">
      <div className="b" style={{ flex: "1 1 360px" }}>
        <div className="sh">
          <h2 className="h2">নোটিফিকেশন</h2>
          <button type="button" className="btn g sm" disabled={!unread} onClick={() => setItems(items.map((n) => ({ ...n, unread: false })))}>সব পড়া হয়েছে</button>
        </div>
        <div className="pills">{CATS.map((c) => <button key={c} type="button" className={`pill${cat === c ? " on" : ""}`} onClick={() => setCat(c)}>{c}</button>)}</div>
        {list.map((n) => (
          <Link
            key={n.id}
            href={n.href}
            onClick={() => setItems(items.map((x) => (x.id === n.id ? { ...x, unread: false } : x)))}
            style={{ display: "flex", gap: 12, alignItems: "flex-start", padding: 12, borderRadius: 12, textDecoration: "none", color: "#17251D", border: `1px solid ${n.unread ? "#CFE6D8" : "#E4EBE6"}`, background: n.unread ? "#F1F8F4" : "#fff" }}
          >
            <span className="ic" style={{ background: n.bg, color: n.fg }}><Icon name={n.icon} size={18} /></span>
            <span className="fx"><b className="t1">{n.title}</b><div className="mu">{n.text}</div></span>
            {n.unread ? <span style={{ width: 8, height: 8, borderRadius: "50%", background: "#168447", marginTop: 8, flex: "none" }} aria-label="নতুন" /> : null}
          </Link>
        ))}
        <div className="mu">নোটিফিকেশনে কখনো পরিচয়পত্রের ছবি বা নম্বর দেখানো হয় না।</div>
      </div>
      <div className="a">
        <h2 className="h2">অডিট লগ</h2>
        <div className="tw">
          <table style={{ minWidth: 700 }}>
            <thead><tr><th>সময়</th><th>কে</th><th>কাজ</th><th>কোন রেকর্ড</th><th>পরিবর্তন</th></tr></thead>
            <tbody>
              {LOG.map((l) => (
                <tr key={l[0] + l[2]}><td>{l[0]}</td><td>তানভীর আহমেদ</td><td><span className={`ch ${l[1]}`}>{l[2]}</span></td><td>{l[3]}</td><td>{l[4]}</td></tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="mu">লগ মুছে বা বদলে ফেলা যায় না। সংবেদনশীল তথ্য (পরিচয়পত্র নম্বর, পাসওয়ার্ড) লগে লুকানো থাকে।</div>
      </div>
    </div>
  );
}
