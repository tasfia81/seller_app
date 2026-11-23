"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useRef, useState, useTransition } from "react";
import { Icon } from "@/components/ui/Icon";
import { Avatar, Chip, EmptyState, KV, Note } from "@/components/ui/bits";
import { ConfirmDialog, useToast } from "@/components/ui/feedback";
import type { ApiSupportInbox, ApiSupportMessage, ApiSupportThread } from "@/lib/api/types";
import { bnDate, bnDateTime, bnDigits, bnTime } from "@/lib/format";
import { replySupport, setSupportStatus } from "./actions";

export type SupportFilter = { status: "open" | "resolved"; kind: "all" | "seller" | "investor" };
type Thread = ApiSupportThread & { messages: ApiSupportMessage[] };

const KIND_LABEL = { seller: "সেলার", investor: "বিনিয়োগকারী" } as const;
const QUICK = ["দেখছি, একটু পরে জানাচ্ছি।", "হিসাব মিলিয়ে দেখা হয়েছে, সব ঠিক আছে।", "অফিসে একবার যোগাযোগ করুন।"];

function href(f: SupportFilter, id?: string) {
  const q = new URLSearchParams({ status: f.status });
  if (f.kind !== "all") q.set("kind", f.kind);
  if (id) q.set("id", id);
  return `/support?${q}`;
}

