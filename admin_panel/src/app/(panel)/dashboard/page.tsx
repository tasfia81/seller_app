import Link from "next/link";
import { DateFilter } from "@/components/dashboard/DateFilter";
import { Icon, type IconName } from "@/components/ui/Icon";
import { Avatar, Chip, Kpi } from "@/components/ui/bits";
import { dashboard, DEMO_MODE, products, sales, sellers } from "@/lib/demo-data";
import { bnDigits, money } from "@/lib/format";
import { paymentLabel } from "@/lib/labels";

export const metadata = { title: "ড্যাশবোর্ড" };

const HOURS = ["৮টা", "৯", "১০", "১১", "১২", "১", "২", "৩", "৪", "৫"];

const quickActions: { href: string; label: string; icon: IconName; bg: string; fg: string }[] = [
  { href: "/products/new", label: "পণ্য যোগ", icon: "tag", bg: "#E3F3EA", fg: "#168447" },
  { href: "/inventory", label: "স্টক যোগ", icon: "plus", bg: "#E3F3EA", fg: "#168447" },
  { href: "/assignments/new", label: "স্টক বরাদ্দ", icon: "truck", bg: "#E3F3EA", fg: "#168447" },
  { href: "/applications", label: "আবেদন যাচাই", icon: "doc", bg: "#E6EFFD", fg: "#1D4FB8" },
  { href: "/cash", label: "ক্যাশ যাচাই", icon: "cash", bg: "#FCF0DA", fg: "#85560C" },
  { href: "/reports", label: "রিপোর্ট", icon: "chart", bg: "#ECEFED", fg: "#45524A" },
];

