import { Suspense } from "react";
import { AdminBadge, AdminBadgeFallback } from "@/components/shell/AdminBadge";
import { BottomNav, Sidebar } from "@/components/shell/Navigation";

export default function PanelLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="app">
      <aside className="side">
        {/* The active menu item depends on the URL, so it streams in on dynamic routes. */}
        <Suspense fallback={<div className="sb" />}>
          <Sidebar
            footer={
              <Suspense fallback={<AdminBadgeFallback />}>
                <AdminBadge />
              </Suspense>
            }
          />
        </Suspense>
      </aside>
      <div className="main">
        {children}
        <div className="bnav">
          <Suspense fallback={<div className="bn" />}>
            <BottomNav />
          </Suspense>
        </div>
      </div>
    </div>
  );
}
