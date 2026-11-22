"use client";

import { useMemo, useState } from "react";
import { Icon } from "@/components/ui/Icon";
import { Avatar, Chip, Note } from "@/components/ui/bits";
import { ConfirmDialog, useToast } from "@/components/ui/feedback";
import { bnDigits } from "@/lib/format";

interface Person { id: string; name: string; active: boolean }
type Audience = "all_sellers" | "all_investors" | "everyone" | "sellers" | "investors";

const AUDIENCES: { id: Audience; label: string }[] = [
  { id: "all_sellers", label: "সব সক্রিয় সেলার" },
  { id: "all_investors", label: "সব সক্রিয় বিনিয়োগকারী" },
  { id: "everyone", label: "সবাই" },
  { id: "sellers", label: "নির্দিষ্ট সেলার" },
  { id: "investors", label: "নির্দিষ্ট বিনিয়োগকারী" },
];

const TEMPLATES = [
  { title: "কাল বিক্রি বন্ধ", body: "আগামীকাল ছুটির কারণে বিক্রি বন্ধ থাকবে। আজকের দিনের হিসাব সময়মতো জমা দিন।" },
  { title: "মাসিক রিপোর্ট প্রস্তুত", body: "এই মাসের লাভের হিসাব অ্যাপে দেখা যাচ্ছে। কোনো প্রশ্ন থাকলে হেল্পলাইনে যোগাযোগ করুন।" },
  { title: "নতুন স্টক এসেছে", body: "নতুন ব্যাচের প্রোডাক্ট গুদামে এসেছে। অ্যাপে আপনার বরাদ্দ দেখে নিন।" },
];

const HISTORY = [
  { title: "অক্টোবরের রিপোর্ট প্রস্তুত", audience: "সব সক্রিয় বিনিয়োগকারী", count: 4, at: "১ নভেম্বর, সকাল ১০:০৫" },
  { title: "হাতিরঝিলে আজ মেলা", audience: "সব সক্রিয় সেলার", count: 4, at: "২৮ অক্টোবর, সকাল ৮:৩০" },
];