export default function DashboardPage() {
  const d = dashboard;
  const p = d.pending;
  const pendingActions: { href: string; label: string; icon: IconName; count: number; bg: string; fg: string }[] = [
    { href: "/applications", label: "সেলার আবেদন", icon: "doc", count: p.applications, bg: "#E6EFFD", fg: "#1D4FB8" },
    { href: "/cash", label: "ক্যাশ জমা যাচাই", icon: "cash", count: p.cash, bg: "#FCF0DA", fg: "#85560C" },
    { href: "/returns", label: "স্টক ফেরতের অনুরোধ", icon: "ret", count: p.returns, bg: "#ECEFED", fg: "#45524A" },
    { href: "/settlements", label: "দিনের হিসাব যাচাই", icon: "cal", count: p.settlements, bg: "#ECEFED", fg: "#45524A" },
    { href: "/corrections", label: "বিক্রি সংশোধনের অনুরোধ", icon: "edit", count: p.corrections, bg: "#ECEFED", fg: "#45524A" },
  ];
  const lowCentral = products.filter((x) => x.warehouse > 0 && x.warehouse <= x.lowStockAt);
  const activeSellers = sellers.filter((s) => s.status === "active").slice(0, 4);
  const maxHour = Math.max(...d.hourly);

  return (
    <>
      <header className="tb">
        <h1>ড্যাশবোর্ড</h1>
        <span className="sub hide-m">শনিবার, ২১ নভেম্বর ২০২৬</span>
        <span className="grow" />
        {DEMO_MODE ? <span className="demo" title="এখনকার সব সংখ্যা উদাহরণ, সার্ভার থেকে আসেনি">ডেমো ডেটা</span> : null}
        <Link className="ib" href="/activity" aria-label="নোটিফিকেশন, ৯টি নতুন">
          <Icon name="bell" />
          <span className="dot" />
        </Link>
        <span className="av hide-m" title="তানভীর আহমেদ">তা</span>
      </header>

      <main className="ct">
        <div className="sh">
          <DateFilter />
          <span className="mu">সর্বশেষ আপডেট: সকাল ১১:০৫</span>
        </div>

        <section className="kpis" aria-label="আজকের আর্থিক সারাংশ">
          <Kpi label="আজকের মোট বিক্রি" value={money(d.todaySales)} note={<span style={{ color: "#0F6A38" }}>গতকালের চেয়ে ১২% বেশি</span>} />
          <Kpi label="মোট লাভ" value={money(d.grossProfit)} note="বিক্রি − পণ্যের ক্রয়মূল্য · ২৩%" />
          <Kpi label="আনুমানিক নিট লাভ" value={money(d.netProfit)} note="সেলারের আয় ও খরচ বাদে" />
          <Kpi label="বাকি ক্যাশ" value={money(d.cashOutstanding)} note="৭ জন সেলারের কাছে" tone="warn" />
          <Kpi label="সেলারদের আজকের আয়" value={money(d.sellerEarnings)} note="অনুমোদনের অপেক্ষায়" />
          <Kpi
            label="সক্রিয় সেলার"
            value={<>{bnDigits(d.activeSellers)} <span style={{ fontSize: 14, color: "#5F6C64", fontWeight: 500 }}>/ {bnDigits(d.totalSellers)}</span></>}
            note="আজ বিক্রি করছেন"
          />
        </section>

        <nav className="qa" aria-label="দ্রুত কাজ">
          {quickActions.map((a) => (
            <Link key={a.href} href={a.href}>
              <span className="ic" style={{ background: a.bg, color: a.fg }}>
                <Icon name={a.icon} />
              </span>
              {a.label}
            </Link>
          ))}
        </nav>

        <div className="two">
          <div className="a">
            <section className="cd">
              <div className="sh">
                <h2 className="h2">ঘণ্টা অনুযায়ী বিক্রি</h2>
                <span className="mu">আজ · মোট {money(d.todaySales)}</span>
              </div>
              <div className="chart" role="img" aria-label="ঘণ্টাভিত্তিক বিক্রি, দুপুর ১২টায় সবচেয়ে বেশি">
                {d.hourly.map((v, i) => (
                  <i key={i} className={v === maxHour ? "hi" : undefined} style={{ height: `${(v / maxHour) * 100}%` }} title={`${HOURS[i]}: ${bnDigits(v)}%`} />
                ))}
              </div>
              <div className="chart-x">
                {HOURS.map((h) => (
                  <span key={h}>{h}</span>
                ))}
              </div>
            </section>

            <section>
              <div className="sh" style={{ marginBottom: 10 }}>
                <h2 className="h2">সেলারদের আজকের অবস্থা</h2>
                <Link href="/reports">সব দেখুন</Link>
              </div>
              <div className="tw">
                <table>
                  <thead>
                    <tr>
                      <th>সেলার</th>
                      <th className="n">বিক্রি</th>
                      <th className="n">পণ্য</th>
                      <th className="n">বাকি ক্যাশ</th>
                      <th>গতকালের তুলনায়</th>
                    </tr>
                  </thead>
                  <tbody>
                    {activeSellers.map((s) => (
                      <tr key={s.id}>
                        <td>
                          <Link className="sl" href={`/sellers/${s.id}`}>
                            <Avatar name={s.name} />
                            <b style={{ fontWeight: 600 }}>{s.name}</b>
                          </Link>
                        </td>
                        <td className="n"><b>{money(s.todaySales)}</b></td>
                        <td className="n">{bnDigits(s.todayItems)}</td>
                        <td className="n" style={s.cashDue ? { color: "#85560C", fontWeight: 600 } : undefined}>{money(s.cashDue)}</td>
                        <td>
                          {s.trend > 0 ? <Chip tone="ok">▲ {bnDigits(s.trend)}%</Chip> : s.trend < 0 ? <Chip tone="er">▼ {bnDigits(-s.trend)}%</Chip> : <Chip>সমান</Chip>}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </section>

            <section className="cd">
              <div className="sh">
                <h2 className="h2">সাম্প্রতিক নিশ্চিত বিক্রি</h2>
                <Link href="/sales">বিক্রি মনিটর</Link>
              </div>
              {sales
                .filter((s) => s.status === "confirmed")
                .slice(0, 4)
                .map((s) => (
                  <Link key={s.id} className="li" href="/sales">
                    <span className="fx">
                      <span className="t1">{s.product} × {bnDigits(s.qty)}</span>
                      <div className="mu">#{s.id} · {s.seller} · {s.time} · {paymentLabel[s.payment]}</div>
                    </span>
                    <b>{money(s.qty * s.unitPrice)}</b>
                  </Link>
                ))}
            </section>
          </div>

          <div className="b">
            <section className="cd">
              <h2 className="h2" style={{ marginBottom: 6 }}>আপনার সিদ্ধান্তের অপেক্ষায়</h2>
              {pendingActions.map((a) => (
                <Link key={a.href} className="li" href={a.href}>
                  <span className="ic" style={{ background: a.bg, color: a.fg }}>
                    <Icon name={a.icon} size={18} />
                  </span>
                  <span className="fx t1">{a.label}</span>
                  <span className="cnt" style={{ background: a.bg, color: a.fg }}>{bnDigits(a.count)}</span>
                </Link>
              ))}
            </section>

            <section className="cd">
              <h2 className="h2" style={{ marginBottom: 6 }}>স্টকের সতর্কতা</h2>
              {lowCentral.map((x) => (
                <Link key={x.id} className="li" href="/inventory">
                  <span className="ic" style={{ background: "#FBE5E5", color: "#A92F2F" }}><Icon name="alert" size={18} /></span>
                  <span className="fx">
                    <span className="t1">মূল স্টকে কম: {x.name}</span>
                    <div className="mu">গুদামে {bnDigits(x.warehouse)} {x.unit} · সীমা {bnDigits(x.lowStockAt)}</div>
                  </span>
                </Link>
              ))}
              <Link className="li" href="/sellers/rakib">
                <span className="ic" style={{ background: "#FCF0DA", color: "#85560C" }}><Icon name="box" size={18} /></span>
                <span className="fx"><span className="t1">সেলারের কাছে কম: পোলো টি-শার্ট</span><div className="mu">রাকিব হাসান · ২ পিস বাকি</div></span>
              </Link>
              <Link className="li" href="/assignments">
                <span className="ic" style={{ background: "#E6EFFD", color: "#1D4FB8" }}><Icon name="truck" size={18} /></span>
                <span className="fx"><span className="t1">হস্তান্তর বাকি: ২টি বরাদ্দ</span><div className="mu">সেলার এখনো বুঝে নেননি</div></span>
              </Link>
              <Link className="li" href="/returns">
                <span className="ic" style={{ background: "#FBE5E5", color: "#A92F2F" }}><Icon name="flag" size={18} /></span>
                <span className="fx"><span className="t1">গরমিল: ৩ পিস জার্সি</span><div className="mu">সাকিব হোসেন · গতকালের হিসাব</div></span>
              </Link>
            </section>
          </div>
        </div>
      </main>
    </>
  );
}
