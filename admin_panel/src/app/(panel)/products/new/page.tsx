import { Topbar } from "@/components/shell/Topbar";
import { ProductForm } from "./ProductForm";

export const metadata = { title: "পণ্য যোগ / সম্পাদনা" };

export default function ProductFormPage() {
  return (
    <>
      <Topbar title="পণ্য যোগ / সম্পাদনা" back="/products" crumb={{ href: "/products", label: "পণ্য" }} />
      <main className="ct">
        <ProductForm />
      </main>
    </>
  );
}
