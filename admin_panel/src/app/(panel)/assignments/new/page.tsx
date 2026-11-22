import { Topbar } from "@/components/shell/Topbar";
import { AssignWizard } from "./AssignWizard";

export const metadata = { title: "সেলারকে স্টক দেওয়া" };

export default function NewAssignmentPage() {
  return (
    <>
      <Topbar title="সেলারকে স্টক দেওয়া" back="/assignments" />
      <main className="ct">
        <AssignWizard />
      </main>
    </>
  );
}
