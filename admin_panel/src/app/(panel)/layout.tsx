import { Suspense } from "react";
import { BottomNav, Sidebar } from "@/components/shell/Navigation";

export default function PanelLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="app">
      <aside className="side">
        {/* The active menu item depends on the URL, so it streams in on dynamic routes. */}
        <Suspense fallback={<div className="sb" />}>
          <Sidebar />
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
