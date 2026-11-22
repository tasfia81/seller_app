import Link from "next/link";
import { Suspense } from "react";
import { LoadError } from "@/components/shell/LoadState";
import { PageLoading } from "@/components/shell/PageLoading";
import { Topbar } from "@/components/shell/Topbar";
import { Icon } from "@/components/ui/Icon";
import { Avatar, Chip, EmptyState, KV, Kpi } from "@/components/ui/bits";
import { api, load } from "@/lib/api/server";
import { placeText, type ApiSellerOverview } from "@/lib/api/types";
import { bnDate, bnDigits, money } from "@/lib/format";
import { SellerControls, SellerEditForm } from "./SellerForms";

export const metadata = { title: "সেলারের প্রোফাইল" };

const TONE = { active: "ok", inactive: "nu", suspended: "er" } as const;

export default function SellerProfilePage(props: PageProps<"/sellers/[id]">) {
  return (
    <Suspense fallback={<PageLoading title="সেলার" />}>
      <SellerProfile params={props.params} />
    </Suspense>
  );
}

async function SellerProfile({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const r = await load(() => api.get<ApiSellerOverview>(`/admin/sellers/${encodeURIComponent(id)}`));
  if (r.error !== undefined) {
    return (
      <>
        <Topbar title="সেলার" back="/sellers" />
        <main className="ct"><LoadError message={r.error} retryHref={`/sellers/${id}`} /></main>
      </>
    );
  }
  const { seller: s, kpis: k, assignments, compensation, cash, earnings } = r.data;
  const items = assignments.flatMap((a) => a.items.map((i) => ({ ...i, assignment: a.id, pending: a.status === "pending_handover" })));

  return (
    <>
      <Topbar title={s.name} back="/sellers" crumb={{ href: "/sellers", label: "সেলার" }} />
      <main className="ct">
        <section className="cd" style={{ display: "flex", gap: 16, alignItems: "center", flexWrap: "wrap" }}>
          <Avatar name={s.name} size={64} />
          <div style={{ flex: "1 1 220px" }}>
            <div style={{ fontSize: 20, fontWeight: 700 }}>{s.name}</div>
            <div className="mu">{bnDigits(s.mobile)} · যোগ দিয়েছেন {bnDate(s.joined_at, true)}</div>
            <div style={{ display: "flex", gap: 6, marginTop: 6, flexWrap: "wrap" }}>
              <Chip tone={TONE[s.status]}>{s.status_label}</Chip>
              <Chip tone="inf">{bnDigits(compensation.label)}</Chip>
              <Chip>{s.policy_label}</Chip>
            </div>
          </div>
          <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
            <Link className="btn" href="/assignments/new"><Icon name="truck" size={18} />স্টক দিন</Link>
            <Link className="btn o" href="/compensation">আয়ের নিয়ম বদলান</Link>
          </div>
        </section>

        <div className="kpis">
          <Kpi label="আজকের বিক্রি" value={money(k.today_sales)} />
          <Kpi label="এই মাসের বিক্রি" value={money(k.month_sales)} />
          <Kpi label="চালু বরাদ্দে দেওয়া" value={`${bnDigits(k.assigned)} পিস`} />
          <Kpi label="হাতে আছে" value={`${bnDigits(k.available)} পিস`} />
          <Kpi label="বাকি ক্যাশ" value={money(k.cash_due)} tone={k.cash_due ? "warn" : undefined} />
          <Kpi label="দেওয়ার মতো আয়" value={money(k.earnings_payable)} tone="good" />
        </div>

        <div className="two">
          <div className="a">
            <section>
              <div className="sh" style={{ marginBottom: 10 }}><h2 className="h2">দেওয়া পণ্য (চালু বরাদ্দ)</h2><Link href="/assignments">সব বরাদ্দ</Link></div>
              {items.length ? (
                <div className="tw">
                  <table style={{ minWidth: 600 }}>
                    <thead><tr><th>পণ্য</th><th>ধরন</th><th className="n">দেওয়া</th><th className="n">বিক্রি</th><th className="n">ফেরত</th><th className="n">হাতে</th></tr></thead>
                    <tbody>
                      {items.map((i) => {
                        const left = i.quantity - i.sold - i.returned;
                        return (
                          <tr key={i.assignment + i.product_id + (i.variant ?? "")}>
                            <td><b style={{ fontWeight: 600 }}>{i.name}</b> {i.pending ? <Chip tone="wa">হস্তান্তর বাকি</Chip> : null}</td>
                            <td>{i.variant ?? "—"}</td>
                            <td className="n">{bnDigits(i.quantity)}</td>
                            <td className="n">{bnDigits(i.sold)}</td>
                            <td className="n">{bnDigits(i.returned)}</td>
                            <td className="n"><b style={left <= 2 ? { color: "#85560C" } : undefined}>{bnDigits(left)}</b></td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              ) : (
                <div className="cd"><EmptyState icon="box" title="এখন কোনো চালু বরাদ্দ নেই" /></div>
              )}
            </section>
            <SellerEditForm seller={s} presentAddress={placeText(s.present_address)} />
          </div>

          <div className="b">
            <section className="cd">
              <div className="sh" style={{ marginBottom: 4 }}><h2 className="h2">আয়ের নিয়ম</h2><Link href="/compensation">বদলান</Link></div>
              <KV label="বর্তমান">{bnDigits(compensation.label)}</KV>
              {compensation.effective_from ? <KV label="কার্যকর">{bnDate(compensation.effective_from, true)} থেকে</KV> : null}
            </section>
            <section className="cd">
              <div className="sh" style={{ marginBottom: 4 }}><h2 className="h2">টাকার অবস্থা</h2><Link href="/cash">ক্যাশ জমা</Link></div>
              <KV label="হাতে নেওয়া ক্যাশ">{money(cash.collected)}</KV>
              <KV label="যাচাই হয়েছে">{money(cash.verified)}</KV>
              <KV label="যাচাইয়ের অপেক্ষায়">{money(cash.pending_verification)}</KV>
              <KV label="বাকি ক্যাশ">{money(cash.due)}</KV>
              <KV label="দেওয়ার মতো আয়">{money(earnings.outstanding)}</KV>
            </section>
            <section className="cd">
              <h2 className="h2" style={{ marginBottom: 4 }}>পরিচয় ও যোগাযোগ</h2>
              <KV label="পরিচয়পত্র">{s.nid_masked.replace(/\d/g, (d) => bnDigits(d))}</KV>
              <KV label="স্থায়ী ঠিকানা">{placeText(s.permanent_address)}</KV>
              <KV label="জরুরি যোগাযোগ">{s.emergency.name} ({s.emergency.relation}) · {bnDigits(s.emergency.mobile)}</KV>
            </section>
            <SellerControls id={s.id} name={s.name} status={s.status} />
          </div>
        </div>
      </main>
    </>
  );
}
