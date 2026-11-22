"use client";

import { useState } from "react";
import { Icon } from "@/components/ui/Icon";
import { Note } from "@/components/ui/bits";
import { ActionButton, useToast } from "@/components/ui/feedback";
import { bnDigits, money, parseMoney } from "@/lib/format";

interface Row { id: string; name: string; code: string; uninvested: number; blocked: boolean }
const METHODS = ["ব্যাংক ট্রান্সফার", "চেক", "বিকাশ"];

export function InvestmentsView({ investors, batch }: { investors: Row[]; batch: { product: string; qty: number; unitCost: number } }) {
  const toast = useToast();

  // 1. Record money received.
  const [who, setWho] = useState(investors[investors.length - 1]?.id ?? "");
  const [amount, setAmount] = useState("");
  const [method, setMethod] = useState(METHODS[0]);
  const [ref, setRef] = useState("");
  const [seen, setSeen] = useState(false);
  const [busy, setBusy] = useState(false);
  const amt = parseMoney(amount);
  const recordError =
    amt === null || amt <= 0 ? "সঠিক পরিমাণ দিন।" : !ref.trim() ? "রেফারেন্স / লেনদেন নম্বর দিন।" : !seen ? "স্টেটমেন্টে টাকা ঢুকেছে কিনা নিজে দেখে টিক দিন।" : null;

  const record = () => {
    if (recordError || busy) return;
    setBusy(true); // UI lock; the server also rejects a repeated reference.
    toast("ডেমো: সার্ভার যুক্ত হলে বিনিয়োগ রেকর্ড হবে ও রসিদ যাবে। এখন কিছু সংরক্ষণ হয়নি।");
    setTimeout(() => setBusy(false), 2500);
  };

  // 2. Split a new stock batch across investors' uninvested money.
  const total = batch.qty * batch.unitCost;
  const [parts, setParts] = useState<Record<string, string>>(() =>
    Object.fromEntries(investors.map((i) => [i.id, i.blocked ? "০" : bnDigits(i.uninvested)])),
  );
  const [company, setCompany] = useState(() =>
    bnDigits(Math.max(0, total - investors.reduce((s, i) => s + (i.blocked ? 0 : Math.min(i.uninvested, total)), 0))),
  );
  const value = (s: string | undefined) => parseMoney(s ?? "") ?? 0;
  const investorSum = investors.reduce((s, i) => s + value(parts[i.id]), 0);
  const companyPart = value(company);
  const split = investorSum + companyPart;
  const over = investors.filter((i) => value(parts[i.id]) > i.uninvested || (i.blocked && value(parts[i.id]) > 0));
  const splitError = over.length
    ? `${over.map((i) => i.name).join(", ")}: খাটেনি টাকার বেশি বা আটকানো।`
    : split !== total
      ? `মোট ${money(total)} মেলাতে হবে — এখন ${money(split)}।`
      : null;

  const fillProportional = () => {
    const pool = investors.filter((i) => !i.blocked).reduce((s, i) => s + i.uninvested, 0);
    const take = Math.min(pool, total);
    let used = 0;
    const next: Record<string, string> = {};
    const usable = investors.filter((i) => !i.blocked);
    usable.forEach((i, k) => {
      const share = k === usable.length - 1 ? take - used : Math.floor((i.uninvested / pool) * take);
      used += share;
      next[i.id] = bnDigits(share);
    });
    investors.filter((i) => i.blocked).forEach((i) => (next[i.id] = "০"));
    setParts(next);
    setCompany(bnDigits(total - take));
  };

  return (
    <div className="two">
      <div className="b">
        <section className="drawer">
          <h2 className="h2">১. নতুন বিনিয়োগ রেকর্ড</h2>
          <div className="f">
            <label htmlFor="iv">বিনিয়োগকারী <i>*</i></label>
            <select id="iv" className="in" value={who} onChange={(e) => setWho(e.target.value)}>
              {investors.map((i) => <option key={i.id} value={i.id}>{i.name} ({i.code})</option>)}
            </select>
          </div>
          <div className="f">
            <label htmlFor="am">পরিমাণ <i>*</i></label>
            <input id="am" className="in" inputMode="decimal" placeholder="যেমন: ১,০০,০০০" value={amount} onChange={(e) => setAmount(e.target.value)} />
            <span className="hint">শুধু চুক্তি সই হওয়া কিস্তির টাকা নিন</span>
          </div>
          <div className="f">
            <span className="lb">কীভাবে এসেছে <i>*</i></span>
            <div className="pills" role="group" aria-label="মাধ্যম">
              {METHODS.map((m) => <button key={m} type="button" className={`pill${method === m ? " sel" : ""}`} aria-pressed={method === m} onClick={() => setMethod(m)}>{m}</button>)}
            </div>
          </div>
          <div className="f"><label htmlFor="rf">রেফারেন্স / লেনদেন নম্বর <i>*</i></label><input id="rf" className="in" placeholder="যেমন: FT2611220931" value={ref} onChange={(e) => setRef(e.target.value)} /></div>
          <ActionButton className="btn g full" message="ডেমো: ফাইল আপলোড সার্ভার যুক্ত হলে চালু হবে।"><Icon name="img" size={18} />প্রমাণ (স্লিপ / স্টেটমেন্ট) যোগ করুন</ActionButton>
          <label className="ck"><input type="checkbox" checked={seen} onChange={() => setSeen(!seen)} /> কোম্পানির ব্যাংক স্টেটমেন্টে টাকা ঢুকেছে, নিজে দেখেছি</label>
          {recordError && amount ? <span className="err">{recordError}</span> : null}
          <button type="button" className="btn full" disabled={!!recordError || busy} onClick={record}>
            {busy ? "পাঠানো হচ্ছে…" : `${money(amt ?? 0)} রেকর্ড করুন ও রসিদ পাঠান`}
          </button>
          <div className="mu">একবার চাপলেই বাটন বন্ধ হয়; একই রেফারেন্স সার্ভার দুবার নেবে না। রসিদ বিনিয়োগকারীর অ্যাপে যাবে।</div>
        </section>
      </div>

      <div className="a">
        <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          <div className="sh"><h2 className="h2">২. স্টক কেনায় পুঁজি লাগানো</h2><span className="ch inf">খসড়া</span></div>
          <div className="mu">নতুন ব্যাচ তোলার সময় বলে দিন কার টাকায় কেনা হলো — এই হিসাব থেকেই বিনিয়োগকারী নিজের প্রোডাক্ট, সেলার আর লাভ দেখেন।</div>
          <div className="fg">
            <div className="f"><label htmlFor="pr">প্রোডাক্ট ও ব্যাচ</label><input id="pr" className="in" value={batch.product} readOnly /></div>
            <div className="f"><label htmlFor="q">পরিমাণ × কেনা দাম</label><input id="q" className="in" value={`${bnDigits(batch.qty)} পিস × ${money(batch.unitCost)}`} readOnly /></div>
            <div className="f"><label htmlFor="tt">মোট খরচ</label><input id="tt" className="in" value={money(total)} readOnly /></div>
          </div>
          <div className="sh">
            <span className="t1">কার টাকা থেকে</span>
            <button type="button" className="btn g sm" onClick={fillProportional}>খাটেনি অনুপাতে ভাগ করুন</button>
          </div>
          <div className="tw">
            <table style={{ minWidth: 560 }}>
              <thead><tr><th>বিনিয়োগকারী</th><th className="n">খাটেনি (এখন)</th><th className="n">এই ব্যাচে</th><th className="n">পরে বাকি</th></tr></thead>
              <tbody>
                {investors.map((i) => {
                  const v = value(parts[i.id]);
                  return (
                    <tr key={i.id}>
                      <td><b>{i.name}</b> {i.blocked ? <span className="ch wa">ফেরত চেয়েছেন · আটকানো</span> : null}</td>
                      <td className="n">{money(i.uninvested)}</td>
                      <td className="n">
                        <input
                          className={`in${v > i.uninvested || (i.blocked && v > 0) ? " e" : ""}`}
                          aria-label={`${i.name}-এর অংশ`}
                          inputMode="decimal"
                          disabled={i.blocked}
                          value={parts[i.id] ?? ""}
                          onChange={(e) => setParts({ ...parts, [i.id]: e.target.value })}
                          style={{ width: 130, height: 36, textAlign: "right" }}
                        />
                      </td>
                      <td className="n">{money(Math.max(0, i.uninvested - v))}</td>
                    </tr>
                  );
                })}
                <tr>
                  <td><b>কোম্পানির নিজের টাকা</b></td>
                  <td className="n">—</td>
                  <td className="n"><input className="in" aria-label="কোম্পানির অংশ" inputMode="decimal" value={company} onChange={(e) => setCompany(e.target.value)} style={{ width: 130, height: 36, textAlign: "right" }} /></td>
                  <td className="n">—</td>
                </tr>
              </tbody>
            </table>
          </div>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", background: splitError ? "#FFF7E8" : "#F4FAF6", borderRadius: 12, padding: "10px 14px" }}>
            <span className="t1">মোট ভাগ হলো</span>
            <b style={{ color: splitError ? "#85560C" : "#0F6A38" }}>{money(split)} / {money(total)}{splitError ? "" : " ✓"}</b>
          </div>
          {splitError ? <span className="err">{splitError}</span> : null}
          {investors.some((i) => i.blocked) ? <Note kind="warn" icon="alert">ফেরত চাওয়া বিনিয়োগকারীর টাকা নতুন স্টকে লাগানো আটকে রাখা হয়েছে।</Note> : null}
          <div className="actions">
            <ActionButton disabled={!!splitError} confirm={{ title: "ভাগ সংরক্ষণ করবেন?", message: "সংরক্ষণের পর বদলানো যাবে না — ভুল হলে সংশোধনী এন্ট্রি দিতে হবে।", label: "সংরক্ষণ করুন" }}>
              ব্যাচ স্টকে তুলুন ও ভাগ সংরক্ষণ করুন
            </ActionButton>
          </div>
          <div className="mu">ভাগ সংরক্ষণের পর বদলানো যায় না; ভুল হলে সংশোধনী এন্ট্রি (মূলটা মুছবে না)।</div>
        </section>
      </div>
    </div>
  );
}
