import type { IconName } from "@/components/ui/Icon";

export interface NavItem {
  href: string;
  label: string;
  icon: IconName;
  badge?: string;
}

/** Full sidebar menu (desktop). Only the dashboard is built in this phase. */
export const sidebar: { title: string; items: NavItem[] }[] = [
  { title: "প্রধান", items: [
    { href: "/dashboard", label: "ড্যাশবোর্ড", icon: "dash" },
    { href: "/sales", label: "বিক্রি", icon: "receipt" },
    { href: "/corrections", label: "সংশোধনের অনুরোধ", icon: "edit", badge: "২" },
  ] },
  { title: "সেলার", items: [
    { href: "/applications", label: "সেলার আবেদন", icon: "doc", badge: "৪" },
    { href: "/sellers", label: "সেলার", icon: "users" },
    { href: "/compensation", label: "কমিশন ও আয়", icon: "trend" },
  ] },
  { title: "পণ্য ও স্টক", items: [
    { href: "/products", label: "পণ্য ও ক্যাটাগরি", icon: "tag" },
    { href: "/inventory", label: "মূল স্টক", icon: "box" },
    { href: "/assignments", label: "স্টক বরাদ্দ", icon: "truck" },
    { href: "/returns", label: "ফেরত ও ক্ষতি", icon: "ret", badge: "৩" },
  ] },
  { title: "টাকা", items: [
    { href: "/cash", label: "ক্যাশ জমা", icon: "cash", badge: "৬" },
    { href: "/payouts", label: "সেলার পেমেন্ট", icon: "wallet" },
    { href: "/settlements", label: "দিনের হিসাব", icon: "cal" },
    { href: "/expenses", label: "খরচ", icon: "chart" },
  ] },
  { title: "বিশ্লেষণ", items: [
    { href: "/reports", label: "রিপোর্ট", icon: "trend" },
    { href: "/activity", label: "নোটিফিকেশন ও লগ", icon: "history" },
    { href: "/settings", label: "সেটিংস", icon: "gear" },
  ] },
];

/** Bottom navigation (mobile). */
export const bottomNav: NavItem[] = [
  { href: "/dashboard", label: "ড্যাশবোর্ড", icon: "dash" },
  { href: "/sales", label: "বিক্রি", icon: "receipt" },
  { href: "/inventory", label: "স্টক", icon: "box" },
  { href: "/sellers", label: "সেলার", icon: "users" },
  { href: "/more", label: "আরও", icon: "grid" },
];
