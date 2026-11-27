"use client";

import Link from "next/link";
import { useState } from "react";
import { Icon } from "@/components/ui/Icon";
import { Avatar, Chip, EmptyState } from "@/components/ui/bits";
import type { ApiSellerRow, ApiSellerStatus } from "@/lib/api/types";
import { bnDigits, money } from "@/lib/format";

type SellerStatus = ApiSellerStatus;
type CompensationModel = ApiSellerRow["model"];
const TONE = { active: "ok", inactive: "nu", suspended: "er" } as const;

const STATUS: { id: SellerStatus | "all"; label: string }[] = [
  { id: "all", label: "সব" },
  { id: "active", label: "সক্রিয়" },
  { id: "inactive", label: "নিষ্ক্রিয়" },
  { id: "suspended", label: "স্থগিত" },
];
const MODELS: { id: CompensationModel; label: string }[] = [
  { id: "profit", label: "লাভের ভাগ" },
  { id: "daily", label: "দৈনিক মজুরি" },
  { id: "per_unit", label: "প্রতি পিস" },
  { id: "hybrid", label: "মিশ্র" },
];

export function SellersTable({ items }: { items: ApiSellerRow[] }) {
  const [status, setStatus] = useState<SellerStatus | "all">("all");
  const [model, setModel] = useState<CompensationModel | null>(null);
  const [q, setQ] = useState("");
  const list = items.filter(
    (s) => (status === "all" || s.status === status) && (!model || s.model === model) && (s.name.includes(q.trim()) || s.mobile.includes(q.trim())),
  );

  return (
    <>
      <div className="sh">
        <div className="srch">
          <input className="in" type="search" placeholder="নাম বা মোবাইল নম্বর খুঁজুন" aria-label="সেলার খুঁজুন" value={q} onChange={(e) => setQ(e.target.value)} />
          <span><Icon name="search" size={18} /></span>
        </div>
        <div className="pills" role="group" aria-label="ফিল্টার">
          {STATUS.map((s) => (
            <button key={s.id} type="button" className={`pill${status === s.id ? " on" : ""}`} onClick={() => setStatus(s.id)}>{s.label}</button>
          ))}
          <span style={{ width: 1, background: "#E4EBE6", margin: "0 4px" }} />
          {MODELS.map((m) => (
            <button key={m.id} type="button" className={`pill${model === m.id ? " sel" : ""}`} onClick={() => setModel(model === m.id ? null : m.id)}>{m.label}</button>
          ))}
        </div>
      </div>
      <div className="tw">
        {list.length === 0 ? (
          <EmptyState icon="users" title="কোনো সেলার মেলেনি" text="অন্য নাম বা ফিল্টার দিয়ে খুঁজুন।" />
        ) : (
          <table style={{ minWidth: 860 }}>
            <thead>
              <tr><th>সেলার</th><th>অবস্থা</th><th>আয়ের ধরন</th><th>স্টকের নিয়ম</th><th className="n" scope="col">হাতে আছে</th><th className="n">আজকের বিক্রি</th><th className="n">বাকি ক্যাশ</th><th /></tr>
            </thead>
            <tbody>
              {list.map((s) => (
                <tr key={s.id}>
                  <td>
                    <Link className="sl" href={`/sellers/${s.id}`}>
                      <Avatar name={s.name} />
                      <span><b>{s.name}</b><span className="mu">{bnDigits(s.mobile)}</span></span>
                    </Link>
                  </td>
                  <td><Chip tone={TONE[s.status]}>{s.status_label}</Chip></td>
                  <td>{bnDigits(s.compensation)}</td>
                  <td>{s.policy_label}</td>
                  <td className="n"><b>{bnDigits(s.available)}</b></td>
                  <td className="n"><b>{money(s.today_sales)}</b></td>
                  <td className="n" style={s.cash_due ? { color: s.status === "suspended" ? "#A92F2F" : "#85560C", fontWeight: 600 } : undefined}>{money(s.cash_due)}</td>
                  <td className="n">
                    <Link href={`/sellers/${s.id}`} aria-label={`${s.name}-এর প্রোফাইল`} className="ib" style={{ display: "inline-flex", width: 36, height: 36 }}>
                      <Icon name="chev" />
                    </Link>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </>
  );
}
