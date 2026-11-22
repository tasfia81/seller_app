import Link from "next/link";
import { notFound } from "next/navigation";
import { Suspense } from "react";
import { PageLoading } from "@/components/shell/PageLoading";
import { Topbar } from "@/components/shell/Topbar";
import { Icon } from "@/components/ui/Icon";
import { Avatar, Chip, KV, Kpi, Note, StatusChip } from "@/components/ui/bits";
import { ActionButton, Tabs } from "@/components/ui/feedback";
import { sellers } from "@/lib/demo-data";
import { bnDigits, money } from "@/lib/format";
import { policyLabel, sellerStatus } from "@/lib/labels";

export function generateStaticParams() {
  return sellers.map((s) => ({ id: s.id }));
}

export async function generateMetadata(props: PageProps<"/sellers/[id]">) {
  const { id } = await props.params;
  return { title: sellers.find((s) => s.id === id)?.name ?? "সেলার" };
}

const ASSIGNED = [
  { name: "জার্সি — বাংলাদেশ", variant: "L", given: 20, sold: 12, returned: 0 },
  { name: "পোলো টি-শার্ট", variant: "XL", given: 10, sold: 6, returned: 2 },
  { name: "বেসিক টি-শার্ট (সাদা)", variant: "M", given: 10, sold: 5, returned: 0 },
];

export default function SellerProfilePage(props: PageProps<"/sellers/[id]">) {
  return (
    <Suspense fallback={<PageLoading title="সেলার" />}>
      <SellerProfile params={props.params} />
    </Suspense>
  );
}

