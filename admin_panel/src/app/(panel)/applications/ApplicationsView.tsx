"use client";

import Link from "next/link";
import { useState, useTransition } from "react";
import { Icon } from "@/components/ui/Icon";
import { Avatar, Chip, EmptyState, KV, Note } from "@/components/ui/bits";
import { ConfirmDialog, useToast } from "@/components/ui/feedback";
import type { ActionResult } from "@/lib/api/server";
import { addressText, type ApiApplication, type ApiApplicationStatus, type ApiApplicationSummary } from "@/lib/api/types";
import { bnDate, bnDateTime, bnDigits } from "@/lib/format";
import { approveApplication, rejectApplication, requestInfo, revealNid, startReview } from "./actions";

const TABS: { id: ApiApplicationStatus; label: string; tone: "wa" | "inf" | "nu" | "ok" | "er" }[] = [
  { id: "submitted", label: "অপেক্ষমাণ", tone: "wa" },
  { id: "under_review", label: "যাচাই চলছে", tone: "inf" },
  { id: "more_info", label: "আরও তথ্য প্রয়োজন", tone: "nu" },
  { id: "approved", label: "অনুমোদিত", tone: "ok" },
  { id: "rejected", label: "বাতিল", tone: "er" },
];
const TONE = Object.fromEntries(TABS.map((t) => [t.id, t.tone])) as Record<ApiApplicationStatus, (typeof TABS)[number]["tone"]>;

const INFO_FIELDS: { id: string; label: string }[] = [
  { id: "nid_front", label: "পরিচয়পত্রের সামনের ছবি" },
  { id: "nid_back", label: "পরিচয়পত্রের পেছনের ছবি" },
  { id: "photo", label: "সেলারের ছবি" },
  { id: "present_address", label: "বর্তমান ঠিকানা" },
  { id: "permanent_address", label: "স্থায়ী ঠিকানা" },
  { id: "emergency", label: "জরুরি যোগাযোগ" },
];
const CHECKS = ["পরিচয়পত্রের নাম আবেদনের নামের সাথে মিলেছে", "জন্মতারিখ মিলেছে", "পরিচয়পত্রের সব লেখা পরিষ্কার পড়া যায়", "সেলারের ছবি পরিচয়পত্রের ছবির সাথে মিলেছে"];

function age(dob: string) {
  const b = new Date(dob);
  const t = new Date();
  return t.getFullYear() - b.getFullYear() - (t < new Date(t.getFullYear(), b.getMonth(), b.getDate()) ? 1 : 0);
}

