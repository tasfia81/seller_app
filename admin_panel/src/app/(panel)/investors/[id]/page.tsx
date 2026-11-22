import Link from "next/link";
import { notFound } from "next/navigation";
import { Suspense } from "react";
import { PageLoading } from "@/components/shell/PageLoading";
import { Topbar } from "@/components/shell/Topbar";
import { Icon } from "@/components/ui/Icon";
import { Avatar, Chip, KV, Kpi, Note, StatusChip } from "@/components/ui/bits";
import { ActionButton, Tabs } from "@/components/ui/feedback";
import { bnDigits, money } from "@/lib/format";
import { activeCapital, inStock, investorById, investorStatus, investors } from "@/lib/investors";

export function generateStaticParams() {
  return investors.map((i) => ({ id: i.id }));
}

export async function generateMetadata(props: PageProps<"/investors/[id]">) {
  const { id } = await props.params;
  return { title: investorById(id)?.name ?? "বিনিয়োগকারী" };
}

export default function InvestorProfilePage(props: PageProps<"/investors/[id]">) {
  return (
    <Suspense fallback={<PageLoading title="বিনিয়োগকারী" />}>
      <InvestorProfile params={props.params} />
    </Suspense>
  );
}

const KIND: Record<string, [string, "ok" | "wa" | "inf"]> = {
  invest: ["বিনিয়োগ", "inf"],
  profit: ["লাভ প্রদান", "ok"],
  withdraw: ["মূলধন ফেরত", "wa"],
};

