"use client";

import { useMemo, useState } from "react";
import { Icon } from "@/components/ui/Icon";
import { Avatar, EmptyState, KV, Note, StatusChip } from "@/components/ui/bits";
import { ActionButton, useToast } from "@/components/ui/feedback";
import { bnDigits } from "@/lib/format";
import { applicationStatus } from "@/lib/labels";
import type { Application, ApplicationStatus } from "@/lib/types";

const TABS: { id: ApplicationStatus; label: string }[] = [
  { id: "pending", label: "অপেক্ষমাণ" },
  { id: "review", label: "যাচাই চলছে" },
  { id: "moreInfo", label: "আরও তথ্য প্রয়োজন" },
  { id: "approved", label: "অনুমোদিত" },
  { id: "rejected", label: "বাতিল" },
];

export function ApplicationsView({ items }: { items: Application[] }) {
  const toast = useToast();
  const [tab, setTab] = useState<ApplicationStatus>("pending");
  const [q, setQ] = useState("");
  const list = useMemo(
    () => items.filter((a) => a.status === tab && (a.name.includes(q.trim()) || a.mobile.includes(q.trim()))),
    [items, tab, q],
  );
  const [selectedId, setSelectedId] = useState(list[0]?.id);
  const sel = list.find((a) => a.id === selectedId) ?? list[0];
  const [checks, setChecks] = useState([true, true, false, false]);
  const [infoFields, setInfoFields] = useState<string[]>(["পরিচয়পত্রের পেছনের ছবি"]);
  const [rejectReason, setRejectReason] = useState("");

  return (
    <>
      <div className="tabs" role="tablist" aria-label="আবেদনের অবস্থা">
        {TABS.map((t) => {
          const count = items.filter((a) => a.status === t.id).length;
          return (
            <button key={t.id} type="button" role="tab" aria-selected={tab === t.id} className={`tab${tab === t.id ? " on" : ""}`} onClick={() => setTab(t.id)}>
              {t.label}
              {count ? <span className={`ch ${applicationStatus[t.id][1]}`}>{bnDigits(count)}</span> : null}
            </button>
          );
        })}
      </div>

      <div className="two">
        <div className="b">
          <div className="srch" style={{ maxWidth: "none" }}>
            <input className="in" type="search" placeholder="নাম বা মোবাইল নম্বর খুঁজুন" aria-label="আবেদন খুঁজুন" value={q} onChange={(e) => setQ(e.target.value)} />
            <span><Icon name="search" size={18} /></span>
          </div>
          {list.length === 0 ? (
            <div className="cd"><EmptyState icon="doc" title="এই তালিকায় কোনো আবেদন নেই" /></div>
          ) : (
            list.map((a) => (
              <button key={a.id} type="button" className={`card-btn${sel?.id === a.id ? " on" : ""}`} onClick={() => setSelectedId(a.id)} style={{ flexDirection: "row", alignItems: "center", gap: 12 }}>
                <Avatar name={a.name} />
                <span className="fx">
                  <span className="t1">{a.name}</span>
                  <div className="mu">{a.mobile} · {a.submitted}</div>
                </span>
                <StatusChip value={applicationStatus[a.status]} />
              </button>
            ))
          )}
        </div>

        {sel ? (
          <div className="a">
            <section className="cd" style={{ display: "flex", gap: 14, alignItems: "center", flexWrap: "wrap" }}>
              <Avatar name={sel.name} size={64} />
              <div className="fx">
                <div style={{ fontSize: 19, fontWeight: 700 }}>{sel.name}</div>
                <div className="mu">আবেদন #{sel.id} · জমা: {sel.submitted}</div>
              </div>
              <StatusChip value={applicationStatus[sel.status]} />
              {sel.status === "pending" ? (
                <ActionButton className="btn o sm" message="যাচাই শুরু হিসেবে চিহ্নিত হবে — সার্ভার চালু হলে সংরক্ষণ হবে।">যাচাই শুরু করুন</ActionButton>
              ) : null}
            </section>

            <section className="cd">
              <h2 className="h2" style={{ marginBottom: 6 }}>ব্যক্তিগত তথ্য</h2>
              <div className="kvg">
                <KV label="মোবাইল">{sel.mobile}</KV>
                <KV label="জন্মতারিখ">{sel.dob}</KV>
                <KV label="লিঙ্গ">{sel.gender ?? "দেওয়া হয়নি"}</KV>
                <KV label="ইমেইল">{sel.email ?? "দেওয়া হয়নি"}</KV>
                <KV label="পিতা/মাতার নাম">{sel.guardian ?? "দেওয়া হয়নি"}</KV>
                <KV label="বর্তমান ঠিকানা">{sel.presentAddress}</KV>
                <KV label="স্থায়ী ঠিকানা">{sel.permanentAddress}</KV>
              </div>
            </section>

            <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 12 }}>
              <div className="sh">
                <h2 className="h2">পরিচয় যাচাই</h2>
                <span className="mu" style={{ display: "flex", gap: 6, alignItems: "center" }}><Icon name="lock" size={16} />শুধু অনুমোদিত অ্যাডমিন দেখতে পারেন · খোলা রেকর্ড হয়</span>
              </div>
              <div className="kv" style={{ border: 0 }}>
                <span>জাতীয় পরিচয়পত্র নম্বর</span>
                <span style={{ display: "flex", gap: 10, alignItems: "center" }}>
                  •••• •••• {sel.nidLast4}
                  <ActionButton className="btn o sm" message="পুরো নম্বর দেখা অডিট লগে রেকর্ড হবে — সার্ভার চালু হলে নিরাপদ লিংক থেকে দেখানো হবে।">পুরো নম্বর দেখুন</ActionButton>
                </span>
              </div>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(170px, 1fr))", gap: 12 }}>
                <DocCard label="সামনের অংশ" ok />
                <DocCard label="পেছনের অংশ" ok={!sel.backImageFailed} />
                <DocCard label="প্রোফাইল ছবি" ok />
              </div>
              <div style={{ borderTop: "1px solid #EEF2EF", paddingTop: 8 }}>
                <div className="mu">যাচাইয়ের তালিকা (আপনি নিজে মিলিয়ে দেখবেন)</div>
                {["পরিচয়পত্রের নাম আবেদনের নামের সাথে মিলেছে", "জন্মতারিখ মিলেছে", "পরিচয়পত্রের সব লেখা পরিষ্কার পড়া যায়", "সেলারের ছবি পরিচয়পত্রের ছবির সাথে মিলেছে"].map((t, i) => (
                  <label key={t} className="ck">
                    <input type="checkbox" checked={checks[i]} onChange={() => setChecks(checks.map((c, j) => (j === i ? !c : c)))} /> {t}
                  </label>
                ))}
              </div>
            </section>

            <div style={{ display: "flex", flexWrap: "wrap", gap: 16 }}>
              <section className="cd" style={{ flex: "1 1 260px" }}>
                <h2 className="h2" style={{ marginBottom: 6 }}>জরুরি যোগাযোগ</h2>
                <KV label="নাম">{sel.emergency.name}</KV>
                <KV label="সম্পর্ক">{sel.emergency.relation}</KV>
                <KV label="মোবাইল">{sel.emergency.mobile}</KV>
              </section>
              <section className="cd" style={{ flex: "1 1 260px" }}>
                <h2 className="h2" style={{ marginBottom: 6 }}>টাইমলাইন</h2>
                <div className="tl"><i style={{ background: "#168447" }} /><div><div className="t1">আবেদন জমা হয়েছে</div><div className="mu">{sel.submitted}</div></div></div>
                <div className="tl"><i style={{ background: "#DCE4DF" }} /><div><div className="t1" style={{ color: "#5F6C64" }}>যাচাই শুরু</div><div className="mu">এখনো হয়নি</div></div></div>
                <div className="tl"><i style={{ background: "#DCE4DF" }} /><div><div className="t1" style={{ color: "#5F6C64" }}>সিদ্ধান্ত · যাচাইকারী</div><div className="mu">—</div></div></div>
              </section>
            </div>

            <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 10, borderColor: "#F0D9AE", background: "#FFFCF5" }}>
              <h2 className="h2">আরও তথ্য চাওয়া বা বাতিলের কারণ</h2>
              <div className="mu">কোন তথ্য ঠিক নেই বাছুন — সেলার শুধু এগুলোই আবার দেবেন।</div>
              <div style={{ display: "flex", flexWrap: "wrap", gap: "4px 18px" }}>
                {["পরিচয়পত্রের পেছনের ছবি", "সেলারের ছবি", "বর্তমান ঠিকানা"].map((f) => (
                  <label key={f} className="ck">
                    <input type="checkbox" checked={infoFields.includes(f)} onChange={() => setInfoFields(infoFields.includes(f) ? infoFields.filter((x) => x !== f) : [...infoFields, f])} /> {f}
                  </label>
                ))}
              </div>
              <textarea className="in" aria-label="সেলারের জন্য বার্তা বা বাতিলের কারণ" placeholder="যেমন: পেছনের ছবিটি ঝাপসা। আলোতে পরিষ্কার করে আবার তুলুন।" value={rejectReason} onChange={(e) => setRejectReason(e.target.value)} />
            </section>

            <div className="actions">
              <ActionButton
                confirm={{ title: "সেলারকে অনুমোদন দেবেন?", message: `${sel.name} অনুমোদনের পর সেলার অ্যাকাউন্ট চালু করার যোগ্য হবেন। এই সিদ্ধান্ত অডিট লগে থাকবে।`, label: "অনুমোদন দিন" }}
                disabled={!checks.every(Boolean)}
              >
                অনুমোদন দিন
              </ActionButton>
              <button
                type="button"
                className="btn o"
                onClick={() => (infoFields.length ? toast(`ডেমো: ${bnDigits(infoFields.length)}টি তথ্য আবার চাওয়া হবে — সার্ভার চালু হলে সেলার নোটিফিকেশন পাবেন।`) : toast("কোন তথ্য দরকার, অন্তত একটি বাছুন।", true))}
              >
                আরও তথ্য চাই
              </button>
              <button
                type="button"
                className="btn r"
                onClick={() => (rejectReason.trim() ? toast("ডেমো: আবেদন বাতিল হিসেবে সংরক্ষণ হবে — সার্ভার চালু হলে।") : toast("বাতিলের কারণ লিখতে হবে।", true))}
              >
                বাতিল করুন
              </button>
            </div>
            {!checks.every(Boolean) ? <Note>অনুমোদনের আগে যাচাইয়ের তালিকার সবগুলো মিলিয়ে টিক দিন।</Note> : null}
          </div>
        ) : null}
      </div>
    </>
  );
}

function DocCard({ label, ok }: { label: string; ok: boolean }) {
  const toast = useToast();
  return (
    <div className="doc">
      {ok ? (
        <div className="pv">
          {label}
          <button type="button" className="ib" aria-label={`${label} বড় করে দেখুন`} onClick={() => toast("ডেমো: সার্ভার চালু হলে সুরক্ষিত, কিছুক্ষণের জন্য বৈধ লিংক থেকে ছবিটি খুলবে।")} style={{ position: "absolute", right: 6, bottom: 6, background: "#fff", width: 36, height: 36 }}>
            <Icon name="zoom" size={18} />
          </button>
        </div>
      ) : (
        <div className="pv" style={{ background: "#FBF7F0", color: "#85560C", flexDirection: "column", gap: 6 }}>
          <Icon name="img" />
          ছবি লোড হয়নি
        </div>
      )}
      <div className="cap">
        {label} {ok ? <span className="ch ok">আছে</span> : <span className="ch wa">সমস্যা</span>}
      </div>
    </div>
  );
}
