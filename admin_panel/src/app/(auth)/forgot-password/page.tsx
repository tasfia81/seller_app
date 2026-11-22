import Link from "next/link";
import { Icon } from "@/components/ui/Icon";
import { ForgotFlow } from "./ForgotFlow";

export const metadata = { title: "পাসওয়ার্ড পুনরুদ্ধার" };

export default function ForgotPasswordPage() {
  return (
    <div style={{ minHeight: "100vh", display: "flex", justifyContent: "center", padding: "64px 16px" }}>
      <div className="cd" style={{ width: "100%", maxWidth: 460, padding: 28, display: "flex", flexDirection: "column", gap: 18, alignSelf: "flex-start" }}>
        <Link href="/login" style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 14, fontWeight: 600, textDecoration: "none", minHeight: 44 }}>
          <Icon name="back" size={18} />
          লগইনে ফিরে যান
        </Link>
        <ForgotFlow />
      </div>
    </div>
  );
}
