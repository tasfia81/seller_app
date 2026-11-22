import Link from "next/link";
import { Topbar } from "@/components/shell/Topbar";
import { Icon } from "@/components/ui/Icon";
import { Avatar } from "@/components/ui/bits";

export const metadata = { title: "স্টক বরাদ্দ" };

const ROWS = [
  { id: "2104", label: "বর-২১০৪", seller: "রাকিব হাসান", date: "আজ ০৮:১০", items: "৪০ পিস · ৩ পণ্য", status: ["চালু", "ok"] },
  { id: "2105", label: "বর-২১০৫", seller: "নুসরাত জাহান", date: "আজ ০৮:২০", items: "২০ পিস · ২ পণ্য", status: ["হস্তান্তর বাকি", "wa"] },
  { id: "2106", label: "বর-২১০৬", seller: "সাকিব হোসেন", date: "আজ ০৮:৩৫", items: "১৫ পিস · ১ পণ্য", status: ["গ্রহণের অপেক্ষায়", "inf"] },
  { id: "2098", label: "বর-২০৯৮", seller: "মিম আক্তার", date: "গতকাল", items: "৩০ পিস · ৩ পণ্য", status: ["আংশিক ফেরত", "wa"] },
  { id: "2090", label: "বর-২০৯০", seller: "রাকিব হাসান", date: "২০ নভেম্বর", items: "৩৫ পিস · ৩ পণ্য", status: ["বন্ধ", "nu"] },
];

export default function AssignmentsPage() {
  return (
    <>
      <Topbar title="স্টক বরাদ্দ">
        <Link className="btn" href="/assignments/new"><Icon name="plus" size={18} />নতুন বরাদ্দ</Link>
      </Topbar>
      <main className="ct">
        <div className="tw">
          <table style={{ minWidth: 680 }}>
            <thead><tr><th>বরাদ্দ</th><th>সেলার</th><th>তারিখ</th><th>পণ্য</th><th>অবস্থা</th><th /></tr></thead>
            <tbody>
              {ROWS.map((r) => (
                <tr key={r.id}>
                  <td><b style={{ fontWeight: 600 }}>#{r.label}</b></td>
                  <td><div className="sl"><Avatar name={r.seller} /><b>{r.seller}</b></div></td>
                  <td>{r.date}</td>
                  <td>{r.items}</td>
                  <td><span className={`ch ${r.status[1]}`}>{r.status[0]}</span></td>
                  <td className="n"><Link className="btn g sm" href={`/assignments/${r.id}`}>বিস্তারিত</Link></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="mu">সেলার অ্যাপে “পেয়েছি” চাপার পরই বরাদ্দ “চালু” হয় — তার আগে স্টক সেলারের নামে যায় না।</div>
      </main>
    </>
  );
}
