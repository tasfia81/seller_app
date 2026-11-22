"use client";

import { useState } from "react";
import { Icon } from "@/components/ui/Icon";
import { ActionButton } from "@/components/ui/feedback";
import { products, sellers } from "@/lib/demo-data";
import { parseMoney } from "@/lib/format";

const CATS = ["যাতায়াত", "প্যাকেজিং", "গুদাম", "ভাড়া", "মার্কেটিং", "নষ্ট", "অন্যান্য"];

export function ExpenseForm() {
  const [cat, setCat] = useState("যাতায়াত");
  const [amount, setAmount] = useState("");
  const [desc, setDesc] = useState("");
  const [file, setFile] = useState<string | null>(null);
  const amt = parseMoney(amount);
  const valid = amt !== null && amt > 0 && desc.trim().length > 0;

  return (
    <section className="drawer">
      <h2 className="h2">নতুন খরচ</h2>
      <div className="f">
        <span className="lb">ক্যাটাগরি <i>*</i></span>
        <div className="pills">{CATS.map((c) => <button key={c} type="button" className={`pill${cat === c ? " sel" : ""}`} onClick={() => setCat(c)}>{c}</button>)}</div>
      </div>
      <div className="fg2">
        <div className="f"><label htmlFor="a">টাকা <i>*</i></label><input id="a" className="in" value={amount} onChange={(e) => setAmount(e.target.value)} placeholder="৳" inputMode="decimal" /></div>
        <div className="f"><label htmlFor="d">তারিখ <i>*</i></label><input id="d" type="date" className="in" defaultValue="2026-11-22" /></div>
      </div>
      <div className="f"><label htmlFor="ds">বিবরণ <i>*</i></label><input id="ds" className="in" value={desc} onChange={(e) => setDesc(e.target.value)} placeholder="যেমন: গুদাম থেকে মিরপুরে মাল নেওয়া" /></div>
      <div className="f"><label htmlFor="s">কোনো সেলারের জন্য? <small>(ঐচ্ছিক)</small></label><select id="s" className="in"><option value="">নির্দিষ্ট নয়</option>{sellers.map((x) => <option key={x.id}>{x.name}</option>)}</select></div>
      <div className="f"><label htmlFor="p">কোনো পণ্যের জন্য? <small>(ঐচ্ছিক)</small></label><select id="p" className="in"><option value="">নির্দিষ্ট নয়</option>{products.map((x) => <option key={x.id}>{x.name}</option>)}</select></div>
      <div className="f">
        <span className="lb">রসিদের ছবি <small>(ঐচ্ছিক)</small></span>
        <label className="up">
          <Icon name="img" />
          {file ?? "ছবি যোগ করুন"}
          <input type="file" accept="image/*" style={{ display: "none" }} onChange={(e) => setFile(e.target.files?.[0]?.name ?? null)} />
        </label>
      </div>
      <ActionButton className="btn full" disabled={!valid}>খরচ সংরক্ষণ করুন</ActionButton>
    </section>
  );
}
