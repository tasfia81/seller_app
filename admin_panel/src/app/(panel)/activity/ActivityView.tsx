"use client";

import Link from "next/link";
import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { bnDateTime } from "@/lib/format";
import { markNotificationsRead } from "./actions";

export type Notice = { id: string; title: string; body: string; at: string; link: string; kind: string; read: boolean };
export type Audit = { id: string; actor_name: string; at: string; action: string; target: string; summary: string };

export function ActivityView({ notices, audit }: { notices: Notice[]; audit: Audit[] }) {
  const [salesOnly, setSalesOnly] = useState(false);
  const [error, setError] = useState("");
  const [busy, start] = useTransition();
  const router = useRouter();
  const list = salesOnly ? notices.filter((notice) => notice.kind === "sale_created") : notices;

  return (
    <div className="two">
      <section className="b cd">
        <div className="sh">
          <h2 className="h2">নোটিফিকেশন</h2>
          <button className="btn g sm" disabled={busy || notices.every((n) => n.read)} onClick={() => start(async () => {
            const result = await markNotificationsRead();
            setError(result.ok ? "" : result.message);
            if (result.ok) {
              window.dispatchEvent(new Event("admin-live-update"));
              router.refresh();
            }
          })}>সব পড়া হয়েছে</button>
        </div>
        {error ? <p role="alert">{error}</p> : null}
        <div className="pills">
          <button className={salesOnly ? "pill" : "pill on"} onClick={() => setSalesOnly(false)}>সব</button>
          <button className={salesOnly ? "pill on" : "pill"} onClick={() => setSalesOnly(true)}>নতুন বিক্রি</button>
        </div>
        {!list.length ? <p className="mu">এই তালিকায় কোনো নোটিফিকেশন নেই।</p> : null}
        {list.map((n) => (
          <div key={n.id} className="li">
            <div className="fx">
              <b>{n.title}{n.read ? "" : " · নতুন"}</b>
              <div className="mu">{n.body} · {bnDateTime(n.at)}</div>
              {n.link.startsWith("/") && !n.link.startsWith("//") ? <Link href={n.link}>বিস্তারিত দেখুন</Link> : null}
            </div>
          </div>
        ))}
      </section>
      <section className="a cd">
        <h2 className="h2">অডিট লগ</h2>
        <div className="tw">
          <table style={{ minWidth: 600 }}>
            <thead><tr><th>সময়</th><th>কে</th><th>কাজ</th><th>বিস্তারিত</th></tr></thead>
            <tbody>{audit.map((row) => <tr key={row.id}><td>{bnDateTime(row.at)}</td><td>{row.actor_name}</td><td>{row.action}</td><td>{row.summary}</td></tr>)}</tbody>
          </table>
        </div>
      </section>
    </div>
  );
}
