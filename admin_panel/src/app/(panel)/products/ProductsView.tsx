"use client";

import Link from "next/link";
import { useState, useTransition } from "react";
import { Icon } from "@/components/ui/Icon";
import { EmptyState } from "@/components/ui/bits";
import { ConfirmDialog, useToast } from "@/components/ui/feedback";
import type { ActionResult } from "@/lib/api/server";
import type { ApiCategory, ApiProduct } from "@/lib/api/types";
import { bnDigits, money } from "@/lib/format";
import { archiveCategory, createCategory, renameCategory } from "./actions";

const STOCK = ["সব", "চালু", "কম স্টক", "স্টক শেষ"] as const;

export function ProductsView({ items, categories }: { items: ApiProduct[]; categories: ApiCategory[] }) {
  const toast = useToast();
  const [pending, start] = useTransition();
  const [cat, setCat] = useState<string | null>(null);
  const [stock, setStock] = useState<(typeof STOCK)[number]>("সব");
  const [q, setQ] = useState("");
  const [newCat, setNewCat] = useState("");
  const selectedCat = categories.find((c) => c.id === cat) ?? null;
  const [editing, setEditing] = useState("");
  const [confirmArchive, setConfirmArchive] = useState(false);

  const run = (fn: () => Promise<ActionResult>, after?: () => void) =>
    start(async () => {
      const r = await fn();
      toast(r.ok ? (r.message ?? "সম্পন্ন হয়েছে।") : r.message, !r.ok);
      if (r.ok) after?.();
    });

  const list = items.filter((p) => {
    if (cat && p.category_id !== cat) return false;
    if (stock === "চালু" && !p.active) return false;
    if (stock === "কম স্টক" && p.stock_status !== "low_stock") return false;
    if (stock === "স্টক শেষ" && p.stock_status !== "out_of_stock") return false;
    const t = q.trim().toLowerCase();
    return !t || p.name.toLowerCase().includes(t) || p.sku.toLowerCase().includes(t);
  });

  return (
    <div className="two">
      <div className="b" style={{ flex: "1 1 260px", maxWidth: 320 }}>
        <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 6 }}>
          <h2 className="h2">ক্যাটাগরি</h2>
          <div style={{ display: "flex", gap: 6, margin: "4px 0" }}>
            <input className="in" placeholder="নতুন ক্যাটাগরির নাম" aria-label="নতুন ক্যাটাগরির নাম" value={newCat} onChange={(e) => setNewCat(e.target.value)} />
            <button type="button" className="btn sm" disabled={pending || newCat.trim().length < 2} onClick={() => run(() => createCategory(newCat.trim()), () => setNewCat(""))}>যোগ</button>
          </div>
          <button type="button" onClick={() => setCat(null)} style={catBtn(cat === null)}>
            সব পণ্য <small className="mu" style={{ marginLeft: "auto" }}>{bnDigits(items.length)}</small>
          </button>
          {categories.map((c) => (
            <button key={c.id} type="button" onClick={() => { setCat(c.id); setEditing(c.name); }} style={catBtn(cat === c.id, c.archived)}>
              {c.name} <small className="mu" style={{ marginLeft: "auto" }}>{c.archived ? "আর্কাইভ" : bnDigits(c.product_count)}</small>
            </button>
          ))}
          {!categories.length ? <div className="mu">এখনো কোনো ক্যাটাগরি নেই — উপরে প্রথমটা যোগ করুন।</div> : null}
        </section>
        {selectedCat ? (
          <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 10 }}>
            <h2 className="h2">ক্যাটাগরি সম্পাদনা</h2>
            <div className="f"><label htmlFor="cn">নাম</label><input id="cn" className="in" value={editing} onChange={(e) => setEditing(e.target.value)} /></div>
            <div style={{ display: "flex", gap: 8 }}>
              {selectedCat.archived ? (
                <button type="button" className="btn o sm" disabled={pending} onClick={() => run(() => archiveCategory(selectedCat.id, false))}>আবার চালু</button>
              ) : (
                <button type="button" className="btn r sm" disabled={pending} onClick={() => setConfirmArchive(true)}>আর্কাইভ</button>
              )}
              <button type="button" className="btn sm" disabled={pending || editing.trim().length < 2 || editing.trim() === selectedCat.name} onClick={() => run(() => renameCategory(selectedCat.id, editing.trim()))}>সংরক্ষণ</button>
            </div>
            <ConfirmDialog
              open={confirmArchive}
              title="ক্যাটাগরি আর্কাইভ করবেন?"
              message="আর্কাইভ করলে নতুন পণ্যে এটা বাছাই করা যাবে না। আগের পণ্য ও বিক্রি যেমন আছে থাকবে।"
              confirmLabel="আর্কাইভ"
              danger
              onConfirm={() => run(() => archiveCategory(selectedCat.id, true))}
              onClose={() => setConfirmArchive(false)}
            />
          </section>
        ) : null}
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
            <EmptyState icon="tag" title={items.length ? "কোনো পণ্য মেলেনি" : "এখনো কোনো পণ্য নেই"} text={items.length ? "অন্য নাম বা ফিল্টার দিয়ে খুঁজুন।" : "উপরের “নতুন পণ্য” দিয়ে প্রথম পণ্য যোগ করুন।"} />
          ) : (
            <table style={{ minWidth: 820 }}>
              <thead><tr><th>পণ্য</th><th>ক্যাটাগরি</th><th>SKU</th><th>ইউনিট</th><th className="n">বিক্রয়মূল্য</th><th className="n">মূল স্টক</th><th>অবস্থা</th><th /></tr></thead>
              <tbody>
                {list.map((p) => {
                  const out = p.stock_status === "out_of_stock";
                  const low = p.stock_status === "low_stock";
                  return (
                    <tr key={p.id}>
                      <td><div className="sl"><span className="th" style={out ? { background: "#ECEFED", color: "#6E7A73" } : undefined}><Icon name="tag" size={18} /></span><b>{p.name}</b></div></td>
                      <td>{p.category_name ?? "—"}</td>
                      <td className="mu">{p.sku}</td>
                      <td>{p.unit_label}</td>
                      <td className="n"><b>{money(p.price)}</b>{p.price_editable && p.min_price ? <span className="mu"> {bnDigits(p.min_price)}–{bnDigits(p.max_price ?? 0)}</span> : null}</td>
                      <td className="n" style={out ? { color: "#A92F2F", fontWeight: 600 } : low ? { color: "#85560C", fontWeight: 600 } : undefined}>{bnDigits(p.stock.warehouse)}</td>
                      <td>{!p.active ? <span className="ch nu">বন্ধ</span> : out ? <span className="ch er">স্টক শেষ</span> : low ? <span className="ch wa">কম স্টক</span> : <span className="ch ok">চালু</span>}</td>
                      <td className="n" style={{ display: "flex", gap: 6, justifyContent: "flex-end" }}>
                        <Link className="btn g sm" href={`/products/new?id=${p.id}`}>সম্পাদনা</Link>
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
