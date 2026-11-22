"use client";

import Link from "next/link";
import { useState } from "react";
import { Icon } from "@/components/ui/Icon";
import { EmptyState } from "@/components/ui/bits";
import { ActionButton } from "@/components/ui/feedback";
import { bnDigits, money } from "@/lib/format";
import type { Product } from "@/lib/types";

type Cat = { name: string; count: number; archived: boolean };
const STOCK = ["সব", "চালু", "কম স্টক", "স্টক শেষ"] as const;

export function ProductsView({ items, categories }: { items: Product[]; categories: Cat[] }) {
  const [cat, setCat] = useState<string | null>(null);
  const [stock, setStock] = useState<(typeof STOCK)[number]>("সব");
  const [q, setQ] = useState("");
  const [catQ, setCatQ] = useState("");
  const [editing, setEditing] = useState(categories[1]?.name ?? "");

  const list = items.filter((p) => {
    if (cat && p.category !== cat) return false;
    if (stock === "চালু" && !p.active) return false;
    if (stock === "কম স্টক" && !(p.warehouse > 0 && p.warehouse <= p.lowStockAt)) return false;
    if (stock === "স্টক শেষ" && p.warehouse > 0) return false;
    const t = q.trim().toLowerCase();
    return !t || p.name.includes(q.trim()) || p.sku.toLowerCase().includes(t);
  });

  return (
    <div className="two">
      <div className="b" style={{ flex: "1 1 260px", maxWidth: 320 }}>
        <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 6 }}>
          <div className="sh">
            <h2 className="h2">ক্যাটাগরি</h2>
            <ActionButton className="btn g sm">+ যোগ</ActionButton>
          </div>
          <div className="srch" style={{ maxWidth: "none", margin: "4px 0" }}>
            <input className="in" type="search" placeholder="ক্যাটাগরি খুঁজুন" aria-label="ক্যাটাগরি খুঁজুন" value={catQ} onChange={(e) => setCatQ(e.target.value)} />
            <span><Icon name="search" size={18} /></span>
          </div>
          <button type="button" onClick={() => setCat(null)} style={catBtn(cat === null)}>
            সব পণ্য <small className="mu" style={{ marginLeft: "auto" }}>{bnDigits(items.length)}</small>
          </button>
          {categories.filter((c) => c.name.includes(catQ.trim())).map((c) => (
            <button key={c.name} type="button" onClick={() => { setCat(c.name); setEditing(c.name); }} style={catBtn(cat === c.name, c.archived)}>
              {c.name} <small className="mu" style={{ marginLeft: "auto" }}>{c.archived ? "আর্কাইভ" : bnDigits(c.count)}</small>
            </button>
          ))}
          <div className="mu" style={{ marginTop: 6, lineHeight: 1.5 }}>যেকোনো ক্যাটাগরি বানানো যায় — পোশাক, সবজি, খাবার বা ইলেকট্রনিক্স, সবার জন্য একই নিয়ম।</div>
        </section>
        <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          <h2 className="h2">ক্যাটাগরি সম্পাদনা</h2>
          <div className="f"><label htmlFor="cn">নাম</label><input id="cn" className="in" value={editing} onChange={(e) => setEditing(e.target.value)} /></div>
          <div style={{ display: "flex", gap: 8 }}>
            <ActionButton className="btn r sm" confirm={{ title: "ক্যাটাগরি আর্কাইভ করবেন?", message: "আর্কাইভ করলে নতুন পণ্যে এটা বাছাই করা যাবে না। আগের পণ্য ও বিক্রি যেমন আছে থাকবে।", label: "আর্কাইভ", danger: true }}>আর্কাইভ</ActionButton>
            <ActionButton className="btn sm" disabled={!editing.trim()}>সংরক্ষণ</ActionButton>
          </div>
        </section>
      </div>

      <div className="a">
        <div className="sh">
          <div className="srch">
            <input className="in" type="search" placeholder="পণ্যের নাম বা SKU খুঁজুন" aria-label="পণ্য খুঁজুন" value={q} onChange={(e) => setQ(e.target.value)} />
            <span><Icon name="search" size={18} /></span>
          </div>
          <div className="pills" role="group" aria-label="স্টক ফিল্টার">
            {STOCK.map((s) => <button key={s} type="button" className={`pill${stock === s ? " on" : ""}`} onClick={() => setStock(s)}>{s}</button>)}
          </div>
        </div>
        <div className="tw">
          {list.length === 0 ? (
            <EmptyState icon="tag" title="কোনো পণ্য মেলেনি" text="অন্য নাম বা ফিল্টার দিয়ে খুঁজুন।" />
          ) : (
            <table style={{ minWidth: 820 }}>
              <thead><tr><th>পণ্য</th><th>ক্যাটাগরি</th><th>SKU</th><th>ইউনিট</th><th className="n">বিক্রয়মূল্য</th><th className="n">মূল স্টক</th><th>অবস্থা</th><th /></tr></thead>
              <tbody>
                {list.map((p) => {
                  const out = p.warehouse === 0;
                  const low = !out && p.warehouse <= p.lowStockAt;
                  return (
                    <tr key={p.id}>
                      <td><div className="sl"><span className="th" style={out ? { background: "#ECEFED", color: "#6E7A73" } : undefined}><Icon name={p.category === "অ্যাক্সেসরিজ" ? "tag" : "shirt"} size={18} /></span><b>{p.name}</b></div></td>
                      <td>{p.category}</td>
                      <td className="mu">{p.sku}</td>
                      <td>{p.unit}</td>
                      <td className="n"><b>{money(p.price)}</b>{p.minPrice ? <span className="mu"> {bnDigits(p.minPrice)}–{bnDigits(p.maxPrice ?? 0)}</span> : null}</td>
                      <td className="n" style={out ? { color: "#A92F2F", fontWeight: 600 } : low ? { color: "#85560C", fontWeight: 600 } : undefined}>{bnDigits(p.warehouse)}</td>
                      <td>{out ? <span className="ch er">স্টক শেষ</span> : low ? <span className="ch wa">কম স্টক</span> : <span className="ch ok">চালু</span>}</td>
                      <td className="n" style={{ display: "flex", gap: 6, justifyContent: "flex-end" }}>
                        <Link className="btn g sm" href="/products/new">সম্পাদনা</Link>
                        {out || low ? <Link className="btn o sm" href="/inventory">স্টক যোগ</Link> : <Link className="btn o sm" href="/assignments/new">বরাদ্দ</Link>}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>
        <div className="mu">মূল স্টক = গুদামে থাকা পণ্য। সেলারদের কাছে থাকা পণ্য “মূল স্টক” পেজে আলাদা দেখানো হয়।</div>
      </div>
    </div>
  );
}

function catBtn(on: boolean, archived = false): React.CSSProperties {
  return {
    display: "flex", alignItems: "center", gap: 10, minHeight: 44, padding: "0 10px", borderRadius: 10, fontSize: 14, border: 0, textAlign: "left",
    background: on ? "#E3F3EA" : "transparent", color: on ? "#0F6A38" : archived ? "#5F6C64" : "#17251D", fontWeight: on ? 600 : 400,
  };
}
