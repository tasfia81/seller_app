import { Topbar } from "@/components/shell/Topbar";
import { investorApplications } from "@/lib/investors";
import { InvestorApplicationsView } from "./InvestorApplicationsView";

export const metadata = { title: "বিনিয়োগকারীর আবেদন" };

export default function InvestorApplicationsPage() {
  return (
    <>
      <Topbar title="আবেদন যাচাই" back="/investors" crumb={{ href: "/investors", label: "বিনিয়োগকারী" }} />
      <main className="ct">
        <InvestorApplicationsView items={investorApplications} />
      </main>
    </>
  );
}
