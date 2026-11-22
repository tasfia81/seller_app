"use client";

import { useState } from "react";
import { Icon } from "@/components/ui/Icon";
import { KV, Note } from "@/components/ui/bits";
import { ActionButton, Toggle } from "@/components/ui/feedback";
import { bnDigits, money, parseMoney } from "@/lib/format";
import { categories } from "@/lib/demo-data";

const UNITS = ["পিস", "কেজি", "গ্রাম", "লিটার", "প্যাকেট", "বোতল", "বক্স"];

export function ProductForm() {
  const [name, setName] = useState("পোলো টি-শার্ট");
  const [category, setCategory] = useState("টি-শার্ট");
  const [sku, setSku] = useState("TS-POLO");
  const [cost, setCost] = useState("২৬০");
  const [price, setPrice] = useState("৩৮০");
  const [min, setMin] = useState("৩৫০");
  const [max, setMax] = useState("৪২০");
  const [flexible, setFlexible] = useState(true);
  const [unit, setUnit] = useState("পিস");
  const [variantType, setVariantType] = useState("সাইজ");
  const [variants, setVariants] = useState(["M", "L", "XL"]);
  const [newVariant, setNewVariant] = useState("");

  const c = parseMoney(cost), p = parseMoney(price), lo = parseMoney(min), hi = parseMoney(max);
  const errors = {
    name: !name.trim() ? "পণ্যের নাম দিন।" : null,
    sku: !sku.trim() ? "SKU দিন।" : null,
    price: p === null || p <= 0 ? "সঠিক বিক্রয়মূল্য দিন।" : null,
    max: flexible && lo !== null && hi !== null && hi < lo ? "সর্বোচ্চ দাম সর্বনিম্নের চেয়ে কম হতে পারে না।" : null,
    range: flexible && p !== null && lo !== null && hi !== null && (p < lo || p > hi) ? "বিক্রয়মূল্য সর্বনিম্ন ও সর্বোচ্চের মধ্যে রাখুন।" : null,
  };
  const valid = Object.values(errors).every((e) => !e);
  const profit = p !== null && c !== null ? p - c : 0;
  const margin = p ? Math.round((profit / p) * 100) : 0;

  const addVariant = () => {
    const v = newVariant.trim();
    if (v && !variants.includes(v)) setVariants([...variants, v]);
    setNewVariant("");
  };

  return (
    <div className="two">
      <div className="a">
        <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 14 }}>
          <h2 className="h2">মূল তথ্য</h2>
          <div className="fg">
            <Field id="nm" label="পণ্যের নাম" req value={name} set={setName} error={errors.name} />
            <div className="f"><label htmlFor="ct">ক্যাটাগরি <i>*</i></label><select id="ct" className="in" value={category} onChange={(e) => setCategory(e.target.value)}>{categories.filter((x) => !x.archived).map((x) => <option key={x.name}>{x.name}</option>)}</select></div>
            <Field id="sk" label="SKU" req value={sku} set={setSku} error={errors.sku} hint="প্রতিটি পণ্যের আলাদা কোড" />
          </div>
          <div className="f"><label htmlFor="ds">বিবরণ <small>(ঐচ্ছিক)</small></label><textarea id="ds" className="in" defaultValue="কটন পোলো, বুকে লোগো। ধোয়ার পরও রং ঠিক থাকে।" /></div>
          <div className="f"><span className="lb">পণ্যের ছবি</span><label className="up"><Icon name="img" size={24} />ছবি বাছুন<span className="mu" style={{ fontWeight: 400 }}>JPG/PNG, সর্বোচ্চ ২MB</span><input type="file" accept="image/*" style={{ display: "none" }} /></label></div>
        </section>

        <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 14 }}>
          <h2 className="h2">দাম</h2>
          <div className="fg">
            <Field id="pc" label="ক্রয়মূল্য (৳)" req value={cost} set={setCost} hint="সেলার কখনো দেখবেন না" />
            <Field id="sp" label="বিক্রয়মূল্য (৳)" req value={price} set={setPrice} error={errors.price ?? errors.range} />
            {flexible ? <Field id="mn" label="সর্বনিম্ন দাম (৳)" value={min} set={setMin} /> : null}
            {flexible ? <Field id="mx" label="সর্বোচ্চ দাম (৳)" value={max} set={setMax} error={errors.max} /> : null}
          </div>
          <div className="f">
            <span className="lb">সেলার দাম বদলাতে পারবেন?</span>
            <div className="seg" role="radiogroup">
              <button type="button" className={!flexible ? "on" : ""} onClick={() => setFlexible(false)}>না, নির্ধারিত</button>
              <button type="button" className={flexible ? "on" : ""} onClick={() => setFlexible(true)}>হ্যাঁ, সীমার মধ্যে</button>
            </div>
          </div>
          <Note>ক্রয়মূল্য বদলালে শুধু নতুন স্টকে লাগবে — আগের বিক্রির লাভের হিসাব বদলাবে না।</Note>
        </section>

        <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 14 }}>
          <h2 className="h2">স্টক ও ইউনিট</h2>
          <div className="fg">
            <div className="f"><label htmlFor="un">বিক্রির ইউনিট</label><select id="un" className="in" value={unit} onChange={(e) => setUnit(e.target.value)}>{UNITS.map((u) => <option key={u}>{u}</option>)}</select></div>
            <div className="f"><label htmlFor="pr">পরিমাণের ধাপ</label><select id="pr" className="in" defaultValue={unit === "কেজি" || unit === "লিটার" ? "০.৫ করে" : "পূর্ণ সংখ্যা"}><option>পূর্ণ সংখ্যা</option><option>০.৫ করে</option><option>০.১ করে</option></select></div>
            <div className="f"><label htmlFor="ls">কম স্টকের সীমা</label><input id="ls" className="in" defaultValue="১০" /></div>
          </div>
          <div>
            <div className="sh" style={{ marginBottom: 8 }}>
              <label className="t1" htmlFor="vt">ধরন (ভ্যারিয়েন্ট)</label>
              <select id="vt" className="in" style={{ width: 160, height: 36 }} value={variantType} onChange={(e) => setVariantType(e.target.value)}><option>সাইজ</option><option>রং</option><option>স্বাদ</option><option>ওজন</option></select>
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
          {[
            ["স্টক হিসাব রাখা হবে", "প্রতিটি বিক্রিতে স্টক কমবে", true],
            ["মেয়াদ ট্র্যাক করুন", "খাবার বা ওষুধের মতো পণ্যের জন্য", false],
            ["ডিসকাউন্ট দেওয়া যাবে", "", false],
            ["এই পণ্যে আলাদা কমিশন", "সেলারের সাধারণ নিয়মের বদলে", false],
            ["পণ্য চালু আছে", "বন্ধ করলে নতুন বরাদ্দ দেওয়া যাবে না", true],
          ].map(([t, s, on]) => (
            <div key={t as string} className="tg"><span>{t}{s ? <small>{s}</small> : null}</span><Toggle label={t as string} defaultOn={on as boolean} /></div>
          ))}
        </section>
      </div>

      <div className="b sticky">
        <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          <h2 className="h2">সারাংশ</h2>
          <div className="sl"><span className="th" style={{ width: 52, height: 52 }}><Icon name="shirt" size={24} /></span><div><b>{name || "নাম নেই"}</b><span className="mu">{category} · {sku}</span></div></div>
          <KV label="বিক্রয়মূল্য">{p !== null ? `${money(p)} / ${unit}` : "—"}</KV>
          <KV label={`প্রতি ${unit} মোট লাভ`}><span style={{ color: profit >= 0 ? "#0F6A38" : "#A92F2F" }}>{money(profit)}</span></KV>
          <KV label="মার্জিন">{bnDigits(margin)}%</KV>
          <KV label={variantType}>{variants.join(", ") || "নেই"}</KV>
          <ActionButton className="btn full" disabled={!valid}>পণ্য সংরক্ষণ করুন</ActionButton>
          {!valid ? <span className="err">লাল চিহ্নিত ঘরগুলো ঠিক করুন।</span> : null}
        </section>
      </div>
    </div>
  );
}

function Field({ id, label, req, value, set, error, hint }: { id: string; label: string; req?: boolean; value: string; set: (v: string) => void; error?: string | null; hint?: string }) {
  return (
    <div className="f">
      <label htmlFor={id}>{label} {req ? <i>*</i> : null}</label>
      <input id={id} className={`in${error ? " e" : ""}`} value={value} onChange={(e) => set(e.target.value)} />
      {error ? <span className="err">{error}</span> : hint ? <span className="hint">{hint}</span> : null}
    </div>
  );
}
