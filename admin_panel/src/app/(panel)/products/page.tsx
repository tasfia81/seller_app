import Link from "next/link";
import { Topbar } from "@/components/shell/Topbar";
import { Icon } from "@/components/ui/Icon";
import { categories, products } from "@/lib/demo-data";
import { ProductsView } from "./ProductsView";

export const metadata = { title: "পণ্য ও ক্যাটাগরি" };

export default function ProductsPage() {
  return (
    <>
      <Topbar title="পণ্য ও ক্যাটাগরি">
        <Link className="btn" href="/products/new"><Icon name="plus" size={18} />নতুন পণ্য</Link>
      </Topbar>
      <main className="ct">
        <ProductsView items={products} categories={categories} />
      </main>
    </>
  );
}
