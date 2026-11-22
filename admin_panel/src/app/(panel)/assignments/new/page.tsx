import { Suspense } from "react";
import { LoadError, Skeleton } from "@/components/shell/LoadState";
import { Topbar } from "@/components/shell/Topbar";
import { api, load } from "@/lib/api/server";
import type { ApiInventory, ApiProduct, ApiSellerRow } from "@/lib/api/types";
import { AssignWizard } from "./AssignWizard";

export const metadata = { title: "সেলারকে স্টক দেওয়া" };

export default function NewAssignmentPage() {
  return (
    <>
      <Topbar title="সেলারকে স্টক দেওয়া" back="/assignments" crumb={{ href: "/assignments", label: "স্টক বরাদ্দ" }} />
      <main className="ct">
        <Suspense fallback={<Skeleton rows={8} />}>
          <WizardData />
        </Suspense>
      </main>
    </>
  );
}

async function WizardData() {
  const r = await load(() => Promise.all([api.get<ApiSellerRow[]>("/admin/sellers"), api.get<ApiProduct[]>("/admin/products"), api.get<ApiInventory>("/admin/inventory")]));
  if (r.error !== undefined) return <LoadError message={r.error} retryHref="/assignments/new" />;
  const [sellers, products, inv] = r.data;
  const stock: Record<string, number> = {};
  for (const p of inv.products) for (const v of p.by_variant) stock[`${p.product_id}|${v.variant ?? ""}`] = v.warehouse;
  return <AssignWizard sellers={sellers.filter((s) => s.status === "active")} products={products.filter((p) => p.active)} stock={stock} />;
}
