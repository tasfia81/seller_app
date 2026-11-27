"use client";

import { useState, useTransition } from "react";
import { KV } from "@/components/ui/bits";
import { useToast } from "@/components/ui/feedback";
import type { ApiProduct } from "@/lib/api/types";
import { bnDigits, money, parseMoney } from "@/lib/format";
import { receiveStock } from "./actions";

export function StockReceiptForm({ products }: { products: ApiProduct[] }) {
  const toast = useToast();
  const [pending, start] = useTransition();
  const [pid, setPid] = useState(products[0]?.id ?? "");
  const product = products.find((p) => p.id === pid);
  const [variant, setVariant] = useState(product?.variants[0] ?? "");
  const [qty, setQty] = useState("");
  const [cost, setCost] = useState(product ? bnDigits(product.unit_cost) : "");
  const [supplier, setSupplier] = useState("");
  const [batch, setBatch] = useState("");
  const q = parseMoney(qty) ?? 0;
  const c = parseMoney(cost);
  const valid = !!product && q > 0 && c !== null && c >= 0 && (!product.variants.length || !!variant);

  if (!products.length) {
    return (
      <section className="drawer" id="receive-stock">
        <h2 className="h2">স্টক গ্রহণ</h2>
        <div className="mu">চালু কোনো পণ্য নেই। আগে পণ্য যোগ করুন।</div>
      </section>
    );
  }

  const pick = (id: string) => {
    const p = products.find((x) => x.id === id);
    setPid(id);
    setVariant(p?.variants[0] ?? "");
    setCost(p ? bnDigits(p.unit_cost) : "");
  };

  const submit = () =>
    start(async () => {
      const r = await receiveStock({
        product_id: pid,
        variant: product?.variants.length ? variant : null,
        quantity: q,
        unit_cost: c ?? 0,
        supplier: supplier.trim() || null,
        batch_ref: batch.trim() || null,
      });
      toast(r.ok ? (r.message ?? "সম্পন্ন।") : r.message, !r.ok);
      if (r.ok) setQty("");
    });

  return (
    <section className="drawer" id="receive-stock">
      <h2 className="h2">স্টক গ্রহণ (সরবরাহকারী থেকে)</h2>
      <div className="f">
        <label htmlFor="sp">পণ্য <i>*</i></label>
        <select id="sp" className="in" value={pid} onChange={(e) => pick(e.target.value)}>
          {products.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
        </select>
      </div>
      {product?.variants.length ? (
        <div className="f">
          <span className="lb">{product.variant_label ?? "ধরন"} <i>*</i></span>
          <div className="pills" role="group" aria-label="ধরন">
            {product.variants.map((v) => (
              <button key={v} type="button" className={`pill${variant === v ? " sel" : ""}`} aria-pressed={variant === v} onClick={() => setVariant(v)}>{v}</button>
            ))}
          </div>
        </div>
      ) : null}
      <div className="fg">
        <div className="f"><label htmlFor="sq">পরিমাণ ({product?.unit_label}) <i>*</i></label><input id="sq" className="in" inputMode="decimal" value={qty} onChange={(e) => setQty(e.target.value)} /></div>
        <div className="f"><label htmlFor="sc">ক্রয়মূল্য / ইউনিট <i>*</i></label><input id="sc" className="in" inputMode="decimal" value={cost} onChange={(e) => setCost(e.target.value)} /></div>
      </div>
      <div className="f"><label htmlFor="ss">সরবরাহকারী</label><input id="ss" className="in" value={supplier} onChange={(e) => setSupplier(e.target.value)} placeholder="ঐচ্ছিক" /></div>
      <div className="f"><label htmlFor="sb">ব্যাচ / চালান নম্বর</label><input id="sb" className="in" value={batch} onChange={(e) => setBatch(e.target.value)} placeholder="ঐচ্ছিক" /></div>
      <KV label="মোট খরচ">{money(q * (c ?? 0))}</KV>
      <button type="button" className="btn full" disabled={!valid || pending} onClick={submit}>{pending ? "যোগ হচ্ছে…" : "গুদামে যোগ করুন"}</button>
      <div className="mu">প্রতিটি গ্রহণ আলাদা “লট” হিসেবে থাকে — পরে কোন লট কার টাকায় কেনা হলো, সেটাও এখান থেকে হিসাব হয়।</div>
    </section>
  );
}
