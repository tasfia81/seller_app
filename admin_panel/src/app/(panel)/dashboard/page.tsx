import styles from "./Dashboard.module.css";
import Link from "next/link";
import { Suspense } from "react";
import { DateFilter, parsePeriod, PERIODS, type Period } from "@/components/dashboard/DateFilter";
import { HourlySalesChart } from "@/components/dashboard/HourlySalesChart";
import { LoadError, Skeleton } from "@/components/shell/LoadState";
import { Icon, type IconName } from "@/components/ui/Icon";
import { Avatar, Chip, EmptyState, Kpi } from "@/components/ui/bits";
import { api, load } from "@/lib/api/server";
import type { ApiDashboard } from "@/lib/api/types";
import { bnDigits, bnTime, money } from "@/lib/format";

export const metadata = { title: "ড্যাশবোর্ড" };

const quickActions: { href: string; label: string; icon: IconName; bg: string; fg: string }[] = [
  { href: "/products/new", label: "পণ্য যোগ", icon: "tag", bg: "#E3F3EA", fg: "#168447" },
  { href: "/inventory", label: "স্টক যোগ", icon: "plus", bg: "#E3F3EA", fg: "#168447" },
  { href: "/assignments/new", label: "স্টক বরাদ্দ", icon: "truck", bg: "#E3F3EA", fg: "#168447" },
  { href: "/applications", label: "আবেদন যাচাই", icon: "doc", bg: "#E6EFFD", fg: "#1D4FB8" },
  { href: "/cash", label: "ক্যাশ যাচাই", icon: "cash", bg: "#FCF0DA", fg: "#85560C" },
  { href: "/reports", label: "রিপোর্ট", icon: "chart", bg: "#ECEFED", fg: "#45524A" },
];

export default function DashboardPage(props: PageProps<"/dashboard">) {
  return (
    <>
      <header className={`tb ${styles.header}`}>
        <h1>ড্যাশবোর্ড</h1>
        <span className="grow" />
        <Link className="ib" href="/activity" aria-label="নোটিফিকেশন">
          <Icon name="bell" />
        </Link>
      </header>
      <main className={`ct ${styles.content}`}>
        <nav className="qa" aria-label="দ্রুত কাজ">
          {quickActions.map((a) => (
            <Link key={a.href} href={a.href}>
              <span className="ic" style={{ background: a.bg, color: a.fg }}><Icon name={a.icon} /></span>
              {a.label}
            </Link>
          ))}
        </nav>
        <Suspense fallback={<Skeleton rows={5} />}>
          <DashboardData searchParams={props.searchParams} />
        </Suspense>
      </main>
    </>
  );
}

async function DashboardData({ searchParams }: { searchParams: Promise<Record<string, string | string[] | undefined>> }) {
  const period = parsePeriod((await searchParams).period);
  const r = await load(() => api.get<ApiDashboard>(`/admin/dashboard?period=${period}`));
  if (r.error !== undefined) return <LoadError message={r.error} retryHref={`/dashboard?period=${period}`} />;
  return <DashboardView d={r.data} period={period} />;
}

function change(now: number, before: number) {
  if (!before) return null;
  const pct = Math.round(((now - before) / before) * 100);
  return pct;
}