async function SellerProfile({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const s = sellers.find((x) => x.id === id);
  if (!s) notFound();

  return (
    <>
      <Topbar title={s.name} back="/sellers" crumb={{ href: "/sellers", label: "সেলার" }} />
      <main className="ct">
        <section className="cd" style={{ display: "flex", gap: 16, alignItems: "center", flexWrap: "wrap" }}>
          <Avatar name={s.name} size={64} />
          <div style={{ flex: "1 1 220px" }}>
            <div style={{ fontSize: 20, fontWeight: 700 }}>{s.name}</div>
            <div className="mu">{s.mobile}</div>
            <div style={{ display: "flex", gap: 6, marginTop: 6, flexWrap: "wrap" }}>
              <StatusChip value={sellerStatus[s.status]} />
              <Chip tone="inf">{s.compensation}</Chip>
              <Chip>{policyLabel[s.policy]}</Chip>
            </div>
          </div>
          <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
            <Link className="btn" href="/assignments/new"><Icon name="truck" size={18} />স্টক দিন</Link>
            <Link className="btn o" href="/compensation">আয়ের নিয়ম বদলান</Link>
          </div>
        </section>

        <Tabs label="সেলারের তথ্য" tabs={["সারাংশ", "দেওয়া পণ্য", "বিক্রি", "আয়", "ক্যাশ জমা", "দিনের হিসাব", "অ্যাকাউন্ট"].map((t) => ({ id: t, label: t }))} />

        <div className="kpis">
          <Kpi label="আজকের বিক্রি" value={money(s.todaySales)} />
          <Kpi label="এই মাসের বিক্রি" value={money(s.monthSales)} />
          <Kpi label="মোট দেওয়া স্টক" value={`${bnDigits(s.assigned)} পিস`} />
          <Kpi label="হাতে আছে" value={`${bnDigits(s.available)} পিস`} />
          <Kpi label="বাকি ক্যাশ" value={money(s.cashDue)} tone={s.cashDue ? "warn" : undefined} />
          <Kpi label="দেওয়ার মতো আয়" value={money(s.payable)} tone="good" />
        </div>

        <div className="two">
          <div className="a">
            <section>
              <div className="sh" style={{ marginBottom: 10 }}>
                <h2 className="h2">দেওয়া পণ্য (চালু বরাদ্দ)</h2>
                <Link href="/assignments/2104">বরাদ্দ #বর-২১০৪ দেখুন</Link>
              </div>
              <div className="tw">
                <table style={{ minWidth: 600 }}>
                  <thead><tr><th>পণ্য</th><th>ধরন</th><th className="n">দেওয়া</th><th className="n">বিক্রি</th><th className="n">ফেরত</th><th className="n">হাতে</th></tr></thead>
                  <tbody>
                    {ASSIGNED.map((a) => {
                      const left = a.given - a.sold - a.returned;
                      return (
                        <tr key={a.name}>
                          <td><b style={{ fontWeight: 600 }}>{a.name}</b></td>
                          <td>{a.variant}</td>
                          <td className="n">{bnDigits(a.given)}</td>
                          <td className="n">{bnDigits(a.sold)}</td>
                          <td className="n">{bnDigits(a.returned)}</td>
                          <td className="n"><b style={left <= 2 ? { color: "#85560C" } : undefined}>{bnDigits(left)}</b></td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </section>

            <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 14 }}>
              <div className="sh"><h2 className="h2">তথ্য সম্পাদনা</h2><span className="mu">পরিবর্তন অডিট লগে থাকবে</span></div>
              <div className="fg">
                <div className="f"><label htmlFor="ph">মোবাইল নম্বর</label><input id="ph" className="in" defaultValue={s.mobile} /></div>
                <div className="f"><label htmlFor="st">অ্যাকাউন্টের অবস্থা</label><select id="st" className="in" defaultValue={s.status}><option value="active">সক্রিয়</option><option value="inactive">নিষ্ক্রিয়</option><option value="suspended">স্থগিত</option></select></div>
                <div className="f"><label htmlFor="ad">বর্তমান ঠিকানা</label><input id="ad" className="in" defaultValue="মিরপুর, ঢাকা" /></div>
                <div className="f"><label htmlFor="po">স্টকের নিয়ম</label><select id="po" className="in" defaultValue={s.policy}><option value="dailyReturn">প্রতিদিন ফেরত</option><option value="carryForward">পরের দিনে চলবে</option></select></div>
              </div>
              <div>
                <div className="mu">কাজের অনুমতি</div>
                <label className="ck"><input type="checkbox" defaultChecked /> অনুমোদিত সীমার মধ্যে দাম বদলাতে পারবেন</label>
                <label className="ck"><input type="checkbox" /> ডিসকাউন্ট দিতে পারবেন</label>
                <label className="ck"><input type="checkbox" defaultChecked /> বিকাশ/নগদে টাকা নিতে পারবেন</label>
              </div>
              <Note icon="shield">নাম, জন্মতারিখ বা পরিচয়পত্রের তথ্য এখানে বদলানো যায় না — সেগুলো বদলাতে আবার যাচাই করতে হবে।</Note>
              <div style={{ display: "flex", justifyContent: "flex-end" }}><ActionButton>সংরক্ষণ করুন</ActionButton></div>
            </section>
          </div>

          <div className="b">
            <section className="cd">
              <div className="sh" style={{ marginBottom: 4 }}><h2 className="h2">আয়ের নিয়ম</h2><Link href="/compensation">বদলান</Link></div>
              <KV label="বর্তমান">{s.compensation}</KV>
              <KV label="কার্যকর">১ জুন ২০২৬ থেকে</KV>
            </section>
            <section className="cd">
              <div className="sh" style={{ marginBottom: 4 }}><h2 className="h2">টাকার অবস্থা</h2><Link href="/cash">ক্যাশ জমা</Link></div>
              <KV label="বাকি ক্যাশ">{money(s.cashDue)}</KV>
              <KV label="দেওয়ার মতো আয়">{money(s.payable)}</KV>
              <KV label="সর্বশেষ দিনের হিসাব"><Chip tone="ok">বন্ধ · গতকাল</Chip></KV>
            </section>
            <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 10 }}>
              <h2 className="h2">অ্যাকাউন্ট নিয়ন্ত্রণ</h2>
              <ActionButton className="btn r" confirm={{ title: `${s.name}-কে স্থগিত করবেন?`, message: "স্থগিত থাকলে সেলার লগইন বা বিক্রি করতে পারবেন না। লেনদেনের ইতিহাস যেমন আছে তেমন থাকবে।", label: "স্থগিত করুন", danger: true }}>
                {s.status === "suspended" ? "আবার চালু করুন" : "সেলার স্থগিত করুন"}
              </ActionButton>
              <ActionButton className="btn g" confirm={{ title: "সব ডিভাইস থেকে লগআউট?", message: "সেলারকে আবার লগইন করতে হবে।", label: "লগআউট করান" }}>সব ডিভাইস থেকে লগআউট করান</ActionButton>
              <ActionButton className="btn g">লগইন রিসেটের লিংক পাঠান</ActionButton>
              <div className="mu" style={{ lineHeight: 1.55 }}>লেনদেন আছে এমন সেলারকে মুছে ফেলা যায় না — শুধু নিষ্ক্রিয় বা স্থগিত করা যায়।</div>
            </section>
          </div>
        </div>
      </main>
    </>
  );
}