export function SupportView({ inbox, thread, filter }: { inbox: ApiSupportInbox; thread: Thread | null; filter: SupportFilter }) {
  const router = useRouter();

  // New messages arrive without a reload: re-read every 15 s while the tab is visible.
  useEffect(() => {
    const t = setInterval(() => {
      if (document.visibilityState === "visible") router.refresh();
    }, 15_000);
    return () => clearInterval(t);
  }, [router]);

  const c = inbox.counts;
  return (
    <>
      <div className="sh">
        <div className="tabs" role="tablist" aria-label="অবস্থা">
          <Link role="tab" aria-selected={filter.status === "open"} className={`tab${filter.status === "open" ? " on" : ""}`} href={href({ ...filter, status: "open" })} style={{ textDecoration: "none" }}>
            খোলা {c.waiting ? <span className="ch wa">{bnDigits(c.waiting)} উত্তর বাকি</span> : c.open ? <span className="ch nu">{bnDigits(c.open)}</span> : null}
          </Link>
          <Link role="tab" aria-selected={filter.status === "resolved"} className={`tab${filter.status === "resolved" ? " on" : ""}`} href={href({ ...filter, status: "resolved" })} style={{ textDecoration: "none" }}>
            সমাধান হয়েছে {c.resolved ? <span className="ch nu">{bnDigits(c.resolved)}</span> : null}
          </Link>
        </div>
        <div className="pills" role="group" aria-label="কার প্রশ্ন">
          {(["all", "seller", "investor"] as const).map((k) => (
            <Link key={k} href={href({ ...filter, kind: k })} className={`pill${filter.kind === k ? " on" : ""}`} style={{ textDecoration: "none" }}>
              {k === "all" ? "সবাই" : KIND_LABEL[k]}
            </Link>
          ))}
        </div>
      </div>

      {inbox.items.length === 0 && !thread ? (
        <div className="cd">
          <EmptyState
            icon="chat"
            title={filter.status === "open" ? "কোনো খোলা প্রশ্ন নেই" : "এখনো কিছু সমাধান হয়নি"}
            text="সেলার বা বিনিয়োগকারী অ্যাপ থেকে প্রশ্ন পাঠালে এখানে আসবে, সাথে নোটিফিকেশন।"
          />
        </div>
      ) : (
        <div className="two">
          <div className="b">
            {inbox.items.length === 0 ? <div className="mu">এই তালিকায় আর কোনো কথোপকথন নেই।</div> : null}
            {inbox.items.map((t) => {
              const waiting = t.status === "open" && t.last_from === "user";
              return (
                <Link key={t.id} href={href(filter, t.id)} scroll={false} className={`card-btn${t.id === thread?.id ? " on" : ""}`} style={{ textDecoration: "none", color: "inherit" }}>
                  <div className="sh" style={{ width: "100%", gap: 8 }}>
                    <span className="sl" style={{ minWidth: 0 }}>
                      <Avatar name={t.owner_name} size={34} />
                      <span style={{ minWidth: 0 }}>
                        <b className="t1" style={{ display: "block" }}>{t.owner_name}</b>
                        <span className="mu">{KIND_LABEL[t.owner_kind]}{t.is_applicant ? " · আবেদনকারী" : ""} · {t.topic_label}</span>
                      </span>
                    </span>
                    {t.unread ? <span className="ch wa" aria-label={`${t.unread}টি নতুন বার্তা`}>{bnDigits(t.unread)}</span> : null}
                  </div>
                  <span style={{ fontSize: 13.5, color: waiting ? "var(--text)" : "#5d6b63", fontWeight: waiting ? 600 : 400, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", width: "100%" }}>
                    {t.last_from === "admin" ? "আপনি: " : ""}{t.last_message}
                  </span>
                  <span className="mu" style={{ fontSize: 12 }}>{bnDateTime(t.updated_at)}{waiting ? " · উত্তর বাকি" : ""}</span>
                </Link>
              );
            })}
          </div>
          <div className="a">{thread ? <Conversation thread={thread} /> : null}</div>
        </div>
      )}
    </>
  );
}

function Conversation({ thread }: { thread: Thread }) {
  const toast = useToast();
  const [pending, start] = useTransition();
  const [text, setText] = useState("");
  const [requestId, setRequestId] = useState(() => crypto.randomUUID());
  const [confirm, setConfirm] = useState(false);
  const bottom = useRef<HTMLDivElement>(null);
  const count = thread.messages.length;

  useEffect(() => {
    bottom.current?.scrollIntoView({ block: "end" });
  }, [count]);

  const send = () => {
    const body = text.trim();
    if (!body || pending) return;
    start(async () => {
      const r = await replySupport(thread.id, body, requestId);
      if (r.ok) {
        setText("");
        setRequestId(crypto.randomUUID());
      } else {
        toast(r.message, true);
      }
    });
  };

  const changeStatus = (action: "resolve" | "reopen") =>
    start(async () => {
      const r = await setSupportStatus(thread.id, action);
      toast(r.ok ? (r.message ?? "সম্পন্ন হয়েছে।") : r.message, !r.ok);
    });

  // Day separator before the first message of each day.
  const rows = thread.messages.map((m, i) => {
    const day = bnDate(m.at, true);
    return { m, day, showDay: i === 0 || day !== bnDate(thread.messages[i - 1].at, true) };
  });
  return (
    <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 12, padding: 0, overflow: "hidden" }}>
      <div className="sh" style={{ padding: "14px 16px", borderBottom: "1px solid var(--border)", gap: 10 }}>
        <div className="sl" style={{ minWidth: 0 }}>
          <Avatar name={thread.owner_name} size={40} />
          <div style={{ minWidth: 0 }}>
            <b style={{ fontSize: 16 }}>{thread.owner_name}</b>
            <span className="mu">{KIND_LABEL[thread.owner_kind]}{thread.is_applicant ? " (আবেদন যাচাই চলছে)" : ""} · {thread.topic_label}</span>
          </div>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 8, flexWrap: "wrap", justifyContent: "flex-end" }}>
          <Chip tone={thread.status === "open" ? "ok" : "nu"}>{thread.status_label}</Chip>
          {thread.seller_id ? <Link className="btn g sm" href={`/sellers/${thread.seller_id}`}>প্রোফাইল</Link> : null}
          {thread.status === "open" ? (
            <button type="button" className="btn o sm" disabled={pending} onClick={() => setConfirm(true)}><Icon name="check" size={16} />সমাধান হয়েছে</button>
          ) : (
            <button type="button" className="btn g sm" disabled={pending} onClick={() => changeStatus("reopen")}>আবার খুলুন</button>
          )}
        </div>
      </div>

      <div role="log" aria-label="বার্তা" aria-live="polite" style={{ display: "flex", flexDirection: "column", gap: 8, padding: "4px 16px", maxHeight: "min(56vh, 560px)", minHeight: 240, overflowY: "auto" }}>
        {rows.map(({ m, day, showDay }) => {
          const mine = m.sender === "admin";
          return (
            <div key={m.id} style={{ display: "contents" }}>
              {showDay ? <div className="mu" style={{ alignSelf: "center", fontSize: 12, padding: "6px 0" }}>{day}</div> : null}
              <div style={{ alignSelf: mine ? "flex-end" : "flex-start", maxWidth: "78%", display: "flex", flexDirection: "column", alignItems: mine ? "flex-end" : "flex-start" }}>
                <div
                  style={{
                    background: mine ? "#168447" : "#F1F5F2",
                    color: mine ? "#fff" : "var(--text)",
                    borderRadius: mine ? "16px 16px 4px 16px" : "16px 16px 16px 4px",
                    padding: "9px 13px",
                    fontSize: 14.5,
                    lineHeight: 1.55,
                    whiteSpace: "pre-wrap",
                    overflowWrap: "anywhere",
                  }}
                >
                  {m.text}
                </div>
                <span className="mu" style={{ fontSize: 11.5, margin: "3px 4px 0" }}>{mine ? `${m.author} · ` : ""}{bnTime(m.at)}</span>
              </div>
            </div>
          );
        })}
        <div ref={bottom} />
      </div>

      <div style={{ borderTop: "1px solid var(--border)", padding: "12px 16px 16px", display: "flex", flexDirection: "column", gap: 10 }}>
        <div className="pills" role="group" aria-label="দ্রুত উত্তর">
          {QUICK.map((q) => <button key={q} type="button" className="pill" onClick={() => setText(q)}>{q}</button>)}
        </div>
        <div style={{ display: "flex", gap: 8, alignItems: "flex-end" }}>
          <label htmlFor="reply" style={{ position: "absolute", left: -9999 }}>উত্তর লিখুন</label>
          <textarea
            id="reply"
            className="in"
            rows={2}
            maxLength={2000}
            value={text}
            placeholder={thread.status === "resolved" ? "এটি সমাধান হিসেবে বন্ধ আছে — উত্তর দিলেও বন্ধই থাকবে" : "উত্তর লিখুন… (Ctrl+Enter পাঠায়)"}
            onChange={(e) => setText(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter" && (e.ctrlKey || e.metaKey)) send();
            }}
            style={{ flex: 1, resize: "vertical", minHeight: 48 }}
          />
          <button type="button" className="btn" disabled={pending || !text.trim()} onClick={send} aria-label="উত্তর পাঠান"><Icon name="send" size={18} />{pending ? "যাচ্ছে…" : "পাঠান"}</button>
        </div>
        <Note>উত্তর পাঠালে {KIND_LABEL[thread.owner_kind]} অ্যাপে নোটিফিকেশন পাবেন। চ্যাটে কখনো OTP, পাসওয়ার্ড বা পুরো NID চাইবেন না।</Note>
      </div>
      <div style={{ padding: "0 16px 16px" }}>
        <KV label="শুরু">{bnDateTime(thread.created_at)}</KV>
        {thread.owner_mobile ? <KV label="মোবাইল">{bnDigits(thread.owner_mobile)}</KV> : null}
      </div>

      <ConfirmDialog
        open={confirm}
        title="সমাধান হয়েছে হিসেবে বন্ধ করবেন?"
        message="ব্যবহারকারী আবার লিখলে কথোপকথন নিজে থেকেই খুলে যাবে।"
        confirmLabel="বন্ধ করুন"
        onConfirm={() => changeStatus("resolve")}
        onClose={() => setConfirm(false)}
      />
    </section>
  );
}
