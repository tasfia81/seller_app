"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { Icon } from "@/components/ui/Icon";
import { Avatar, EmptyState, Note, StatusChip } from "@/components/ui/bits";
import { bnDigits, money } from "@/lib/format";
import {
  activeCapital,
  investorAppStatus,
  investorStatus,
  type Investor,
  type InvestorApplication,
} from "@/lib/investors";

type Tab = "active" | "suspended";
type Sort = "capital" | "due" | "new";

export function InvestorsView({ investors, applications, idle }: { investors: Investor[]; applications: InvestorApplication[]; idle: number }) {
  const [tab, setTab] = useState<Tab>("active");
  const [sort, setSort] = useState<Sort>("capital");
  const [q, setQ] = useState("");

  const list = useMemo(() => {
    const t = q.trim();
    const rows = investors.filter(
      (i) => (tab === "suspended" ? i.status === "suspended" : i.status !== "suspended") && (!t || i.name.includes(t) || i.code.includes(t)),
    );
    const key = (i: Investor) => (sort === "capital" ? activeCapital(i) : sort === "due" ? i.profitThisMonth : -investors.indexOf(i));
    return [...rows].sort((a, b) => key(b) - key(a));
  }, [investors, tab, sort, q]);

  const activeCount = investors.filter((i) => i.status !== "suspended").length;
  const suspendedCount = investors.length - activeCount;

  return (
    <>
      <div className="tabs" role="tablist" aria-label="বিনিয়োগকারীর অবস্থা">
        <button type="button" role="tab" aria-selected={tab === "active"} className={`tab${tab === "active" ? " on" : ""}`} onClick={() => setTab("active")}>
          সক্রিয় <span className="ch ok">{bnDigits(activeCount)}</span>
        </button>
        <Link role="tab" className="tab" href="/investors/applications">
          আবেদন <span className="ch wa">{bnDigits(applications.length)}</span>
        </Link>
        <button type="button" role="tab" aria-selected={tab === "suspended"} className={`tab${tab === "suspended" ? " on" : ""}`} onClick={() => setTab("suspended")}>
          স্থগিত{suspendedCount ? <span className="ch er">{bnDigits(suspendedCount)}</span> : null}
        </button>
      </div>

      <div className="sh">
        <div className="srch">
          <input className="in" type="search" placeholder="নাম বা আইডি খুঁজুন" aria-label="বিনিয়োগকারী খুঁজুন" value={q} onChange={(e) => setQ(e.target.value)} />
          <span><Icon name="search" size={18} /></span>
        </div>
        <div className="seg" role="group" aria-label="সাজানো">
          {([["capital", "মূলধন বেশি"], ["due", "পাওনা বেশি"], ["new", "নতুন"]] as const).map(([id, label]) => (
            <button key={id} type="button" className={sort === id ? "on" : undefined} aria-pressed={sort === id} onClick={() => setSort(id)}>{label}</button>
          ))}
        </div>
      </div>

      {list.length === 0 ? (
        <div className="cd"><EmptyState icon="users" title="এই তালিকায় কেউ নেই" /></div>
      ) : (
        <div className="tw">
          <table>
            <thead>
              <tr><th>বিনিয়োগকারী</th><th className="n">মোট দিয়েছেন</th><th className="n">সক্রিয় মূলধন</th><th className="n">খাটেনি</th><th className="n">লাভ (এ পর্যন্ত)</th><th className="n">এ মাসে দেয়</th><th>অবস্থা</th><th /></tr>
            </thead>
            <tbody>
              {list.map((i) => (
                <tr key={i.id}>
                  <td style={{ minWidth: 220 }}>
                    <Link className="sl" href={`/investors/${i.id}`}>
                      <Avatar name={i.name} />
                      <span><b>{i.name}</b><span className="mu">{i.code} · {i.since} থেকে</span></span>
                    </Link>
                  </td>
                  <td className="n">{money(i.invested)}</td>
                  <td className="n">{money(activeCapital(i))}</td>
                  <td className="n">{money(i.uninvested)}</td>
                  <td className="n">{money(i.profitTotal)}</td>
                  <td className="n"><b>{money(i.profitThisMonth)}</b></td>
                  <td><StatusChip value={investorStatus[i.status]} /></td>
                  <td className="n"><Link className="btn g sm" href={`/investors/${i.id}`}>দেখুন</Link></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <div className="two">
        <div className="a">
          <section className="cd">
            <div className="sh" style={{ marginBottom: 4 }}>
              <h2 className="h2">নতুন আবেদন</h2>
              <Link href="/investors/applications">সব আবেদন</Link>
            </div>
            {applications.length === 0 ? (
              <EmptyState icon="doc" title="নতুন আবেদন নেই" />
            ) : (
              applications.map((a) => (
                <Link key={a.id} className="li" href="/investors/applications">
                  <Avatar name={a.name} />
                  <span className="fx">
                    <span className="t1">{a.name}</span>
                    <div className="mu">{a.mobileMasked} · {a.submitted} · প্রস্তাবিত {money(a.proposed)}</div>
                  </span>
                  <StatusChip value={investorAppStatus[a.status]} />
                </Link>
              ))
            )}
          </section>
        </div>
        <div className="b">
          <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 4 }}>
            <h2 className="h2">আজ যা করতে হবে</h2>
            <Link className="li" href="/investor-withdrawals">
              <span className="ic" style={{ background: "#FCF0DA", color: "#85560C" }}><Icon name="ret" size={18} /></span>
              <span className="fx"><span className="t1">মূলধন ফেরতের অনুরোধ</span><div className="mu">সিদ্ধান্ত বাকি</div></span>
              <Icon name="chev" size={18} />
            </Link>
            <Link className="li" href="/investments">
              <span className="ic" style={{ background: "#E3F3EA", color: "#0F6A38" }}><Icon name="wallet" size={18} /></span>
              <span className="fx"><span className="t1">{money(idle)} এখনো খাটেনি</span><div className="mu">নতুন স্টক কেনায় লাগান</div></span>
              <Icon name="chev" size={18} />
            </Link>
            <Link className="li" href="/investor-profit">
              <span className="ic" style={{ background: "#E6EFFD", color: "#1D4FB8" }}><Icon name="cal" size={18} /></span>
              <span className="fx"><span className="t1">নভেম্বরের লাভ বিতরণ</span><div className="mu">খসড়া প্রস্তুত · ৫ ডিসে পেমেন্ট</div></span>
              <Icon name="chev" size={18} />
            </Link>
          </section>
          <Note icon="lock">বিনিয়োগকারীর NID, ব্যাংক নম্বর ও পুরো মোবাইল নম্বর গোপন থাকে। দেখতে চাইলে কারণ লিখতে হয়, আর সেটা অডিট লগে থাকে।</Note>
        </div>
      </div>
    </>
  );
}