export function MessagesView({ sellers, investors }: { sellers: Person[]; investors: Person[] }) {
  const toast = useToast();
  const [audience, setAudience] = useState<Audience>("all_sellers");
  const [picked, setPicked] = useState<string[]>([]);
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [confirm, setConfirm] = useState(false);
  const [sending, setSending] = useState(false);

  const pool = useMemo(() => (audience === "sellers" ? sellers : audience === "investors" ? investors : []), [audience, sellers, investors]);
  const recipients = useMemo(() => {
    if (audience === "sellers" || audience === "investors") return pool.filter((p) => picked.includes(p.id));
    const s = audience === "all_sellers" || audience === "everyone" ? sellers.filter((p) => p.active) : [];
    const i = audience === "all_investors" || audience === "everyone" ? investors.filter((p) => p.active) : [];
    return [...s, ...i];
  }, [audience, picked, pool, sellers, investors]);

  const error = !recipients.length ? "কাকে পাঠাবেন বাছুন।" : title.trim().length < 2 ? "শিরোনাম লিখুন।" : body.trim().length < 2 ? "বার্তা লিখুন।" : null;
  const toggle = (id: string) => setPicked(picked.includes(id) ? picked.filter((x) => x !== id) : [...picked, id]);

  const send = () => {
    setSending(true); // UI lock; the server also ignores a repeated request id.
    toast("ডেমো: সার্ভার যুক্ত হলে বার্তাটি প্রত্যেকের অ্যাপে নোটিফিকেশন হিসেবে যাবে। এখন কিছু পাঠানো হয়নি।");
    setTimeout(() => setSending(false), 2500);
  };

  return (
    <div className="two">
      <div className="a">
        <section className="drawer">
          <h2 className="h2">নতুন বার্তা</h2>
          <div className="f">
            <span className="lb">কাকে পাঠাবেন <i>*</i></span>
            <div className="pills" role="group" aria-label="প্রাপক">
              {AUDIENCES.map((a) => (
                <button key={a.id} type="button" className={`pill${audience === a.id ? " sel" : ""}`} aria-pressed={audience === a.id} onClick={() => { setAudience(a.id); setPicked([]); }}>
                  {a.label}
                </button>
              ))}
            </div>
          </div>
          {pool.length ? (
            <div className="f">
              <span className="lb">বাছুন <small>({bnDigits(picked.length)} জন বাছা হয়েছে)</small></span>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(200px, 1fr))", gap: 4 }}>
                {pool.map((p) => (
                  <label key={p.id} className="ck">
                    <input type="checkbox" checked={picked.includes(p.id)} onChange={() => toggle(p.id)} />
                    {p.name} {!p.active ? <Chip>নিষ্ক্রিয়</Chip> : null}
                  </label>
                ))}
              </div>
            </div>
          ) : null}
          <div className="f">
            <span className="lb">তৈরি বার্তা</span>
            <div className="pills">
              {TEMPLATES.map((t) => <button key={t.title} type="button" className="pill" onClick={() => { setTitle(t.title); setBody(t.body); }}>{t.title}</button>)}
            </div>
          </div>
          <div className="f"><label htmlFor="mt">শিরোনাম <i>*</i></label><input id="mt" className="in" maxLength={80} value={title} onChange={(e) => setTitle(e.target.value)} placeholder="যেমন: কাল বিক্রি বন্ধ" /></div>
          <div className="f">
            <label htmlFor="mb">বার্তা <i>*</i></label>
            <textarea id="mb" className="in" maxLength={1000} value={body} onChange={(e) => setBody(e.target.value)} style={{ height: 110 }} placeholder="সংক্ষেপে পরিষ্কার করে লিখুন" />
            <span className="hint">{bnDigits(body.length)}/১০০০ অক্ষর</span>
          </div>
          {error && (title || body || picked.length) ? <span className="err">{error}</span> : null}
          <button type="button" className="btn full" disabled={!!error || sending} onClick={() => setConfirm(true)}>
            <Icon name="bell" size={18} />{sending ? "পাঠানো হচ্ছে…" : `${bnDigits(recipients.length)} জনকে পাঠান`}
          </button>
          <Note>বার্তা প্রত্যেকের অ্যাপে নোটিফিকেশন হিসেবে যাবে। কে কখন কী পাঠিয়েছেন তা অডিট লগে থাকে। ফোন নম্বর বা NID কখনো বার্তায় লিখবেন না।</Note>
        </section>
      </div>
      <div className="b">
        <section className="cd">
          <h2 className="h2" style={{ marginBottom: 6 }}>অ্যাপে যেমন দেখাবে</h2>
          <div className="li" style={{ alignItems: "flex-start" }}>
            <span className="ic" style={{ background: "#E3F3EA", color: "#0F6A38" }}><Icon name="bell" size={18} /></span>
            <span className="fx"><span className="t1">{title || "শিরোনাম"}</span><div className="mu">{body || "বার্তা এখানে দেখাবে"}</div></span>
          </div>
          <div className="mu" style={{ marginTop: 8 }}>প্রাপক: {recipients.slice(0, 5).map((r) => r.name).join(", ")}{recipients.length > 5 ? ` এবং আরও ${bnDigits(recipients.length - 5)} জন` : ""}</div>
        </section>
        <section className="cd">
          <h2 className="h2" style={{ marginBottom: 4 }}>আগে পাঠানো</h2>
          {HISTORY.map((h) => (
            <div key={h.title} className="li">
              <Avatar name={h.title} />
              <span className="fx"><span className="t1">{h.title}</span><div className="mu">{h.audience} · {bnDigits(h.count)} জন · {h.at}</div></span>
            </div>
          ))}
        </section>
      </div>
      <ConfirmDialog
        open={confirm}
        title="বার্তা পাঠাবেন?"
        message={`“${title}” ${bnDigits(recipients.length)} জনের অ্যাপে যাবে। পাঠানোর পর ফেরত নেওয়া যাবে না।`}
        confirmLabel="পাঠান"
        onConfirm={send}
        onClose={() => setConfirm(false)}
      />
    </div>
  );
}
