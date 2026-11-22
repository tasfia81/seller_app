import Link from "next/link";
import { Topbar } from "@/components/shell/Topbar";
import { Avatar } from "@/components/ui/bits";
import { bnDigits, money } from "@/lib/format";

export const metadata = { title: "পারফরম্যান্স রিপোর্ট" };

const SELLERS = [
  ["nusrat", "নুসরাত জাহান", 212400, 482, 51200, 14200, 0, ["সব বন্ধ", "ok"]],
  ["rakib", "রাকিব হাসান", 184200, 412, 44960, 12480, 3200, ["সব বন্ধ", "ok"]],
  ["sakib", "সাকিব হোসেন", 156800, 395, 36400, 9875, 4900, ["১টি গরমিল", "er"]],
  ["mim", "মিম আক্তার", 121300, 308, 28100, 9000, 2100, ["১টি যাচাই বাকি", "wa"]],
] as const;
const PRODUCTS = [
  ["জার্সি — বাংলাদেশ", 984, 442800, 344400, 148],
  ["পোলো টি-শার্ট", 612, 232560, 159120, 98],
  ["জগার প্যান্ট", 244, 134200, 95000, 68],
  ["বেসিক টি-শার্ট (সাদা)", 286, 71500, 62340, 220],
] as const;

export default function PerformancePage() {
  return (
    <>
      <Topbar title="সেলার ও পণ্যের পারফরম্যান্স" back="/reports" />
      <main className="ct">
        <section>
          <h2 className="h2" style={{ marginBottom: 10 }}>সেলারের পারফরম্যান্স · নভেম্বর ২০২৬</h2>
          <div className="tw">
            <table style={{ minWidth: 820 }}>
              <thead><tr><th>সেলার</th><th className="n">মোট বিক্রি</th><th className="n">বিক্রিত পণ্য</th><th className="n">মোট লাভ</th><th className="n">সেলারের আয়</th><th className="n">বাকি ক্যাশ</th><th>দিনের হিসাব</th></tr></thead>
              <tbody>
                {SELLERS.map(([id, name, sales, qty, profit, earn, due, st]) => (
                  <tr key={id}>
                    <td><Link className="sl" href={`/sellers/${id}`}><Avatar name={name} /><b>{name}</b></Link></td>
                    <td className="n"><b>{money(sales)}</b></td><td className="n">{bnDigits(qty)}</td><td className="n">{money(profit)}</td><td className="n">{money(earn)}</td>
                    <td className="n" style={due ? { color: "#85560C" } : undefined}>{money(due)}</td>
                    <td><span className={`ch ${st[1]}`}>{st[0]}</span></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
        <section>
          <h2 className="h2" style={{ marginBottom: 10 }}>পণ্যের পারফরম্যান্স</h2>
          <div className="tw">
            <table style={{ minWidth: 820 }}>
              <thead><tr><th>পণ্য</th><th className="n">বিক্রিত</th><th className="n">বিক্রি</th><th className="n">বিক্রিত পণ্যের ক্রয়মূল্য</th><th className="n">মোট লাভ</th><th className="n">মার্জিন</th><th className="n">বাকি স্টক</th></tr></thead>
              <tbody>
                {PRODUCTS.map(([name, qty, rev, cogs, left]) => (
                  <tr key={name}>
                    <td><b style={{ fontWeight: 600 }}>{name}</b></td><td className="n">{bnDigits(qty)}</td><td className="n">{money(rev)}</td><td className="n">{money(cogs)}</td>
                    <td className="n"><b>{money(rev - cogs)}</b></td><td className="n">{bnDigits(Math.round(((rev - cogs) / rev) * 100))}%</td><td className="n">{bnDigits(left)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      </main>
    </>
  );
}
