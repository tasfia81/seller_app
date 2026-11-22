"use client";

import { useState, useTransition } from "react";
import { useToast } from "@/components/ui/feedback";
import { EXPENSE_CATEGORY_LABELS } from "@/lib/api/labels";
import type { ApiProduct, ApiSellerRow } from "@/lib/api/types";
import { dhakaToday, parseMoney } from "@/lib/format";
import { addExpense } from "./actions";

export function ExpenseForm({ sellers, products }: { sellers: ApiSellerRow[]; products: ApiProduct[] }) {
  const toast = useToast();
  const [pending, start] = useTransition();
  const [cat, setCat] = useState("transport");
  const [amount, setAmount] = useState("");
  const [date, setDate] = useState(dhakaToday);
  const [desc, setDesc] = useState("");
  const [seller, setSeller] = useState("");
  const [product, setProduct] = useState("");
  const amt = parseMoney(amount);
  const valid = amt !== null && amt > 0 && desc.trim().length >= 2 && !!date;

  const submit = () => {
    if (!valid) return;
    start(async () => {
      const r = await addExpense({ category: cat, amount: amt!, date, description: desc.trim(), seller_id: seller || null, product_id: product || null });
      toast(r.ok ? (r.message ?? "সম্পন্ন হয়েছে।") : r.message, !r.ok);
      if (r.ok) {
        setAmount("");
        setDesc("");
        setSeller("");
        setProduct("");
      }
    });
  };

  return (
    <section className="drawer">
      <h2 className="h2">নতুন খরচ</h2>
      <div className="f">
        <span className="lb">ক্যাটাগরি <i>*</i></span>
        <div className="pills">{Object.entries(EXPENSE_CATEGORY_LABELS).map(([id, l]) => <button key={id} type="button" className={`pill${cat === id ? " sel" : ""}`} aria-pressed={cat === id} onClick={() => setCat(id)}>{l}</button>)}</div>
      </div>
      <div className="fg2">
        <div className="f"><label htmlFor="a">টাকা <i>*</i></label><input id="a" className="in" value={amount} onChange={(e) => setAmount(e.target.value)} placeholder="৳" inputMode="decimal" /></div>
        <div className="f"><label htmlFor="d">তারিখ <i>*</i></label><input id="d" type="date" className="in" value={date} onChange={(e) => setDate(e.target.value)} /></div>
      </div>
      <div className="f"><label htmlFor="ds">বিবরণ <i>*</i></label><input id="ds" className="in" value={desc} onChange={(e) => setDesc(e.target.value)} placeholder="যেমন: গুদাম থেকে মিরপুরে মাল নেওয়া" /></div>
      <div className="f"><label htmlFor="s">কোনো সেলারের জন্য? <small>(ঐচ্ছিক)</small></label><select id="s" className="in" value={seller} onChange={(e) => setSeller(e.target.value)}><option value="">নির্দিষ্ট নয়</option>{sellers.map((x) => <option key={x.id} value={x.id}>{x.name}</option>)}</select></div>
      <div className="f"><label htmlFor="p">কোনো পণ্যের জন্য? <small>(ঐচ্ছিক)</small></label><select id="p" className="in" value={product} onChange={(e) => setProduct(e.target.value)}><option value="">নির্দিষ্ট নয়</option>{products.map((x) => <option key={x.id} value={x.id}>{x.name}</option>)}</select></div>
      <button type="button" className="btn full" disabled={!valid || pending} onClick={submit}>{pending ? "সংরক্ষণ হচ্ছে…" : "খরচ সংরক্ষণ করুন"}</button>
    </section>
  );
}
