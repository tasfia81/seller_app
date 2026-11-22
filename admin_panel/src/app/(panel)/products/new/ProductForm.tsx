"use client";

import Link from "next/link";
import { useState, useTransition } from "react";
import { Icon } from "@/components/ui/Icon";
import { KV, Note } from "@/components/ui/bits";
import { useToast } from "@/components/ui/feedback";
import { UNIT_LABELS, type ApiCategory, type ApiProduct, type ApiUnit } from "@/lib/api/types";
import { bnDigits, money, parseMoney } from "@/lib/format";
import { saveProduct } from "../actions";

const STEPS = [
  { v: 1, label: "পূর্ণ সংখ্যা" },
  { v: 0.5, label: "০.৫ করে" },
  { v: 0.1, label: "০.১ করে" },
];

export function ProductForm({ categories, product }: { categories: ApiCategory[]; product: ApiProduct | null }) {
  const toast = useToast();
  const [pending, start] = useTransition();
  const p0 = product;
  const editing = !!p0;
  const [name, setName] = useState(p0?.name ?? "");
  const [categoryId, setCategoryId] = useState(p0?.category_id ?? categories[0]?.id ?? "");
  const [sku, setSku] = useState(p0?.sku ?? "");
  const [description, setDescription] = useState(p0?.description ?? "");
  const [cost, setCost] = useState(p0 ? bnDigits(p0.unit_cost) : "");
  const [price, setPrice] = useState(p0 ? bnDigits(p0.price) : "");
  const [min, setMin] = useState(p0?.min_price ? bnDigits(p0.min_price) : "");
  const [max, setMax] = useState(p0?.max_price ? bnDigits(p0.max_price) : "");
  const [flexible, setFlexible] = useState(p0?.price_editable ?? false);
  const [unit, setUnit] = useState<ApiUnit>(p0?.unit ?? "piece");
  const [step, setStep] = useState(p0?.quantity_step ?? 1);
  const [low, setLow] = useState(p0 ? bnDigits(p0.low_stock_at) : "১০");
  const [variantLabel, setVariantLabel] = useState(p0?.variant_label ?? "সাইজ");
  const [variants, setVariants] = useState<string[]>(p0?.variants ?? []);
  const [newVariant, setNewVariant] = useState("");
  const [flags, setFlags] = useState({
    track_stock: p0?.track_stock ?? true,
    track_expiry: p0?.track_expiry ?? false,
    discount_allowed: p0?.discount_allowed ?? false,
    active: p0?.active ?? true,
  });

  const c = parseMoney(cost), pr = parseMoney(price), lo = parseMoney(min), hi = parseMoney(max), lw = parseMoney(low);
  const errors = {
    name: name.trim().length < 2 ? "পণ্যের নাম দিন।" : null,
    category: !categoryId ? "ক্যাটাগরি বাছুন (আগে পণ্য পেজে ক্যাটাগরি যোগ করুন)।" : null,
    sku: sku.trim().length < 2 ? "SKU দিন।" : null,
    cost: c === null || c < 0 ? "সঠিক ক্রয়মূল্য দিন।" : null,
    price: pr === null || pr <= 0 ? "সঠিক বিক্রয়মূল্য দিন।" : null,
    min: flexible && (lo === null || lo <= 0) ? "সর্বনিম্ন দাম দিন।" : null,
    max: flexible && (hi === null || (lo !== null && hi < lo)) ? "সর্বোচ্চ দাম সর্বনিম্নের চেয়ে কম হতে পারে না।" : null,
    range: flexible && pr !== null && lo !== null && hi !== null && (pr < lo || pr > hi) ? "বিক্রয়মূল্য সর্বনিম্ন ও সর্বোচ্চের মধ্যে রাখুন।" : null,
    low: lw === null || lw < 0 ? "সঠিক সংখ্যা দিন।" : null,
  };
  const valid = Object.values(errors).every((e) => !e);
  const profit = pr !== null && c !== null ? pr - c : 0;
  const margin = pr ? Math.round((profit / pr) * 100) : 0;
  const unitLabel = UNIT_LABELS[unit];

  const addVariant = () => {
    const v = newVariant.trim();
    if (v && !variants.includes(v)) setVariants([...variants, v]);
    setNewVariant("");
  };

  const submit = () => {
    if (!valid) return;
    start(async () => {
      const r = await saveProduct(product?.id ?? null, {
        name: name.trim(),
        category_id: categoryId,
        sku: sku.trim(),
        description: description.trim() || null,
        unit,
        quantity_step: step,
        unit_cost: c!,
        price: pr!,
        min_price: flexible ? lo : null,
        max_price: flexible ? hi : null,
        price_editable: flexible,
        variant_label: variants.length ? variantLabel : null,
        variants,
        low_stock_at: lw!,
        ...flags,
      });
      if (r && !r.ok) toast(r.message, true);
    });
  };

  if (!categories.length) {
    return <Note kind="warn">পণ্য যোগ করার আগে অন্তত একটি ক্যাটাগরি দরকার। <Link href="/products">পণ্য ও ক্যাটাগরি</Link> পেজে গিয়ে যোগ করুন।</Note>;
  }

  return (
    <div className="two">
      <div className="a">
        <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 14 }}>
          <h2 className="h2">মূল তথ্য</h2>
          <div className="fg">
            <Field id="nm" label="পণ্যের নাম" req value={name} set={setName} error={errors.name} />
            <div className="f">
              <label htmlFor="ct">ক্যাটাগরি <i>*</i></label>
              <select id="ct" className="in" value={categoryId} onChange={(e) => setCategoryId(e.target.value)}>
                {categories.map((x) => <option key={x.id} value={x.id}>{x.name}</option>)}
              </select>
            </div>
            <Field id="sk" label="SKU" req value={sku} set={setSku} error={errors.sku} hint={editing ? "SKU পরে বদলানো যায় না" : "প্রতিটি পণ্যের আলাদা কোড"} disabled={editing} />
          </div>
          <div className="f"><label htmlFor="ds">বিবরণ <small>(ঐচ্ছিক)</small></label><textarea id="ds" className="in" value={description} onChange={(e) => setDescription(e.target.value)} /></div>
        </section>

        <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 14 }}>
          <h2 className="h2">দাম</h2>
          <div className="fg">
            <Field id="pc" label="ক্রয়মূল্য (৳)" req value={cost} set={setCost} error={errors.cost} hint="সেলার কখনো দেখবেন না" />
            <Field id="sp" label="বিক্রয়মূল্য (৳)" req value={price} set={setPrice} error={errors.price ?? errors.range} />
            {flexible ? <Field id="mn" label="সর্বনিম্ন দাম (৳)" req value={min} set={setMin} error={errors.min} /> : null}
            {flexible ? <Field id="mx" label="সর্বোচ্চ দাম (৳)" req value={max} set={setMax} error={errors.max} /> : null}
          </div>
          <div className="f">
            <span className="lb">সেলার দাম বদলাতে পারবেন?</span>
            <div className="seg" role="radiogroup">
              <button type="button" role="radio" aria-checked={!flexible} className={!flexible ? "on" : ""} onClick={() => setFlexible(false)}>না, নির্ধারিত</button>
              <button type="button" role="radio" aria-checked={flexible} className={flexible ? "on" : ""} onClick={() => setFlexible(true)}>হ্যাঁ, সীমার মধ্যে</button>
            </div>
          </div>
          <Note>ক্রয়মূল্য বদলালে শুধু নতুন স্টকে লাগবে — আগের বিক্রির লাভের হিসাব বদলাবে না।</Note>
        </section>

        <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 14 }}>
          <h2 className="h2">স্টক ও ইউনিট</h2>
          <div className="fg">
            <div className="f">
              <label htmlFor="un">বিক্রির ইউনিট</label>
              <select id="un" className="in" value={unit} disabled={editing} onChange={(e) => setUnit(e.target.value as ApiUnit)}>
                {(Object.keys(UNIT_LABELS) as ApiUnit[]).map((u) => <option key={u} value={u}>{UNIT_LABELS[u]}</option>)}
              </select>
            </div>
            <div className="f">
              <label htmlFor="pr">পরিমাণের ধাপ</label>
              <select id="pr" className="in" value={step} disabled={editing} onChange={(e) => setStep(Number(e.target.value))}>
                {STEPS.map((s) => <option key={s.v} value={s.v}>{s.label}</option>)}
              </select>
            </div>
            <Field id="ls" label="কম স্টকের সীমা" value={low} set={setLow} error={errors.low} />
          </div>
          <div>
            <div className="sh" style={{ marginBottom: 8 }}>
              <label className="t1" htmlFor="vt">ধরন (ভ্যারিয়েন্ট) <small className="mu">ঐচ্ছিক</small></label>
              <select id="vt" className="in" style={{ width: 160, height: 36 }} value={variantLabel} disabled={editing} onChange={(e) => setVariantLabel(e.target.value)}>
                <option>সাইজ</option><option>রং</option><option>স্বাদ</option><option>ওজন</option>
              </select>
            </div>
            <div className="pills">
              {variants.map((v) => (
                <span key={v} className="pill sel" style={{ paddingRight: 4 }}>
                  {v}
                  <button type="button" aria-label={`${v} সরান`} onClick={() => setVariants(variants.filter((x) => x !== v))} style={{ border: 0, background: "none", width: 26, height: 26, color: "#0F6A38", display: "flex", alignItems: "center", justifyContent: "center" }}><Icon name="x" size={14} /></button>
                </span>
              ))}
              <input className="in" style={{ width: 110, height: 36 }} placeholder="নতুন" aria-label="নতুন ধরন" value={newVariant} onChange={(e) => setNewVariant(e.target.value)} onKeyDown={(e) => e.key === "Enter" && (e.preventDefault(), addVariant())} />
              <button type="button" className="pill" onClick={addVariant}><Icon name="plus" size={16} />যোগ</button>
            </div>
          </div>
        </section>

        <section className="cd">
          <h2 className="h2" style={{ marginBottom: 4 }}>অন্যান্য সেটিং</h2>
          {([
            ["track_stock", "স্টক হিসাব রাখা হবে", "প্রতিটি বিক্রিতে স্টক কমবে", editing],
            ["track_expiry", "মেয়াদ ট্র্যাক করুন", "খাবার বা ওষুধের মতো পণ্যের জন্য", editing],
            ["discount_allowed", "ডিসকাউন্ট দেওয়া যাবে", "", false],
            ["active", "পণ্য চালু আছে", "বন্ধ করলে নতুন বরাদ্দ ও বিক্রি হবে না", false],
          ] as const).map(([k, t, s, locked]) => (
            <div key={k} className="tg">
              <span>{t}{s ? <small>{s}</small> : null}</span>
              <button type="button" className="sw" role="switch" aria-checked={flags[k]} aria-label={t} disabled={locked} onClick={() => setFlags({ ...flags, [k]: !flags[k] })} />
            </div>
          ))}
        </section>
      </div>

      <div className="b sticky">
        <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          <h2 className="h2">সারাংশ</h2>
          <div className="sl"><span className="th" style={{ width: 52, height: 52 }}><Icon name="tag" size={24} /></span><div><b>{name || "নাম নেই"}</b><span className="mu">{categories.find((x) => x.id === categoryId)?.name} · {sku || "SKU নেই"}</span></div></div>
          <KV label="বিক্রয়মূল্য">{pr !== null ? `${money(pr)} / ${unitLabel}` : "—"}</KV>
          <KV label={`প্রতি ${unitLabel} মোট লাভ`}><span style={{ color: profit >= 0 ? "#0F6A38" : "#A92F2F" }}>{money(profit)}</span></KV>
          <KV label="মার্জিন">{bnDigits(margin)}%</KV>
          <KV label={variantLabel}>{variants.join(", ") || "নেই"}</KV>
          <button type="button" className="btn full" disabled={!valid || pending} onClick={submit}>
            {pending ? "সংরক্ষণ হচ্ছে…" : editing ? "পরিবর্তন সংরক্ষণ করুন" : "পণ্য সংরক্ষণ করুন"}
          </button>
          {!valid ? <span className="err">লাল চিহ্নিত ঘরগুলো ঠিক করুন।</span> : null}
          {editing ? <div className="mu">SKU, ইউনিট, ধাপ ও ধরনের নাম বিক্রি শুরু হওয়ার পর বদলানো যায় না।</div> : null}
        </section>
      </div>
    </div>
  );
}

function Field({ id, label, req, value, set, error, hint, disabled }: { id: string; label: string; req?: boolean; value: string; set: (v: string) => void; error?: string | null; hint?: string; disabled?: boolean }) {
  return (
    <div className="f">
      <label htmlFor={id}>{label} {req ? <i>*</i> : null}</label>
      <input id={id} className={`in${error ? " e" : ""}`} value={value} disabled={disabled} onChange={(e) => set(e.target.value)} />
      {error ? <span className="err">{error}</span> : hint ? <span className="hint">{hint}</span> : null}
    </div>
  );
}