export function ApplicationsView({ all, tab, selected }: { all: ApiApplicationSummary[]; tab: ApiApplicationStatus; selected: ApiApplication | null }) {
  const toast = useToast();
  const [pending, start] = useTransition();
  const [q, setQ] = useState("");
  const [checks, setChecks] = useState([false, false, false, false]);
  const [fields, setFields] = useState<string[]>([]);
  const [message, setMessage] = useState("");
  const [confirm, setConfirm] = useState<null | "approve" | "reject" | "reveal">(null);
  const [nid, setNid] = useState<string | null>(null);

  const list = all.filter((a) => a.status === tab && (!q.trim() || a.full_name.includes(q.trim()) || a.mobile.includes(q.trim())));
  const s = selected;
  const open = s && (s.status === "submitted" || s.status === "under_review");
  const docsOk = s ? Object.values(s.documents).every((d) => d.uploaded) : false;

  const run = (fn: () => Promise<ActionResult>) =>
    start(async () => {
      const r = await fn();
      toast(r.ok ? (r.message ?? "সম্পন্ন হয়েছে।") : r.message, !r.ok);
    });

  return (
    <>
      <div className="tabs" role="tablist" aria-label="আবেদনের অবস্থা">
        {TABS.map((t) => {
          const count = all.filter((a) => a.status === t.id).length;
          return (
            <Link key={t.id} role="tab" aria-selected={tab === t.id} className={`tab${tab === t.id ? " on" : ""}`} href={`/applications?status=${t.id}`}>
              {t.label}
              {count ? <span className={`ch ${t.tone}`}>{bnDigits(count)}</span> : null}
            </Link>
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
              <Link key={a.id} className={`card-btn${s?.id === a.id ? " on" : ""}`} href={`/applications?status=${tab}&id=${a.id}`} style={{ flexDirection: "row", alignItems: "center", gap: 12, textDecoration: "none", color: "inherit" }}>
                <Avatar name={a.full_name} />
                <span className="fx">
                  <span className="t1">{a.full_name}</span>
                  <div className="mu">{bnDigits(a.mobile)} · {bnDateTime(a.submitted_at)}</div>
                </span>
                <Chip tone={TONE[a.status]}>{a.status_label}</Chip>
              </Link>
            ))
          )}
        </div>

        {s ? (
          <div className="a">
            <section className="cd" style={{ display: "flex", gap: 14, alignItems: "center", flexWrap: "wrap" }}>
              {s.documents.photo.uploaded ? (
                // eslint-disable-next-line @next/next/no-img-element -- private, auth-proxied image
                <img src={`/api/files/applications/${s.id}/photo`} alt={`${s.full_name}-এর ছবি`} style={{ width: 64, height: 64, borderRadius: "50%", objectFit: "cover" }} />
              ) : (
                <Avatar name={s.full_name} size={64} />
              )}
              <div className="fx">
                <div style={{ fontSize: 19, fontWeight: 700 }}>{s.full_name}</div>
                <div className="mu">জমা: {bnDateTime(s.submitted_at)}</div>
              </div>
              <Chip tone={TONE[s.status]}>{s.status_label}</Chip>
              {s.status === "submitted" ? (
                <button type="button" className="btn o sm" disabled={pending} onClick={() => run(() => startReview(s.id))}>যাচাই শুরু করুন</button>
              ) : null}
            </section>

            {s.status === "more_info" ? <Note kind="warn" icon="clock">সেলারের কাছে চাওয়া হয়েছে: {s.requested_fields.map((f) => INFO_FIELDS.find((x) => x.id === f)?.label ?? f).join(", ")} — “{s.admin_message}”</Note> : null}
            {s.status === "rejected" && s.rejection_reason ? <Note kind="danger" icon="x">বাতিলের কারণ: {s.rejection_reason}</Note> : null}

            <section className="cd">
              <h2 className="h2" style={{ marginBottom: 6 }}>ব্যক্তিগত তথ্য</h2>
              <div className="kvg">
                <KV label="মোবাইল">{bnDigits(s.mobile)}</KV>
                <KV label="জন্মতারিখ">{bnDate(s.date_of_birth, true)} ({bnDigits(age(s.date_of_birth))} বছর)</KV>
                <KV label="লিঙ্গ">{s.gender ?? "দেওয়া হয়নি"}</KV>
                <KV label="ইমেইল">{s.email ?? "দেওয়া হয়নি"}</KV>
                <KV label="পিতা/মাতার নাম">{s.guardian_name ?? "দেওয়া হয়নি"}</KV>
                <KV label="বর্তমান ঠিকানা">{addressText(s.present_address)}</KV>
                <KV label="স্থায়ী ঠিকানা">{addressText(s.permanent_address)}</KV>
              </div>
            </section>

            <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 12 }}>
              <div className="sh">
                <h2 className="h2">পরিচয় যাচাই</h2>
                <span className="mu" style={{ display: "flex", gap: 6, alignItems: "center" }}><Icon name="lock" size={16} />খোলা হলে অডিট লগে লেখা হয়</span>
              </div>
              <div className="kv" style={{ border: 0 }}>
                <span>জাতীয় পরিচয়পত্র নম্বর</span>
                <span style={{ display: "flex", gap: 10, alignItems: "center" }}>
                  {nid ? bnDigits(nid) : s.nid_masked.replace(/\d/g, (d) => bnDigits(d))}
                  {!nid ? <button type="button" className="btn o sm" style={{ height: 32 }} onClick={() => setConfirm("reveal")}>পুরো নম্বর দেখুন</button> : null}
                </span>
              </div>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(170px, 1fr))", gap: 12 }}>
                <DocCard appId={s.id} kind="nid_front" label="সামনের অংশ" ok={s.documents.nid_front.uploaded} />
                <DocCard appId={s.id} kind="nid_back" label="পেছনের অংশ" ok={s.documents.nid_back.uploaded} />
                <DocCard appId={s.id} kind="photo" label="প্রোফাইল ছবি" ok={s.documents.photo.uploaded} />
              </div>
              {open ? (
                <div style={{ borderTop: "1px solid #EEF2EF", paddingTop: 8 }}>
                  <div className="mu">যাচাইয়ের তালিকা (আপনি নিজে মিলিয়ে দেখবেন)</div>
                  {CHECKS.map((t, i) => (
                    <label key={t} className="ck">
                      <input type="checkbox" checked={checks[i]} onChange={() => setChecks(checks.map((c, j) => (j === i ? !c : c)))} /> {t}
                    </label>
                  ))}
                </div>
              ) : null}
            </section>

            <div style={{ display: "flex", flexWrap: "wrap", gap: 16 }}>
              <section className="cd" style={{ flex: "1 1 260px" }}>
                <h2 className="h2" style={{ marginBottom: 6 }}>জরুরি যোগাযোগ</h2>
                <KV label="নাম">{s.emergency.name}</KV>
                <KV label="সম্পর্ক">{s.emergency.relation}</KV>
                <KV label="মোবাইল">{bnDigits(s.emergency.mobile)}</KV>
              </section>
              <section className="cd" style={{ flex: "1 1 260px" }}>
                <h2 className="h2" style={{ marginBottom: 6 }}>টাইমলাইন</h2>
                {s.timeline.map((t, i) => (
                  <div key={i} className="tl"><i style={{ background: "#168447" }} /><div><div className="t1">{t.title}</div><div className="mu">{bnDateTime(t.at)} · {t.by}</div></div></div>
                ))}
              </section>
            </div>

            {open ? (
              <>
                <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 10, borderColor: "#F0D9AE", background: "#FFFCF5" }}>
                  <h2 className="h2">আরও তথ্য চাওয়া বা বাতিলের কারণ</h2>
                  <div className="mu">কোন তথ্য ঠিক নেই বাছুন — সেলার শুধু এগুলোই আবার দেবেন।</div>
                  <div style={{ display: "flex", flexWrap: "wrap", gap: "4px 18px" }}>
                    {INFO_FIELDS.map((f) => (
                      <label key={f.id} className="ck">
                        <input type="checkbox" checked={fields.includes(f.id)} onChange={() => setFields(fields.includes(f.id) ? fields.filter((x) => x !== f.id) : [...fields, f.id])} /> {f.label}
                      </label>
                    ))}
                  </div>
                  <textarea className="in" aria-label="সেলারের জন্য বার্তা বা বাতিলের কারণ" placeholder="যেমন: পেছনের ছবিটি ঝাপসা। আলোতে পরিষ্কার করে আবার তুলুন।" value={message} onChange={(e) => setMessage(e.target.value)} />
                </section>

                <div className="actions">
                  <button type="button" className="btn" disabled={pending || !checks.every(Boolean) || !docsOk} onClick={() => setConfirm("approve")}>অনুমোদন দিন</button>
                  <button
                    type="button"
                    className="btn o"
                    disabled={pending}
                    onClick={() => {
                      if (!fields.length) return toast("কোন তথ্য দরকার, অন্তত একটি বাছুন।", true);
                      if (message.trim().length < 3) return toast("সেলারের জন্য ছোট একটা বার্তা লিখুন।", true);
                      run(() => requestInfo(s.id, fields, message.trim()));
                    }}
                  >
                    আরও তথ্য চাই
                  </button>
                  <button type="button" className="btn r" disabled={pending} onClick={() => (message.trim().length < 3 ? toast("বাতিলের কারণ লিখতে হবে।", true) : setConfirm("reject"))}>বাতিল করুন</button>
                </div>
                {!docsOk ? <Note kind="warn">সব ছবি জমা না হলে অনুমোদন দেওয়া যাবে না।</Note> : !checks.every(Boolean) ? <Note>অনুমোদনের আগে যাচাইয়ের তালিকার সবগুলো মিলিয়ে টিক দিন।</Note> : null}
              </>
            ) : null}

            <ConfirmDialog
              open={confirm === "approve"}
              title="সেলারকে অনুমোদন দেবেন?"
              message={`${s.full_name}-এর সেলার অ্যাকাউন্ট চালু হবে। এই সিদ্ধান্ত অডিট লগে থাকবে।`}
              confirmLabel="অনুমোদন দিন"
              onConfirm={() => run(() => approveApplication(s.id))}
              onClose={() => setConfirm(null)}
            />
            <ConfirmDialog
              open={confirm === "reject"}
              title="আবেদন বাতিল করবেন?"
              message={`কারণ: “${message.trim()}”। সেলারের অ্যাকাউন্ট বন্ধ হবে।`}
              confirmLabel="বাতিল করুন"
              danger
              onConfirm={() => run(() => rejectApplication(s.id, message.trim()))}
              onClose={() => setConfirm(null)}
            />
            <ConfirmDialog
              open={confirm === "reveal"}
              title="পুরো পরিচয়পত্র নম্বর দেখবেন?"
              message="এটা অডিট লগে আপনার নামে লেখা থাকবে। শুধু যাচাইয়ের প্রয়োজনে দেখুন।"
              confirmLabel="দেখুন"
              onConfirm={() =>
                start(async () => {
                  const r = await revealNid(s.id);
                  if (r.ok) setNid(r.data.nid_number);
                  else toast(r.message, true);
                })
              }
              onClose={() => setConfirm(null)}
            />
          </div>
        ) : null}
      </div>
    </>
  );
}

function DocCard({ appId, kind, label, ok }: { appId: string; kind: string; label: string; ok: boolean }) {
  const src = `/api/files/applications/${appId}/${kind}`;
  return (
    <div className="doc">
      {ok ? (
        <a className="pv" href={src} target="_blank" rel="noopener noreferrer" aria-label={`${label} বড় করে দেখুন`} style={{ padding: 0, overflow: "hidden" }}>
          {/* eslint-disable-next-line @next/next/no-img-element -- private, auth-proxied image */}
          <img src={src} alt={label} loading="lazy" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
        </a>
      ) : (
        <div className="pv" style={{ background: "#FBF7F0", color: "#85560C", flexDirection: "column", gap: 6 }}>
          <Icon name="img" />
          জমা হয়নি
        </div>
      )}
      <div className="cap">
        {label} {ok ? <span className="ch ok">আছে</span> : <span className="ch wa">নেই</span>}
      </div>
    </div>
  );
}