function DashboardView({ d, period }: { d: ApiDashboard; period: Period }) {
  const m = d.metrics;
  const label = PERIODS.find((p) => p.id === period)!.label;
  const pct = change(m.total_sales, m.previous_total_sales);
  const margin = m.total_sales ? Math.round((m.gross_profit / m.total_sales) * 100) : 0;
  const p = d.pending_actions;
  const pendingActions: { href: string; label: string; icon: IconName; count: number; bg: string; fg: string }[] = [
    { href: "/applications", label: "সেলার আবেদন", icon: "doc", count: p.applications, bg: "#E6EFFD", fg: "#1D4FB8" },
    { href: "/cash", label: "ক্যাশ জমা যাচাই", icon: "cash", count: p.cash_handovers, bg: "#FCF0DA", fg: "#85560C" },
    { href: "/returns", label: "স্টক ফেরতের অনুরোধ", icon: "ret", count: p.stock_returns, bg: "#ECEFED", fg: "#45524A" },
    { href: "/settlements", label: "দিনের হিসাব যাচাই", icon: "cal", count: p.settlements, bg: "#ECEFED", fg: "#45524A" },
    { href: "/corrections", label: "বিক্রি সংশোধনের অনুরোধ", icon: "edit", count: p.corrections, bg: "#ECEFED", fg: "#45524A" },
  ];
  const a = d.inventory_alerts;
  const noAlerts = !a.low_central_stock.length && !a.low_seller_stock.length && !a.pending_transfers && !a.damaged_units;

  return (
    <>
      <div className="sh">
        <DateFilter value={period} basePath="/dashboard" />
      </div>

      <section className="kpis" aria-label={`${label}-এর আর্থিক সারাংশ`}>
        <Kpi
          label={`${label}-এর মোট বিক্রি`}
          value={money(m.total_sales)}
          note={pct === null ? "আগের সময়ের সাথে তুলনা নেই" : <span style={{ color: pct >= 0 ? "#0F6A38" : "#A92F2F" }}>আগের সময়ের চেয়ে {bnDigits(Math.abs(pct))}% {pct >= 0 ? "বেশি" : "কম"}</span>}
        />
        <Kpi label="মোট লাভ" value={money(m.gross_profit)} note={`বিক্রি − পণ্যের ক্রয়মূল্য · ${bnDigits(margin)}%`} />
        <Kpi label="আনুমানিক নিট লাভ" value={money(m.estimated_net_profit)} note="সেলারের আয় ও খরচ বাদে" />
        <Kpi label="বাকি ক্যাশ" value={money(m.cash_outstanding)} note="সেলারদের হাতে, জমা হয়নি" tone={m.cash_outstanding ? "warn" : undefined} />
        <Kpi label="সেলারদের আয়" value={money(m.seller_earnings)} note={label} />
        <Kpi
          label="সক্রিয় সেলার"
          value={<>{bnDigits(m.active_sellers)} <span style={{ fontSize: 14, color: "#5F6C64", fontWeight: 500 }}>/ {bnDigits(m.total_active_sellers)}</span></>}
          note="এই সময়ে বিক্রি করেছেন"
        />
      </section>

      <div className="two">
        <div className="a">
          <HourlySalesChart key={period} hours={d.hourly_sales} periodLabel={label} />

          <section>
            <div className="sh" style={{ marginBottom: 10 }}>
              <h2 className="h2">সেলারদের অবস্থা</h2>
              <Link href="/reports/performance">সব দেখুন</Link>
            </div>
            {d.seller_performance.length ? (
              <div className="tw">
                <table>
                  <thead><tr><th>সেলার</th><th className="n">বিক্রি</th><th className="n">পণ্য</th><th className="n">বাকি ক্যাশ</th><th>আগের তুলনায়</th></tr></thead>
                  <tbody>
                    {d.seller_performance.map((s) => (
                      <tr key={s.seller_id}>
                        <td><Link className="sl" href={`/sellers/${s.seller_id}`}><Avatar name={s.name} /><b style={{ fontWeight: 600 }}>{s.name}</b></Link></td>
                        <td className="n"><b>{money(s.sales)}</b></td>
                        <td className="n">{bnDigits(s.quantity)}</td>
                        <td className="n" style={s.cash_due ? { color: "#85560C", fontWeight: 600 } : undefined}>{money(s.cash_due)}</td>
                        <td>
                          {s.change_percent === null ? <Chip>—</Chip> : s.change_percent > 0 ? <Chip tone="ok">▲ {bnDigits(s.change_percent)}%</Chip> : s.change_percent < 0 ? <Chip tone="er">▼ {bnDigits(-s.change_percent)}%</Chip> : <Chip>সমান</Chip>}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <div className="cd"><EmptyState icon="users" title="এই সময়ে কোনো সেলারের বিক্রি নেই" /></div>
            )}
          </section>

          <section className="cd">
            <div className="sh">
              <h2 className="h2">সাম্প্রতিক বিক্রি</h2>
              <Link href="/sales">বিক্রি মনিটর</Link>
            </div>
            {d.recent_sales.length ? (
              d.recent_sales.map((s) => (
                <Link key={s.id} className="li" href="/sales">
                  <span className="fx">
                    <span className="t1">{s.product_name} × {bnDigits(s.quantity)}</span>
                    <div className="mu">#{s.receipt_no} · {s.seller_name} · {bnTime(s.created_at)} · {s.payment_label}</div>
                  </span>
                  <b>{money(s.total)}</b>
                </Link>
              ))
            ) : (
              <EmptyState icon="receipt" title="এখনো কোনো বিক্রি নেই" />
            )}
          </section>
        </div>

        <div className="b">
          <section className="cd">
            <h2 className="h2" style={{ marginBottom: 6 }}>আপনার সিদ্ধান্তের অপেক্ষায়</h2>
            {pendingActions.map((x) => (
              <Link key={x.href} className="li" href={x.href}>
                <span className="ic" style={{ background: x.bg, color: x.fg }}><Icon name={x.icon} size={18} /></span>
                <span className="fx t1">{x.label}</span>
                <span className="cnt" style={{ background: x.bg, color: x.fg }}>{bnDigits(x.count)}</span>
              </Link>
            ))}
          </section>

          <section className="cd">
            <h2 className="h2" style={{ marginBottom: 6 }}>স্টকের সতর্কতা</h2>
            {noAlerts ? <EmptyState icon="box" title="কোনো সতর্কতা নেই" /> : null}
            {a.low_central_stock.map((x) => (
              <Link key={x.product_id} className="li" href="/inventory">
                <span className="ic" style={{ background: "#FBE5E5", color: "#A92F2F" }}><Icon name="alert" size={18} /></span>
                <span className="fx"><span className="t1">মূল স্টকে কম: {x.name}</span><div className="mu">গুদামে {bnDigits(x.warehouse)}</div></span>
              </Link>
            ))}
            {a.low_seller_stock.map((x) => (
              <Link key={x.seller_name + x.product} className="li" href="/assignments/new">
                <span className="ic" style={{ background: "#FCF0DA", color: "#85560C" }}><Icon name="box" size={18} /></span>
                <span className="fx"><span className="t1">সেলারের কাছে কম: {x.product}</span><div className="mu">{x.seller_name} · {bnDigits(x.qty)} বাকি</div></span>
              </Link>
            ))}
            {a.pending_transfers ? (
              <Link className="li" href="/assignments">
                <span className="ic" style={{ background: "#E6EFFD", color: "#1D4FB8" }}><Icon name="truck" size={18} /></span>
                <span className="fx"><span className="t1">হস্তান্তর বাকি: {bnDigits(a.pending_transfers)}টি বরাদ্দ</span><div className="mu">সেলার এখনো বুঝে নেননি</div></span>
              </Link>
            ) : null}
            {a.damaged_units ? (
              <Link className="li" href="/returns">
                <span className="ic" style={{ background: "#FBE5E5", color: "#A92F2F" }}><Icon name="flag" size={18} /></span>
                <span className="fx"><span className="t1">নষ্ট পণ্য: {bnDigits(a.damaged_units)}</span><div className="mu">ফেরত ও ক্ষতি দেখুন</div></span>
              </Link>
            ) : null}
          </section>
        </div>
      </div>
    </>
  );
}