async function InvestorProfile({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const inv = investorById(id);
  if (!inv) notFound();
  const kistis = inv.ledger.filter((l) => l.kind === "invest").length;

  return (
    <>
      <Topbar title={inv.name} back="/investors" crumb={{ href: "/investors", label: "বিনিয়োগকারী" }}>
        <Link className="btn sm" href="/investments"><Icon name="plus" size={18} />নতুন কিস্তি রেকর্ড</Link>
      </Topbar>
      <main className="ct">
        <section className="cd" style={{ display: "flex", gap: 14, alignItems: "center", flexWrap: "wrap" }}>
          <Avatar name={inv.name} size={60} />
          <div className="fx">
            <div style={{ fontSize: 19, fontWeight: 700 }}>{inv.name}</div>
            <div className="mu">{inv.code} · যোগ দিয়েছেন {inv.since} · {inv.mobileMasked}</div>
          </div>
          <StatusChip value={investorStatus[inv.status]} />
          <Chip tone="ok">KYC যাচাইকৃত</Chip>
          <Chip tone="ok">চুক্তি সই হয়েছে</Chip>
        </section>

        <div className="kpis">
          <Kpi label="মোট দিয়েছেন" value={money(inv.invested)} note={kistis ? `${bnDigits(kistis)} কিস্তিতে` : undefined} />
          <Kpi label="সক্রিয় মূলধন" value={money(activeCapital(inv))} note={`ফেরত দেওয়া ${money(inv.withdrawn)}`} />
          <Kpi label="স্টকে খাটছে" value={money(inStock(inv))} />
          <Kpi label="খাটেনি" value={money(inv.uninvested)} note="লাগানো বাকি" tone="warn" />
          <Kpi label="মোট লাভ" value={money(inv.profitTotal)} note={`দেওয়া ${money(inv.profitPaid)} · এ মাসে ${money(inv.profitThisMonth)}`} tone="good" />
        </div>

        <Tabs label="বিনিয়োগকারীর তথ্য" tabs={[{ id: "where", label: "কোথায় টাকা" }, { id: "ledger", label: "লেনদেন" }, { id: "kyc", label: "KYC ও কাগজ" }, { id: "audit", label: "অডিট" }]} />

        <div className="two">
          <div className="a">
            {inv.holdings.length ? (
              <div className="tw">
                <table>
                  <thead><tr><th>প্রোডাক্ট (ব্যাচ)</th><th className="n">বিনিয়োগ</th><th className="n">কেনা</th><th>বিক্রি</th><th className="n">সেলারের হাতে</th><th className="n">ওনার লাভ</th></tr></thead>
                  <tbody>
                    {inv.holdings.map((h) => {
                      const pct = Math.round((h.sold / h.bought) * 100);
                      return (
                        <tr key={h.batch}>
                          <td><b>{h.product}</b><div className="mu">{h.batch}</div></td>
                          <td className="n">{money(h.bought * h.unitCost)}</td>
                          <td className="n">{bnDigits(h.bought)}</td>
                          <td style={{ minWidth: 150 }}><div className="bar"><i style={{ width: `${pct}%` }} /></div><span className="mu">{bnDigits(h.sold)} · {bnDigits(pct)}%</span></td>
                          <td className="n">{bnDigits(h.withSellers)}</td>
                          <td className="n"><b>{money(h.share)}</b></td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            ) : (
              <Note>ডেমো ডেটায় এই বিনিয়োগকারীর প্রোডাক্টভিত্তিক হিসাব নেই। ব্যাকএন্ড যুক্ত হলে এখানে আসল তালিকা দেখাবে।</Note>
            )}
            {inv.id === "ashraful" ? (
              <Note kind="warn" icon="alert">জার্সির ৬ পিস নষ্ট হিসেবে জমা — তদন্ত চলছে। ক্ষতি (৳২,১০০) ঠিক হলে ওনার হিসাবে যোগ হবে এবং অ্যাপে নোটিফিকেশন যাবে।</Note>
            ) : null}
            {inv.ledger.length ? (
              <section className="cd">
                <h2 className="h2" style={{ marginBottom: 6 }}>লেনদেন</h2>
                <div className="tw" style={{ border: 0 }}>
                  <table style={{ minWidth: 560 }}>
                    <thead><tr><th>তারিখ</th><th>ধরন</th><th className="n">টাকা</th><th>মাধ্যম</th><th>রসিদ</th></tr></thead>
                    <tbody>
                      {inv.ledger.map((l) => (
                        <tr key={l.ref}>
                          <td>{l.date}</td>
                          <td><Chip tone={KIND[l.kind][1]}>{l.label}</Chip></td>
                          <td className="n">{l.kind === "withdraw" ? "−" : ""}{money(l.amount)}</td>
                          <td>{l.via}</td>
                          <td className="mu">{l.ref}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </section>
            ) : null}
          </div>
          <div className="b">
            <section className="cd">
              <div className="sh" style={{ marginBottom: 4 }}><h2 className="h2">চুক্তির শর্ত</h2><ActionButton className="btn g sm">বদলান</ActionButton></div>
              <KV label="লাভের ভাগ">নিট লাভের {bnDigits(inv.sharePercent)}%</KV>
              <KV label="লাভ দেওয়ার দিন">প্রতি মাসের ৫ তারিখ</KV>
              <KV label="মূলধন ফেরতের নোটিশ">৩০ দিন</KV>
              <KV label="লাভ নেওয়া">{inv.preference === "cash" ? "প্রতি মাসে টাকা" : "আবার বিনিয়োগ"}</KV>
              <div className="mu" style={{ marginTop: 6 }}>শর্ত বদলালে শুধু পরের কিস্তি থেকে কার্যকর হবে, নতুন চুক্তিতে উভয়ের সই লাগবে।</div>
            </section>
            <section className="cd">
              <h2 className="h2" style={{ marginBottom: 4 }}>টাকার মাধ্যম ও নমিনি</h2>
              <KV label="লাভ">{inv.profitVia}</KV>
              <KV label="মূলধন ফেরত">{inv.capitalVia}</KV>
              <KV label="নমিনি">{inv.nominee}</KV>
            </section>
            <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 8 }}>
              <h2 className="h2">অ্যাকাউন্ট নিয়ন্ত্রণ</h2>
              <Link className="btn o" href="/messages"><Icon name="bell" size={18} />বার্তা পাঠান (অ্যাপে)</Link>
              <ActionButton className="btn g">নতুন স্টকে টাকা লাগানো বন্ধ রাখুন</ActionButton>
              <ActionButton className="btn r" confirm={{ title: "অ্যাকাউন্ট স্থগিত করবেন?", message: "উনি শুধু হিসাব দেখতে পারবেন; লাভ ও ফেরত নিয়ম অনুযায়ী চলতে থাকবে।", label: "স্থগিত করুন", danger: true }}>
                অ্যাকাউন্ট স্থগিত করুন
              </ActionButton>
            </section>
          </div>
        </div>
      </main>
    </>
  );
}
