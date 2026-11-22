import type { Metadata, Viewport } from "next";
import { Noto_Sans_Bengali } from "next/font/google";
import { ToastProvider } from "@/components/ui/feedback";
import "./globals.css";

const bengali = Noto_Sans_Bengali({
  subsets: ["bengali", "latin"],
  weight: ["400", "500", "600", "700"],
  variable: "--font-bn",
  display: "swap",
});

export const metadata: Metadata = {
  title: { default: "স্ট্রিট সেলস অ্যাডমিন", template: "%s · স্ট্রিট সেলস অ্যাডমিন" },
  description: "স্ট্রিট সেলস ব্যবসার অ্যাডমিন প্যানেল",
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  themeColor: "#0B3D2E",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="bn" className={bengali.variable}>
      <body>
        <ToastProvider>{children}</ToastProvider>
      </body>
    </html>
  );
}
