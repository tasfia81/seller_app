import { Suspense } from "react";
import { parsePeriod } from "@/components/dashboard/DateFilter";
import { LoadError, Skeleton } from "@/components/shell/LoadState";
import { Topbar } from "@/components/shell/Topbar";
import { api, load } from "@/lib/api/server";
import type { ApiSale, ApiSalesList, ApiSellerRow } from "@/lib/api/types";
import { SalesMonitor } from "./SalesMonitor";

export const metadata = { title: "বিক্রি মনিটর" };

export default function SalesPage(props: PageProps<"/sales">) {
  return (
    <>
      <Topbar title="বিক্রি মনিটর" />
      <main className="ct">
        <Suspense fallback={<Skeleton rows={6} />}>
          <SalesData searchParams={props.searchParams} />
        </Suspense>
      </main>
    </>
  );
}

const str = (v: string | string[] | undefined) => (typeof v === "string" ? v : "");

async function SalesData({ searchParams }: { searchParams: Promise<Record<string, string | string[] | undefined>> }) {
  const sp = await searchParams;
  const period = parsePeriod(sp.period);
  const seller = str(sp.seller);
  const payment = str(sp.payment);
  const q = new URLSearchParams({ period });
  if (seller) q.set("seller_id", seller);
  if (payment) q.set("payment", payment);
  const r = await load(async () => {
    const [list, sellers] = await Promise.all([api.get<ApiSalesList>(`/admin/sales?${q}`), api.get<ApiSellerRow[]>("/admin/sellers")]);
    const id = str(sp.id) && list.items.some((s) => s.id === sp.id) ? str(sp.id) : list.items[0]?.id;
    const selected = id ? await api.get<ApiSale>(`/admin/sales/${encodeURIComponent(id)}`) : null;
    return { list, sellers, selected };
  });
  if (r.error !== undefined) return <LoadError message={r.error} retryHref="/sales" />;
  return (
<SalesMonitor period={period} seller={seller} payment={payment} list={r.data.list} sellers={r.data.sellers} selected={r.data.selected} />
  );
}
