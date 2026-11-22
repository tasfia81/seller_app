import Link from "next/link";
import { EmptyState } from "@/components/ui/bits";

export const metadata = { title: "পেজ পাওয়া যায়নি" };

/** Unknown addresses inside the panel keep the menu visible. */
export default function NotFoundInPanel() {
  return (
    <>
      <header className="tb">
        <h1>পেজ পাওয়া যায়নি</h1>
      </header>
      <main className="ct">
        <div className="cd">
          <EmptyState icon="alert" title="এই ঠিকানায় কোনো পেজ নেই" text="বাম পাশের মেনু (মোবাইলে নিচের মেনু) থেকে পেজ বাছুন।" />
          <div style={{ display: "flex", justifyContent: "center", paddingBottom: 16 }}>
            <Link className="btn" href="/dashboard">ড্যাশবোর্ডে ফিরে যান</Link>
          </div>
        </div>
      </main>
    </>
  );
}
