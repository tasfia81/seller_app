import Link from "next/link";
import { Topbar } from "@/components/shell/Topbar";
import { Kpi, Note } from "@/components/ui/bits";
import { api, load } from "@/lib/api/server";
import { bnDigits, money } from "@/lib/format";

export const metadata = { title: "বিনিয়োগকারী" };

type Investor = { id: string; name: string; code: string; mobile_masked: string; status_label: string;
  active_capital: number; in_stock: number; uninvested: number; profit_total: number };

export default async function InvestorsPage({ searchParams }: { searchParams: Promise<{ q?: string }> }) {
  const { q } = await searchParams;
  const result = await load(() => api.get<Investor[]>(`/admin/investors?q=${encodeURIComponent(q ?? "")}`));
  const rows = result.data ?? [];
  return <>
    <Topbar title="বিনিয়োগকারী"><Link className="btn o" href="/investments">বিনিয়োগ রেকর্ড</Link></Topbar>
    <main className="ct">
      <form method="get" className="fg"><input className="in" name="q" defaultValue={q} placeholder="নাম বা কোড" />
        <button className="btn o">খুঁজুন</button></form>
      <Link className="btn o" href="/investors/applications">আবেদন যাচাই</Link>
      {result.error ? <Note kind="warn">{result.error}</Note> : <>
        <div className="kpis">
          <Kpi label="বিনিয়োগকারী" value={bnDigits(rows.length)} />
          <Kpi label="সক্রিয় মূলধন" value={money(rows.reduce((sum, row) => sum + row.active_capital, 0))} />
          <Kpi label="স্টকে খাটছে" value={money(rows.reduce((sum, row) => sum + row.in_stock, 0))} />
        </div>
        <div className="cd"><table className="tbl"><thead><tr><th>বিনিয়োগকারী</th><th>অবস্থা</th><th>মূলধন</th><th>লাভ</th></tr></thead>
          <tbody>{rows.map((row) => <tr key={row.id}><td><Link href={`/investors/${encodeURIComponent(row.id)}`}>{row.name} · {row.code}</Link><div className="mu">{row.mobile_masked}</div></td>
            <td>{row.status_label}</td><td>{money(row.active_capital)}</td><td>{money(row.profit_total)}</td></tr>)}</tbody></table>
          {!rows.length ? <Note>কোনো বিনিয়োগকারী পাওয়া যায়নি।</Note> : null}
        </div>
      </>}
    </main>
  </>;
}
