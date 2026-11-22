"use client";

import { useState } from "react";
import { KV } from "@/components/ui/bits";
import { ActionButton } from "@/components/ui/feedback";
import { products } from "@/lib/demo-data";
import { bnDigits, money, parseMoney } from "@/lib/format";

export function StockReceiptForm() {
  const [pid, setPid] = useState("basic-white");
  const product = products.find((p) => p.id === pid)!;
  const [variant, setVariant] = useState(product.variants[0] ?? "");
  const [qty, setQty] = useState("৫০");
  const [cost, setCost] = useState("১৬০");
  const q = parseMoney(qty) ?? 0;
  const c = parseMoney(cost) ?? 0;
  const valid = q > 0 && c > 0;

  return (
    <section className="drawer">
      <h2 className="h2">স্টক গ্রহণ</h2>
      <div className="f">
        <label htmlFor="p">পণ্য <i>*</i></label>
        <select id="p" className="in" value={pid} onChange={(e) => { setPid(e.target.value); setVariant(products.find((x) => x.id === e.target.value)?.variants[0] ?? ""); }}>
          {products.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
        </select>
      </div>
      <div className="fg2">
        <div className="f">
          <label htmlFor="v">ধরন</label>
          <select id="v" className="in" value={variant} onChange={(e) => setVariant(e.target.value)} disabled={!product.variants.length}>
            {product.variants.length ? product.variants.map((v) => <option key={v}>{v}</option>) : <option>নেই</option>}
          </select>
        </div>
        <div className="f"><label htmlFor="q">পরিমাণ <i>*</i></label><input id="q" className={`in${q > 0 ? "" : " e"}`} value={qty} onChange={(e) => setQty(e.target.value)} inputMode="numeric" /></div>
        <div className="f"><label htmlFor="c">প্রতি {product.unit} ক্রয়মূল্য <i>*</i></label><input id="c" className={`in${c > 0 ? "" : " e"}`} value={cost} onChange={(e) => setCost(e.target.value)} inputMode="decimal" /></div>
        <div className="f"><label htmlFor="d">ক্রয়ের তারিখ</label><input id="d" type="date" className="in" defaultValue="2026-11-22" /></div>
      </div>
      <div className="f"><label htmlFor="s">সরবরাহকারী <small>(ঐচ্ছিক)</small></label><input id="s" className="in" defaultValue="রহমান গার্মেন্টস, মিরপুর" /></div>
      <div className="f"><label htmlFor="b">ব্যাচ রেফারেন্স</label><input id="b" className="in" defaultValue="ব্যাচ-৮৯" /></div>
      <div className="f"><label htmlFor="n">নোট</label><input id="n" className="in" placeholder="যেমন: ২টি প্যাকেট ছেঁড়া ছিল" /></div>
      <div style={{ background: "#F7F9F8", borderRadius: 12, padding: "6px 12px" }}>
        <KV label="গুদামে যোগ হবে">{bnDigits(q)} {product.unit}{variant ? ` (${variant})` : ""}</KV>
        <KV label="মোট ক্রয়মূল্য">{money(q * c)}</KV>
        <KV label="নতুন গুদাম স্টক">{bnDigits(product.warehouse + q)} {product.unit}</KV>
      </div>
      <ActionButton className="btn full" disabled={!valid} confirm={{ title: "স্টক গ্রহণ নিশ্চিত করবেন?", message: `${product.name}: ${bnDigits(q)} ${product.unit}, মোট ${money(q * c)}।`, label: "নিশ্চিত করুন" }}>
        স্টক গ্রহণ নিশ্চিত করুন
      </ActionButton>
    </section>
  );
}
