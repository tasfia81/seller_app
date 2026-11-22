"use client";

import { useState } from "react";
import { Icon } from "@/components/ui/Icon";
import { Avatar, EmptyState, KV, Note, StatusChip } from "@/components/ui/bits";
import { ActionButton, ConfirmDialog, useToast } from "@/components/ui/feedback";
import { bnDigits, money } from "@/lib/format";
import { investorAppStatus, type InvestorAppStatus, type InvestorApplication } from "@/lib/investors";

const TABS: InvestorAppStatus[] = ["pending", "review", "moreInfo", "approved", "rejected"];
const CHECKS = [
  "NID-এর নাম আবেদনের নামের সাথে মিলেছে",
  "সেলফি NID-এর ছবির সাথে মিলেছে",
  "ব্যাংক অ্যাকাউন্টের নাম NID-এর নামের সাথে মিলেছে",
  "টাকার উৎস যুক্তিসঙ্গত (প্রয়োজনে কাগজ চাওয়া হয়েছে)",
  "ফোনে কথা বলে ঝুঁকি বুঝিয়ে বলা হয়েছে",
];

export function InvestorApplicationsView({ items }: { items: InvestorApplication[] }) {
  const toast = useToast();
  const [tab, setTab] = useState<InvestorAppStatus>("pending");
  const list = items.filter((a) => a.status === tab);
  const [selectedId, setSelectedId] = useState<string | undefined>(list[0]?.id);
  const sel = list.find((a) => a.id === selectedId) ?? list[0];
  const [checks, setChecks] = useState<boolean[]>([true, true, false, false, false]);
  const [revealOpen, setRevealOpen] = useState(false);
  const [rejectReason, setRejectReason] = useState("");
  const allChecked = checks.every(Boolean);

  return (
    <>
      <div className="tabs" role="tablist" aria-label="আবেদনের অবস্থা">
        {TABS.map((t) => {
          const count = items.filter((a) => a.status === t).length;
          return (
            <button key={t} type="button" role="tab" aria-selected={tab === t} className={`tab${tab === t ? " on" : ""}`} onClick={() => { setTab(t); setSelectedId(undefined); }}>
              {investorAppStatus[t][0]}
              {count ? <span className={`ch ${investorAppStatus[t][1]}`}>{bnDigits(count)}</span> : null}
            </button>
          );
        })}
      </div>

      <div className="two">
        <div className="b">
          {list.length === 0 ? (
            <div className="cd"><EmptyState icon="doc" title="এই তালিকায় কোনো আবেদন নেই" /></div>
          ) : (
            list.map((a) => (
              <button key={a.id} type="button" className={`card-btn${sel?.id === a.id ? " on" : ""}`} onClick={() => setSelectedId(a.id)} style={{ flexDirection: "row", alignItems: "center", gap: 12 }}>
                <Avatar name={a.name} />
                <span className="fx" style={{ textAlign: "left" }}>
                  <span className="t1">{a.name}</span>
                  <div className="mu">{a.submitted} · {money(a.proposed)}</div>
                </span>
                <StatusChip value={investorAppStatus[a.status]} />
              </button>
            ))
          )}
        </div>

        {sel ? (
          <div className="a">
            <section className="cd" style={{ display: "flex", gap: 14, alignItems: "center", flexWrap: "wrap" }}>
              <Avatar name={sel.name} size={60} />
              <div className="fx">
                <div style={{ fontSize: 19, fontWeight: 700 }}>{sel.name}</div>
                <div className="mu">আবেদন #{sel.code} · জমা: {sel.submitted} · প্রস্তাবিত বিনিয়োগ {money(sel.proposed)}</div>
              </div>
              <StatusChip value={investorAppStatus[sel.status]} />
              {sel.status === "pending" ? <ActionButton className="btn o sm">যাচাই শুরু করুন</ActionButton> : null}
            </section>

            <section className="cd">
              <h2 className="h2" style={{ marginBottom: 6 }}>ব্যক্তিগত ও আর্থিক তথ্য</h2>
              <div className="kvg">
                <KV label="মোবাইল (OTP যাচাইকৃত)">{sel.mobileMasked}</KV>
                <KV label="জন্মতারিখ">{sel.dob}</KV>
                <KV label="পেশা">{sel.occupation}</KV>
                <KV label="টাকার উৎস">{sel.source}</KV>
                <KV label="বর্তমান ঠিকানা">{sel.address}</KV>
                <KV label="নমিনি">{sel.nominee}</KV>
              </div>
            </section>

            <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 12 }}>
              <div className="sh">
                <h2 className="h2">পরিচয় যাচাই (KYC)</h2>
                <span className="mu" style={{ display: "flex", gap: 6, alignItems: "center" }}><Icon name="lock" size={16} />খোলা হলে অডিট লগে লেখা হয়</span>
              </div>
              <div className="kv" style={{ border: 0 }}>
                <span>জাতীয় পরিচয়পত্র নম্বর</span>
                <span style={{ display: "flex", gap: 10, alignItems: "center" }}>
                  {sel.nidMasked}
                  <button type="button" className="btn o sm" style={{ height: 32 }} onClick={() => setRevealOpen(true)}>পুরো নম্বর দেখুন</button>
                </span>
              </div>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(170px, 1fr))", gap: 12 }}>
                {["NID সামনের ছবি", "NID পেছনের ছবি", "সেলফি"].map((d) => (
                  <div key={d} className="doc">
                    <div className="pv">{d}</div>
                    <div className="cap">{d.replace("NID ", "")} <span className="ch ok">আছে</span></div>
                  </div>
                ))}
              </div>
              <div style={{ borderTop: "1px solid #EEF2EF", paddingTop: 8 }}>
                <div className="mu" style={{ marginBottom: 2 }}>যাচাইয়ের তালিকা (নিজে মিলিয়ে দেখবেন)</div>
                {CHECKS.map((c, i) => (
                  <label key={c} className="ck">
                    <input type="checkbox" checked={checks[i]} onChange={() => setChecks(checks.map((v, k) => (k === i ? !v : v)))} /> {c}
                  </label>
                ))}
              </div>
            </section>

            <section className="cd">
              <h2 className="h2" style={{ marginBottom: 6 }}>লাভ পাওয়ার মাধ্যম</h2>
              <KV label="ব্যাংক">{sel.bankName}</KV>
              <KV label="অ্যাকাউন্টের নাম">{sel.accountName}</KV>
              <KV label="অ্যাকাউন্ট">{sel.accountMasked}</KV>
            </section>

            <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 10 }}>
              <h2 className="h2">অনুমোদনের সাথে চুক্তির শর্ত</h2>
              <div className="fg">
                <div className="f"><label htmlFor="sh">লাভের ভাগ (%)</label><input id="sh" className="in" defaultValue="৫০" inputMode="numeric" /><span className="hint">সেটিংসের ডিফল্ট · শুধু এই বিনিয়োগকারীর জন্য বদলানো যায়</span></div>
                <div className="f"><label htmlFor="pd">লাভ দেওয়ার দিন</label><input id="pd" className="in" defaultValue="প্রতি মাসের ৫ তারিখ" /></div>
                <div className="f"><label htmlFor="nt">মূলধন ফেরতের নোটিশ (দিন)</label><input id="nt" className="in" defaultValue="৩০" inputMode="numeric" /></div>
              </div>
              <div className="mu">অনুমোদনের পর চুক্তিপত্র বিনিয়োগকারীর অ্যাপে যাবে। উনি OTP দিয়ে সই করলে কোম্পানির পক্ষে সই করবেন মালিক।</div>
              <div className="f"><label htmlFor="rr">বাতিলের কারণ (বাতিল করলে লাগবে)</label><textarea id="rr" className="in" value={rejectReason} onChange={(e) => setRejectReason(e.target.value)} placeholder="যেমন: NID-এর ছবি অস্পষ্ট, নাম মেলেনি" /></div>
            </section>

            <div className="actions">
              <ActionButton
                disabled={!allChecked}
                confirm={{ title: "অনুমোদন দেবেন?", message: `${sel.name}-এর অ্যাকাউন্ট চালু হবে এবং চুক্তিপত্র ওনার অ্যাপে যাবে। টাকা আসবে চুক্তি সই হওয়ার পর।`, label: "অনুমোদন দিন" }}
              >
                অনুমোদন দিন ও চুক্তি পাঠান
              </ActionButton>
              <ActionButton className="btn o">আরও তথ্য চাই</ActionButton>
              <ActionButton
                className="btn r"
                disabled={rejectReason.trim().length < 5}
                confirm={{ title: "আবেদন বাতিল করবেন?", message: "কারণসহ বার্তা আবেদনকারীর অ্যাপে যাবে।", label: "বাতিল করুন", danger: true }}
              >
                বাতিল করুন (কারণসহ)
              </ActionButton>
            </div>
            {!allChecked ? <span className="err">অনুমোদনের আগে যাচাইয়ের তালিকার সবগুলো টিক দিন।</span> : null}
            <Note>অনুমোদন মানে টাকা নেওয়া নয় — টাকা আসবে চুক্তি সই হওয়ার পর, শুধু কোম্পানির অ্যাকাউন্টে। সব সিদ্ধান্ত অডিট লগে থাকবে।</Note>

            <ConfirmDialog
              open={revealOpen}
              title="পুরো NID নম্বর দেখবেন?"
              message="এটা অডিট লগে আপনার নামে লেখা থাকবে। শুধু যাচাইয়ের প্রয়োজনে দেখুন।"
              confirmLabel="দেখুন"
              onConfirm={() => toast("ডেমো: সার্ভার যুক্ত হলে এখানে পুরো নম্বর দেখাবে এবং অডিট লগে লেখা হবে।")}
              onClose={() => setRevealOpen(false)}
            />
          </div>
        ) : null}
      </div>
    </>
  );
}
