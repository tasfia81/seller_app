import Link from "next/link";
import { Suspense } from "react";
import { LoadError, Skeleton } from "@/components/shell/LoadState";
import { Topbar } from "@/components/shell/Topbar";
import { Icon } from "@/components/ui/Icon";
import { api, load } from "@/lib/api/server";
import type { ApiCategory, ApiProduct } from "@/lib/api/types";
import { ProductsView } from "./ProductsView";

export const metadata = { title: "পণ্য ও ক্যাটাগরি" };

export default function ProductsPage() {
  return (
    <>
      <Topbar title="পণ্য ও ক্যাটাগরি">
        <Link className="btn" href="/products/new"><Icon name="plus" size={18} />নতুন পণ্য</Link>
      </Topbar>
      <main className="ct">
        <Suspense fallback={<Skeleton rows={6} />}>
          <ProductsData />
        </Suspense>
      </main>
    </>
  );
}

async function ProductsData() {
  const r = await load(() => Promise.all([api.get<ApiProduct[]>("/admin/products"), api.get<ApiCategory[]>("/admin/categories")]));
  if (r.error !== undefined) return <LoadError message={r.error} retryHref="/products" />;
  return <ProductsView items={r.data[0]} categories={r.data[1]} />;
}
