import { Suspense } from "react";
import { LoadError, Skeleton } from "@/components/shell/LoadState";
import { Topbar } from "@/components/shell/Topbar";
import { api, load } from "@/lib/api/server";
import type { ApiCategory, ApiProduct } from "@/lib/api/types";
import { ProductForm } from "./ProductForm";

export const metadata = { title: "পণ্য যোগ / সম্পাদনা" };

export default function NewProductPage(props: PageProps<"/products/new">) {
  return (
    <>
      <Topbar title="পণ্য যোগ / সম্পাদনা" back="/products" crumb={{ href: "/products", label: "পণ্য" }} />
      <main className="ct">
        <Suspense fallback={<Skeleton rows={8} />}>
          <FormData searchParams={props.searchParams} />
        </Suspense>
      </main>
    </>
  );
}

async function FormData({ searchParams }: { searchParams: Promise<Record<string, string | string[] | undefined>> }) {
  const id = (await searchParams).id;
  const r = await load(() =>
    Promise.all([
      api.get<ApiCategory[]>("/admin/categories"),
      typeof id === "string" ? api.get<ApiProduct>(`/admin/products/${encodeURIComponent(id)}`) : Promise.resolve(null),
    ]),
  );
  if (r.error !== undefined) return <LoadError message={r.error} retryHref="/products" />;
  const [categories, product] = r.data;
  return <ProductForm categories={categories.filter((c) => !c.archived || c.id === product?.category_id)} product={product} key={product?.id ?? "new"} />;
}
