import type { IconName } from "@/components/ui/Icon";

export interface NavItem {
  href: string;
  label: string;
  icon: IconName;
}

/** Full sidebar menu (desktop). Badge counts come live from /api/nav-counts. */
export const sidebar: { title: string; items: NavItem[] }[] = [
  { title: "প্রধান", items: [
    { href: "/dashboard", label: "ড্যাশবোর্ড", icon: "dash" },
    { href: "/sales", label: "বিক্রি", icon: "receipt" },
    { href: "/corrections", label: "সংশোধনের অনুরোধ", icon: "edit" },
  ] },
  { title: "সেলার", items: [
    { href: "/applications", label: "সেলার আবেদন", icon: "doc" },
    { href: "/sellers", label: "সেলার", icon: "users" },
    { href: "/compensation", label: "কমিশন ও আয়", icon: "trend" },
  ] },
  { title: "পণ্য ও স্টক", items: [
    { href: "/products", label: "পণ্য ও ক্যাটাগরি", icon: "tag" },
    { href: "/inventory", label: "মূল স্টক", icon: "box" },
    { href: "/assignments", label: "স্টক বরাদ্দ", icon: "truck" },
    { href: "/returns", label: "ফেরত ও ক্ষতি", icon: "ret" },
  ] },
  { title: "টাকা", items: [
    { href: "/cash", label: "ক্যাশ জমা", icon: "cash" },
    { href: "/payouts", label: "সেলার পেমেন্ট", icon: "wallet" },
    { href: "/settlements", label: "দিনের হিসাব", icon: "cal" },
    { href: "/expenses", label: "খরচ", icon: "chart" },
  ] },
  { title: "বিনিয়োগকারী", items: [
    { href: "/investors", label: "বিনিয়োগকারী", icon: "shield" },
    { href: "/investments", label: "বিনিয়োগ ও পুঁজি", icon: "wallet" },
    { href: "/investor-profit", label: "লাভ বিতরণ", icon: "trend" },
    { href: "/investor-withdrawals", label: "মূলধন ফেরত", icon: "ret" },
  ] },
  { title: "বিশ্লেষণ", items: [
    { href: "/reports", label: "রিপোর্ট", icon: "trend" },
    { href: "/messages", label: "বার্তা পাঠান", icon: "bell" },
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
