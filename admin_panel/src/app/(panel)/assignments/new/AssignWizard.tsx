"use client";

import Link from "next/link";
import { useState, useTransition } from "react";
import { Icon } from "@/components/ui/Icon";
import { Avatar, KV, Note } from "@/components/ui/bits";
import { ConfirmDialog, useToast } from "@/components/ui/feedback";
import type { ApiProduct, ApiSellerRow } from "@/lib/api/types";
import { bnDigits, money, toAscii } from "@/lib/format";
import { createAssignment } from "../actions";

type Line = { productId: string; variant: string; quantityText: string };
type Policy = "seller_default" | "daily_return" | "carry_forward";
const POLICY_LABEL = { daily_return: "প্রতিদিন ফেরত", carry_forward: "পরের দিনে চলবে" } as const;

export function AssignWizard({ sellers, products, stock }: { sellers: ApiSellerRow[]; products: ApiProduct[]; stock: Record<string, number> }) {
  const toast = useToast();
  const [pending, start] = useTransition();
  const [sellerId, setSellerId] = useState(sellers[0]?.id ?? "");
  const [lines, setLines] = useState<Line[]>([]);
  const [flexible, setFlexible] = useState(false);
  const [discount, setDiscount] = useState(false);
  const [policy, setPolicy] = useState<Policy>("seller_default");
  const [adding, setAdding] = useState("");
  const [confirm, setConfirm] = useState(false);

  if (!sellers.length) return <Note kind="warn">কোনো সক্রিয় সেলার নেই। আগে <Link href="/applications">সেলার আবেদন</Link> অনুমোদন করুন।</Note>;
  const available = (pid: string, variant: string) => stock[`${pid}|${variant}`] ?? 0;
  const hasStock = (p: ApiProduct) => (p.variants.length ? p.variants.some((v) => available(p.id, v) > 0) : available(p.id, "") > 0);
  if (!products.some(hasStock)) {
    return (
      <div className="cd">
        <Note kind="warn">
          {products.length ? "পণ্য তৈরি হয়েছে। বরাদ্দ দেওয়ার আগে গুদামে ইউনিট যোগ করুন।" : "বরাদ্দ দেওয়ার আগে একটি পণ্য তৈরি করে গুদামে ইউনিট যোগ করুন।"}
        </Note>
        <Link className="btn o" href={products.length ? "/inventory#receive-stock" : "/products/new"}>
          {products.length ? "স্টক গ্রহণ করুন" : "পণ্য যোগ করুন"}
        </Link>
      </div>
    );
  }

  const seller = sellers.find((s) => s.id === sellerId)!;
  const rows = lines.map((l) => {
    const p = products.find((x) => x.id === l.productId)!;
    const wh = available(p.id, l.variant);
    const qty = Number(toAscii(l.quantityText));
    const steps = qty / p.quantity_step;
    const invalid = !Number.isFinite(qty) || qty <= 0 || Math.abs(steps - Math.round(steps)) > 1e-6;
    return { ...l, p, wh, qty, over: qty > wh, invalid };
  });
  const hasError = rows.some((r) => r.over || r.invalid) || rows.length === 0;
  const total = rows.reduce((a, r) => a + r.qty * r.p.price, 0);
  const amounts = new Map<string, number>();
  for (const row of rows) amounts.set(row.p.unit_label, (amounts.get(row.p.unit_label) ?? 0) + row.qty);
  const summary = [...amounts].map(([unit, qty]) => `${bnDigits(Number(qty.toFixed(4)))} ${unit}`).join(" · ");
  const effectivePolicy = policy === "seller_default" ? seller.policy : policy;

  const setQty = (i: number, quantityText: string) => {
    if (!/^\d*(\.\d*)?$/.test(toAscii(quantityText))) return;
    setLines(lines.map((l, j) => (j === i ? { ...l, quantityText } : l)));
  };
  const addLine = () => {
    const p = products.find((x) => x.id === adding);
    if (!p) return;
    const variant = p.variants.find((v) => available(p.id, v) > 0 && !lines.some((l) => l.productId === p.id && l.variant === v)) ?? (p.variants.length ? null : "");
    if (variant === null || lines.some((l) => l.productId === p.id && l.variant === variant)) return toast("এই পণ্যের সব ধরন আগেই যোগ হয়েছে বা স্টক নেই।", true);
    setLines([...lines, { productId: p.id, variant, quantityText: bnDigits(p.quantity_step) }]);
    setAdding("");
  };

  const submit = () =>
    start(async () => {
      const r = await createAssignment({
        seller_id: sellerId,
        items: rows.map((x) => ({ product_id: x.productId, variant: x.variant || null, quantity: x.qty })),
        price_mode: flexible ? "flexible" : "fixed",
        discount_allowed: discount,
        policy,
      });
      if (r && !r.ok) toast(r.message, true);
    });

  return (
    <div className="two">
      <div className="a">
        <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          <h2 className="h2">১. সেলার বাছাই</h2>
          <div className="f" style={{ maxWidth: 420 }}>
            <label htmlFor="sel">সেলার</label>
            <select id="sel" className="in" value={sellerId} onChange={(e) => setSellerId(e.target.value)}>
              {sellers.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
            </select>
          </div>
          <div className="sl"><Avatar name={seller.name} /><div><b>{seller.name}</b><span className="mu">{bnDigits(seller.compensation)} · {seller.policy_label}</span></div></div>
          {seller.cash_due > 0 ? <Note kind="warn" icon="alert">এই সেলারের কাছে {money(seller.cash_due)} ক্যাশ বাকি আছে। চাইলে তবুও স্টক দিতে পারবেন।</Note> : null}
        </section>

        <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          <div className="sh">
            <h2 className="h2">২. পণ্য ও পরিমাণ</h2>
            <div style={{ display: "flex", gap: 6 }}>
              <select className="in" style={{ height: 36, width: 200 }} aria-label="পণ্য যোগ" value={adding} onChange={(e) => setAdding(e.target.value)}>
                <option value="">পণ্য বাছুন</option>
                {products.filter(hasStock).map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
              </select>
              <button type="button" className="btn o sm" onClick={addLine} disabled={!adding}><Icon name="plus" size={16} />যোগ</button>
            </div>
          </div>
          {rows.map((r, i) => (
            <div key={r.productId + r.variant} style={{ display: "flex", alignItems: "center", gap: 12, flexWrap: "wrap", border: `1px solid ${r.over ? "#E7B4B4" : "#E4EBE6"}`, borderRadius: 12, padding: "10px 12px" }}>
              <span className="th"><Icon name="tag" size={18} /></span>
              <div className="fx" style={{ minWidth: 160 }}>
                <b className="t1">{r.p.name}</b>
                {r.over ? <div className="err">গুদামে মাত্র {bnDigits(r.wh)} {r.p.unit_label} আছে</div> : <div className="mu">গুদামে: {bnDigits(r.wh)} {r.p.unit_label}</div>}
              </div>
              {r.p.variants.length ? (
                <select className="in" aria-label="ধরন" style={{ width: 90 }} value={r.variant} onChange={(e) => setLines(lines.map((l, j) => (j === i ? { ...l, variant: e.target.value } : l)))}>
                  {r.p.variants.map((v) => <option key={v} value={v} disabled={v !== r.variant && (available(r.p.id, v) === 0 || lines.some((line) => line.productId === r.productId && line.variant === v))}>{v} ({bnDigits(available(r.p.id, v))})</option>)}
                </select>
              ) : null}
              <div className={`qty${r.over ? " e" : ""}`}>
                <button type="button" aria-label="কমান" onClick={() => setQty(i, bnDigits(Number(Math.max(0, r.qty - r.p.quantity_step).toFixed(4))))}>−</button>
                <input aria-label="পরিমাণ" value={r.quantityText} onChange={(e) => setQty(i, e.target.value)} inputMode="decimal" />
                <button type="button" aria-label="বাড়ান" onClick={() => setQty(i, bnDigits(Number((r.qty + r.p.quantity_step).toFixed(4))))}>+</button>
              </div>
              <span className="mu">{r.p.unit_label}</span>
              {r.invalid ? <span className="err">{bnDigits(r.p.quantity_step)} {r.p.unit_label} করে দিন।</span> : null}
              <button type="button" className="ib" aria-label="সরান" style={{ width: 36, height: 36, color: "#A92F2F" }} onClick={() => setLines(lines.filter((_, j) => j !== i))}><Icon name="x" size={18} /></button>
            </div>
          ))}
          {rows.length === 0 ? <div className="mu">উপর থেকে অন্তত একটি পণ্য যোগ করুন।</div> : null}
        </section>

        <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          <h2 className="h2">৩. দামের নিয়ম</h2>
          <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
            <label className={`opt${!flexible ? " on" : ""}`}><input type="radio" name="pr" checked={!flexible} onChange={() => setFlexible(false)} /><span><b>নির্ধারিত দাম</b>সেলার দাম বদলাতে পারবেন না</span></label>
            <label className={`opt${flexible ? " on" : ""}`}><input type="radio" name="pr" checked={flexible} onChange={() => setFlexible(true)} /><span><b>সীমার মধ্যে বদলানো যাবে</b>পণ্যের সর্বনিম্ন–সর্বোচ্চ দাম মেনে</span></label>
          </div>
          <label className="ck"><input type="checkbox" checked={discount} onChange={() => setDiscount(!discount)} /> ডিসকাউন্ট দিতে পারবেন</label>
        </section>

        <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          <h2 className="h2">৪. স্টকের নিয়ম</h2>
          <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
            {([["seller_default", "সেলারের ডিফল্ট", `এখন: ${seller.policy_label}`], ["daily_return", "প্রতিদিন ফেরত", "দিন শেষে বাকি পণ্য ফেরত"], ["carry_forward", "পরের দিনে চলবে", "বাকি পণ্য সেলারের কাছে থাকবে"]] as const).map(([id, t, s]) => (
              <label key={id} className={`opt${policy === id ? " on" : ""}`}><input type="radio" name="po" checked={policy === id} onChange={() => setPolicy(id)} /><span><b>{t}</b>{s}</span></label>
            ))}
          </div>
        </section>
      </div>

      <div className="b sticky">
        <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 8 }}>
          <h2 className="h2">৫. বরাদ্দের সারাংশ</h2>
          <KV label="সেলার">{seller.name}</KV>
          {rows.map((r) => (
            <KV key={r.productId + r.variant} label={`${r.p.name}${r.variant ? ` (${r.variant})` : ""}`}>
              <span style={r.over ? { color: "#A92F2F" } : undefined}>{bnDigits(r.qty)} {r.p.unit_label}{r.over ? " — বেশি" : ""}</span>
            </KV>
          ))}
          <KV label="দামের নিয়ম">{flexible ? "সীমার মধ্যে" : "নির্ধারিত"}{discount ? " · ডিসকাউন্ট" : ""}</KV>
          <KV label="স্টকের নিয়ম">{POLICY_LABEL[effectivePolicy]}</KV>
          <KV label="মোট বিক্রয়মূল্য" total>{money(total)}</KV>
          <Note icon="truck">নিশ্চিত করলে অবস্থা হবে <b>“হস্তান্তর বাকি”</b>। সেলার অ্যাপে বুঝে নেওয়ার পরই স্টক তার নামে যাবে।</Note>
          <button type="button" className="btn full" disabled={hasError || pending} onClick={() => setConfirm(true)}>{pending ? "তৈরি হচ্ছে…" : "যাচাই করে নিশ্চিত করুন"}</button>
          {hasError && rows.length ? <span className="err">পণ্যের পরিমাণ ও গুদামের স্টক মিলিয়ে দেখুন।</span> : null}
        </section>
      </div>
      <ConfirmDialog
        open={confirm}
        title="বরাদ্দ নিশ্চিত করবেন?"
        message={`${seller.name}-কে ${summary} (${money(total)})।`}
        confirmLabel="নিশ্চিত করুন"
        onConfirm={submit}
        onClose={() => setConfirm(false)}
      />
    </div>
  );
}
