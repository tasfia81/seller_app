import { Suspense } from "react";
import { PageLoading } from "@/components/shell/PageLoading";
import { Topbar } from "@/components/shell/Topbar";
import { Avatar, Kpi, Note } from "@/components/ui/bits";
import { ActionButton, Pills } from "@/components/ui/feedback";
import { bnDigits } from "@/lib/format";

export function generateStaticParams() {
  return ["2104", "2105", "2106", "2098", "2090"].map((id) => ({ id }));
}

const ITEMS = [
  { name: "জার্সি — বাংলাদেশ", v: "L", given: 20, sold: 12, ret: 0, rule: "নির্ধারিত ৳৪৫০" },
  { name: "পোলো টি-শার্ট", v: "XL", given: 10, sold: 6, ret: 2, rule: "৳৩৫০–৪২০" },
  { name: "বেসিক টি-শার্ট (সাদা)", v: "M", given: 10, sold: 5, ret: 0, rule: "নির্ধারিত ৳২৫০" },
];

export default function AssignmentDetailPage(props: PageProps<"/assignments/[id]">) {
  return (
    <Suspense fallback={<PageLoading title="বরাদ্দ" />}>
      <AssignmentDetail params={props.params} />
    </Suspense>
  );
}

async function AssignmentDetail({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const given = ITEMS.reduce((a, i) => a + i.given, 0);
  const sold = ITEMS.reduce((a, i) => a + i.sold, 0);
  const ret = ITEMS.reduce((a, i) => a + i.ret, 0);

  return (
    <>
      <Topbar title={`বরাদ্দ #বর-${bnDigits(id)}`} back="/assignments" crumb={{ href: "/assignments", label: "স্টক বরাদ্দ" }} />
      <main className="ct">
        <section className="cd" style={{ display: "flex", gap: 16, alignItems: "center", flexWrap: "wrap" }}>
          <div className="sl fx" style={{ minWidth: 220 }}>
            <Avatar name="রাকিব হাসান" size={48} />
            <div><b style={{ fontSize: 17 }}>রাকিব হাসান</b><span className="mu">দেওয়া হয়েছে: আজ সকাল ৮:১০ · তানভীর</span></div>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 6, flexWrap: "wrap", fontSize: 12.5 }} aria-label="অবস্থার ধাপ">
            <span className="ch nu">খসড়া</span>→<span className="ch nu">হস্তান্তর বাকি</span>→<span className="ch nu">সেলার গ্রহণ ৮:২৫</span>→<span className="ch ok">চালু</span>
          </div>
        </section>
        <div className="kpis">
          <Kpi label="দেওয়া" value={`${bnDigits(given)} পিস`} />
          <Kpi label="বিক্রি" value={`${bnDigits(sold)} পিস`} />
          <Kpi label="ফেরত" value={`${bnDigits(ret)} পিস`} />
          <Kpi label="সেলারের হাতে বাকি" value={`${bnDigits(given - sold - ret)} পিস`} tone="good" />
        </div>
        <div className="two">
          <div className="a">
            <div className="tw">
              <table style={{ minWidth: 640 }}>
                <thead><tr><th>পণ্য</th><th>ধরন</th><th className="n">দেওয়া</th><th className="n">বিক্রি</th><th className="n">ফেরত</th><th className="n">বাকি</th><th>দামের নিয়ম</th></tr></thead>
                <tbody>
                  {ITEMS.map((i) => (
                    <tr key={i.name}><td><b style={{ fontWeight: 600 }}>{i.name}</b></td><td>{i.v}</td><td className="n">{bnDigits(i.given)}</td><td className="n">{bnDigits(i.sold)}</td><td className="n">{bnDigits(i.ret)}</td><td className="n"><b>{bnDigits(i.given - i.sold - i.ret)}</b></td><td>{i.rule}</td></tr>
                  ))}
                </tbody>
              </table>
            </div>
            <section className="cd">
              <h2 className="h2" style={{ marginBottom: 4 }}>এই বরাদ্দের ইতিহাস</h2>
              <div className="tl"><i style={{ background: "#3B82F6" }} /><div><div className="t1">২ পিস পোলো টি-শার্ট ফেরতের অনুরোধ</div><div className="mu">আজ ১১:০৫ · রাকিব · অপেক্ষমাণ</div></div></div>
              <div className="tl"><i style={{ background: "#168447" }} /><div><div className="t1">সেলার স্টক বুঝে নিয়েছেন</div><div className="mu">আজ ৮:২৫ · রাকিব</div></div></div>
              <div className="tl"><i style={{ background: "#A9D6BB" }} /><div><div className="t1">বরাদ্দ তৈরি · {bnDigits(given)} পিস</div><div className="mu">আজ ৮:১০ · তানভীর</div></div></div>
            </section>
            <div className="actions">
              <ActionButton className="btn o">বরাদ্দ ঠিক করুন</ActionButton>
              <ActionButton className="btn r" confirm={{ title: "বরাদ্দ বন্ধ করবেন?", message: "বন্ধের আগে সেলারের হাতে থাকা সব পণ্য ফেরত বা হস্তান্তর করতে হবে।", label: "বন্ধ করুন", danger: true }}>বরাদ্দ বন্ধ করুন</ActionButton>
            </div>
          </div>
          <div className="b">
            <section className="drawer">
              <h2 className="h2">স্টক ফেরত বা হস্তান্তর</h2>
              <Pills label="ধরন" options={["গুদামে ফেরত", "অন্য সেলারকে", "ক্ষতি"]} variant="select" />
              <div className="f"><label htmlFor="p">পণ্য</label><select id="p" className="in"><option>জার্সি — বাংলাদেশ (L) · ৮ বাকি</option><option>পোলো টি-শার্ট (XL) · ২ বাকি</option></select></div>
              <div className="f"><label htmlFor="q">পরিমাণ</label><input id="q" className="in" defaultValue="৮" /></div>
              <div className="f"><label htmlFor="r">কারণ <i>*</i></label><select id="r" className="in"><option>দিন শেষের ফেরত</option><option>অ্যাডমিন ফেরত ডাকছেন</option><option>অন্য এলাকায় বেশি চাহিদা</option></select></div>
              <Note>গুদামে হাতে পাওয়ার পর “পেয়েছি” নিশ্চিত করলে তবেই স্টক গুদামে যোগ হবে। প্রতিটি আসা-যাওয়া লগে থাকে।</Note>
              <ActionButton className="btn full">ফেরত শুরু করুন</ActionButton>
            </section>
          </div>
        </div>
      </main>
    </>
  );
}
