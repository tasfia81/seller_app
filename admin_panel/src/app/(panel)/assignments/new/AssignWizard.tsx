"use client";

import { useState } from "react";
import { Icon } from "@/components/ui/Icon";
import { Avatar, KV, Note } from "@/components/ui/bits";
import { ActionButton } from "@/components/ui/feedback";
import { products, sellers } from "@/lib/demo-data";
import { bnDigits, money, toAscii } from "@/lib/format";
import { policyLabel } from "@/lib/labels";

type Line = { productId: string; variant: string; qty: number };

export function AssignWizard() {
  const [sellerId, setSellerId] = useState("rakib");
  const [lines, setLines] = useState<Line[]>([
    { productId: "jersey-bd", variant: "L", qty: 20 },
    { productId: "polo", variant: "XL", qty: 10 },
    { productId: "cap", variant: "", qty: 10 },
  ]);
  const [flexible, setFlexible] = useState(true);
  const [discount, setDiscount] = useState(false);
  const [policy, setPolicy] = useState<"default" | "dailyReturn" | "carryForward">("default");
  const [adding, setAdding] = useState("");

  const seller = sellers.find((s) => s.id === sellerId)!;
  const assignable = sellers.filter((s) => s.status === "active");
  const rows = lines.map((l) => {
    const p = products.find((x) => x.id === l.productId)!;
    return { ...l, p, over: l.qty > p.warehouse, invalid: l.qty <= 0 };
  });
  const hasError = rows.some((r) => r.over || r.invalid) || rows.length === 0;
  const total = rows.reduce((a, r) => a + r.qty * r.p.price, 0);
  const effectivePolicy = policy === "default" ? seller.policy : policy;

  const setQty = (i: number, qty: number) => setLines(lines.map((l, j) => (j === i ? { ...l, qty: Math.max(0, qty) } : l)));
  const addLine = () => {
    const p = products.find((x) => x.id === adding);
    if (!p || lines.some((l) => l.productId === p.id)) return;
    setLines([...lines, { productId: p.id, variant: p.variants[0] ?? "", qty: 1 }]);
    setAdding("");
  };

  const stepDone = [true, !hasError, true, true];
  return (
    <>
      <div className="steps" aria-label="ধাপ">
        {["সেলার", "পণ্য", "দামের নিয়ম", "স্টকের নিয়ম", "যাচাই ও নিশ্চিত"].map((s, i) => (
          <span key={s} className={`step${i < 4 && stepDone[i] ? " d" : i === 1 ? " c" : ""}`}>
            <b>{i < 4 && stepDone[i] ? "✓" : bnDigits(i + 1)}</b>
            {s}
          </span>
        ))}
      </div>
      <div className="two">
        <div className="a">
          <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            <h2 className="h2">১. সেলার বাছাই</h2>
            <div className="f" style={{ maxWidth: 420 }}>
              <label htmlFor="sel">সেলার</label>
              <select id="sel" className="in" value={sellerId} onChange={(e) => setSellerId(e.target.value)}>
                {assignable.map((s) => <option key={s.id} value={s.id}>{s.name} · হাতে {bnDigits(s.available)} পিস</option>)}
              </select>
            </div>
            <div className="sl"><Avatar name={seller.name} /><div><b>{seller.name}</b><span className="mu">সক্রিয় · হাতে {bnDigits(seller.available)} পিস · {policyLabel[seller.policy]}</span></div></div>
            {seller.cashDue > 0 ? <Note kind="warn" icon="alert">এই সেলারের কাছে {money(seller.cashDue)} ক্যাশ বাকি আছে। চাইলে তবুও স্টক দিতে পারবেন।</Note> : null}
          </section>

          <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 10 }}>
            <div className="sh">
              <h2 className="h2">২. পণ্য ও পরিমাণ</h2>
              <div style={{ display: "flex", gap: 6 }}>
                <select className="in" style={{ height: 36, width: 200 }} aria-label="পণ্য যোগ" value={adding} onChange={(e) => setAdding(e.target.value)}>
                  <option value="">পণ্য বাছুন</option>
                  {products.filter((p) => p.warehouse > 0 && !lines.some((l) => l.productId === p.id)).map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
                </select>
                <button type="button" className="btn o sm" onClick={addLine} disabled={!adding}><Icon name="plus" size={16} />যোগ</button>
              </div>
            </div>
            {rows.map((r, i) => (
              <div key={r.productId} style={{ display: "flex", alignItems: "center", gap: 12, flexWrap: "wrap", border: `1px solid ${r.over ? "#E7B4B4" : "#E4EBE6"}`, borderRadius: 12, padding: "10px 12px" }}>
                <span className="th"><Icon name={r.p.category === "অ্যাক্সেসরিজ" ? "tag" : "shirt"} size={18} /></span>
                <div className="fx" style={{ minWidth: 160 }}>
                  <b className="t1">{r.p.name}</b>
                  {r.over ? <div className="err">গুদামে মাত্র {bnDigits(r.p.warehouse)} {r.p.unit} আছে</div> : <div className="mu">গুদামে: {bnDigits(r.p.warehouse)} {r.p.unit}</div>}
                </div>
                {r.p.variants.length ? (
                  <select className="in" aria-label="ধরন" style={{ width: 90 }} value={r.variant} onChange={(e) => setLines(lines.map((l, j) => (j === i ? { ...l, variant: e.target.value } : l)))}>
                    {r.p.variants.map((v) => <option key={v}>{v}</option>)}
                  </select>
                ) : null}
                <div className={`qty${r.over ? " e" : ""}`}>
                  <button type="button" aria-label="কমান" onClick={() => setQty(i, r.qty - 1)}>−</button>
                  <input aria-label="পরিমাণ" value={bnDigits(r.qty)} onChange={(e) => setQty(i, Number(toAscii(e.target.value).replace(/\D/g, "")) || 0)} inputMode="numeric" />
                  <button type="button" aria-label="বাড়ান" onClick={() => setQty(i, r.qty + 1)}>+</button>
                </div>
                <span className="mu">{r.p.unit}</span>
                <button type="button" className="ib" aria-label="সরান" style={{ width: 36, height: 36, color: "#A92F2F" }} onClick={() => setLines(lines.filter((_, j) => j !== i))}><Icon name="x" size={18} /></button>
              </div>
            ))}
            {rows.length === 0 ? <div className="mu">অন্তত একটি পণ্য যোগ করুন।</div> : null}
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
              {([["default", "সেলারের ডিফল্ট", `এখন: ${policyLabel[seller.policy]}`], ["dailyReturn", "প্রতিদিন ফেরত", "দিন শেষে বাকি পণ্য ফেরত"], ["carryForward", "পরের দিনে চলবে", "বাকি পণ্য সেলারের কাছে থাকবে"]] as const).map(([id, t, s]) => (
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
              <KV key={r.productId} label={`${r.p.name}${r.variant ? ` (${r.variant})` : ""}`}>
                <span style={r.over ? { color: "#A92F2F" } : undefined}>{bnDigits(r.qty)} {r.p.unit}{r.over ? " — বেশি" : ""}</span>
              </KV>
            ))}
            <KV label="দামের নিয়ম">{flexible ? "সীমার মধ্যে" : "নির্ধারিত"}{discount ? " · ডিসকাউন্ট" : ""}</KV>
            <KV label="স্টকের নিয়ম">{policyLabel[effectivePolicy]}</KV>
            <KV label="মোট বিক্রয়মূল্য" total>{money(total)}</KV>
            <Note icon="truck">নিশ্চিত করলে অবস্থা হবে <b>“হস্তান্তর বাকি”</b>। সেলার অ্যাপে বুঝে নেওয়ার পরই স্টক তার নামে যাবে।</Note>
            <ActionButton
              className="btn full"
              disabled={hasError}
              confirm={{ title: "বরাদ্দ নিশ্চিত করবেন?", message: `${seller.name}-কে ${bnDigits(rows.reduce((a, r) => a + r.qty, 0))}টি পণ্য (${money(total)})।`, label: "নিশ্চিত করুন" }}
            >
              যাচাই করে নিশ্চিত করুন
            </ActionButton>
            {hasError ? <span className="err">লাল চিহ্নিত পরিমাণ ঠিক করুন।</span> : null}
          </section>
        </div>
      </div>
    </>
  );
}
