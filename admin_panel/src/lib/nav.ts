import type { IconName } from "@/components/ui/Icon";

export interface NavItem {
  href: string;
  label: string;
  icon: IconName;
}

export interface NavGroup {
  id: string;
  title: string;
  icon: IconName;
  items: NavItem[];
}

/** Always visible at the top of the sidebar. */
export const sidebarTop: NavItem[] = [{ href: "/dashboard", label: "ড্যাশবোর্ড", icon: "dash" }];

/**
 * Collapsible categories (desktop sidebar and the mobile "আরও" page).
 * Badge counts come live from /api/nav-counts.
 */
export const sidebar: NavGroup[] = [
  { id: "sales", title: "বিক্রি ও হিসাব", icon: "receipt", items: [
    { href: "/sales", label: "বিক্রি মনিটর", icon: "receipt" },
    { href: "/corrections", label: "সংশোধনের অনুরোধ", icon: "edit" },
    { href: "/settlements", label: "দিনের হিসাব", icon: "cal" },
  ] },
  { id: "sellers", title: "সেলার", icon: "users", items: [
    { href: "/applications", label: "সেলার আবেদন", icon: "doc" },
    { href: "/sellers", label: "সব সেলার", icon: "users" },
    { href: "/compensation", label: "কমিশন ও আয়", icon: "trend" },
  ] },
  { id: "stock", title: "পণ্য ও স্টক", icon: "box", items: [
    { href: "/products", label: "পণ্য ও ক্যাটাগরি", icon: "tag" },
    { href: "/inventory", label: "মূল স্টক", icon: "box" },
    { href: "/assignments", label: "স্টক বরাদ্দ", icon: "truck" },
    { href: "/returns", label: "ফেরত ও ক্ষতি", icon: "ret" },
  ] },
  { id: "money", title: "টাকা", icon: "wallet", items: [
    { href: "/cash", label: "ক্যাশ জমা", icon: "cash" },
    { href: "/payouts", label: "সেলার পেমেন্ট", icon: "wallet" },
    { href: "/expenses", label: "খরচ", icon: "chart" },
  ] },
  { id: "investors", title: "বিনিয়োগকারী", icon: "shield", items: [
    { href: "/investors", label: "বিনিয়োগকারী", icon: "shield" },
    { href: "/investments", label: "বিনিয়োগ ও পুঁজি", icon: "wallet" },
    { href: "/investor-profit", label: "লাভ বিতরণ", icon: "trend" },
    { href: "/investor-withdrawals", label: "মূলধন ফেরত", icon: "ret" },
  ] },
  { id: "comms", title: "যোগাযোগ", icon: "chat", items: [
    { href: "/support", label: "সাপোর্ট চ্যাট", icon: "chat" },
    { href: "/messages", label: "বার্তা পাঠান", icon: "bell" },
    { href: "/activity", label: "নোটিফিকেশন ও লগ", icon: "history" },
  ] },
];

/** Always visible at the bottom of the menu. */
export const sidebarBottom: NavItem[] = [
  { href: "/reports", label: "রিপোর্ট", icon: "trend" },
  { href: "/settings", label: "সেটিংস", icon: "gear" },
];

/** Bottom navigation (mobile). */
export const bottomNav: NavItem[] = [
  { href: "/dashboard", label: "ড্যাশবোর্ড", icon: "dash" },
  { href: "/sales", label: "বিক্রি", icon: "receipt" },
  { href: "/inventory", label: "স্টক", icon: "box" },
  { href: "/sellers", label: "সেলার", icon: "users" },
  { href: "/more", label: "আরও", icon: "grid" },
];
