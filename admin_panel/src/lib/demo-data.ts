/**
 * DEMO DATA — UI preview only.
 *
 * Every page reads from here until the FastAPI backend exists. Nothing here is
 * real: no real people, NID numbers or transactions. Replace these exports with
 * API calls in `src/lib/api/*` when the backend is ready, and delete this file.
 */
import type { Application, CashHandover, Product, Sale, Seller } from "./types";

export const DEMO_MODE = true;

export const sellers: Seller[] = [
  { id: "rakib", name: "রাকিব হাসান", mobile: "০১৭১২-৩৪৫৬৭৮", status: "active", compensation: "লাভের ৪০%", model: "profit", policy: "dailyReturn", todaySales: 8650, todayItems: 23, cashDue: 3200, trend: 18, monthSales: 184200, assigned: 40, available: 17, payable: 2620 },
  { id: "nusrat", name: "নুসরাত জাহান", mobile: "০১৮১৯-২২৩৩৪৪", status: "active", compensation: "দৈনিক ৳৫০০ + পিসে ৳১০", model: "hybrid", policy: "carryForward", todaySales: 7280, todayItems: 19, cashDue: 0, trend: 6, monthSales: 212400, assigned: 45, available: 12, payable: 4200 },
  { id: "sakib", name: "সাকিব হোসেন", mobile: "০১৯১১-৫৫৬৬৭৭", status: "active", compensation: "প্রতি পিসে ৳২৫", model: "perUnit", policy: "dailyReturn", todaySales: 6100, todayItems: 15, cashDue: 4900, trend: -9, monthSales: 156800, assigned: 23, available: 5, payable: 0 },
  { id: "mim", name: "মিম আক্তার", mobile: "০১৬১২-৮৮৯৯০০", status: "active", compensation: "দৈনিক ৳৪৫০", model: "daily", policy: "dailyReturn", todaySales: 5430, todayItems: 14, cashDue: 2100, trend: 0, monthSales: 121300, assigned: 30, available: 8, payable: 1800 },
  { id: "jahid", name: "জাহিদ হাসান", mobile: "০১৫১১-৩৩৪৪৫৫", status: "inactive", compensation: "লাভের ৪০%", model: "profit", policy: "carryForward", todaySales: 0, todayItems: 0, cashDue: 0, trend: 0, monthSales: 0, assigned: 0, available: 0, payable: 0 },
  { id: "shahriar", name: "শাহরিয়ার কবির", mobile: "০১৭৮৮-১২১২১২", status: "suspended", compensation: "লাভের ৫০%", model: "profit", policy: "dailyReturn", todaySales: 0, todayItems: 0, cashDue: 1450, trend: 0, monthSales: 18400, assigned: 0, available: 0, payable: 0 },
];

export const applications: Application[] = [
  { id: "আবে-০০৫২", name: "ফাহিম রহমান", mobile: "০১৮১২-৪৪৫৫৬৬", submitted: "আজ ০৯:১৫", status: "pending", dob: "১২ মার্চ ২০০৩ (২৩ বছর)", gender: "পুরুষ", guardian: "আব্দুর রহমান", presentAddress: "মোহাম্মদপুর, ঢাকা", permanentAddress: "সদর, কুমিল্লা", nidLast4: "৭৭৩১", emergency: { name: "রোকেয়া বেগম", relation: "মা", mobile: "০১৭১১-৯৯৮৮৭৭" }, backImageFailed: true },
  { id: "আবে-০০৫১", name: "তাসলিমা খাতুন", mobile: "০১৭১৫-২২৩৩৪৪", submitted: "আজ ০৮:৪০", status: "pending", dob: "৪ জুন ২০০২ (২৪ বছর)", gender: "নারী", presentAddress: "উত্তরা, ঢাকা", permanentAddress: "উত্তরা, ঢাকা", nidLast4: "১১৯৮", emergency: { name: "আব্দুল খালেক", relation: "বাবা", mobile: "০১৯১১-২২০০৪৪" } },
  { id: "আবে-০০৫০", name: "রিয়াদ ইসলাম", mobile: "০১৯১১-৭৮৯০১২", submitted: "গতকাল", status: "pending", dob: "২০ জানুয়ারি ২০০৪ (২২ বছর)", presentAddress: "মিরপুর, ঢাকা", permanentAddress: "সদর, বরিশাল", nidLast4: "৫৫০২", emergency: { name: "রুমানা ইসলাম", relation: "বোন", mobile: "০১৮৭৭-৬৬৫৫৪৪" } },
  { id: "আবে-০০৪৯", name: "আরিফ মাহমুদ", mobile: "০১৬১৪-১১২২৩৩", submitted: "২ দিন আগে", status: "pending", dob: "৯ ডিসেম্বর ২০০১ (২৪ বছর)", presentAddress: "যাত্রাবাড়ী, ঢাকা", permanentAddress: "সদর, চাঁদপুর", nidLast4: "৮৮২০", emergency: { name: "মাহমুদা খাতুন", relation: "মা", mobile: "০১৭২২-১১৩৩৫৫" } },
  { id: "আবে-০০৪৮", name: "রাকিব হাসান", mobile: "০১৭১২-৩৪৫৬৭৮", submitted: "৩ মার্চ", status: "approved", dob: "১৪ মার্চ ১৯৯৮", presentAddress: "মিরপুর, ঢাকা", permanentAddress: "মিরপুর, ঢাকা", nidLast4: "৪৫২১", emergency: { name: "সালমা বেগম", relation: "মা", mobile: "০১৮১৯-২২৩৩৪৪" } },
];

export const products: Product[] = [
  { id: "jersey-bd", name: "জার্সি — বাংলাদেশ", category: "জার্সি", sku: "JRS-BD", unit: "পিস", price: 450, cost: 350, warehouse: 100, withSellers: 48, pendingTransfer: 20, damaged: 2, lowStockAt: 20, variants: ["S", "M", "L", "XL"], active: true },
  { id: "polo", name: "পোলো টি-শার্ট", category: "টি-শার্ট", sku: "TS-POLO", unit: "পিস", price: 380, minPrice: 350, maxPrice: 420, cost: 260, warehouse: 66, withSellers: 32, pendingTransfer: 0, damaged: 1, lowStockAt: 10, variants: ["M", "L", "XL"], active: true },
  { id: "basic-white", name: "বেসিক টি-শার্ট (সাদা)", category: "টি-শার্ট", sku: "TS-BSC-W", unit: "পিস", price: 250, cost: 160, warehouse: 170, withSellers: 50, pendingTransfer: 0, damaged: 0, lowStockAt: 20, variants: ["M", "L", "XL", "XXL"], active: true },
  { id: "jogger", name: "জগার প্যান্ট", category: "প্যান্ট", sku: "PNT-JOG", unit: "পিস", price: 550, minPrice: 500, maxPrice: 600, cost: 360, warehouse: 44, withSellers: 24, pendingTransfer: 0, damaged: 3, lowStockAt: 10, variants: ["M", "L", "XL"], active: true },
  { id: "cap", name: "ক্রিকেট ক্যাপ", category: "অ্যাক্সেসরিজ", sku: "ACC-CAP", unit: "পিস", price: 180, cost: 110, warehouse: 8, withSellers: 18, pendingTransfer: 0, damaged: 0, lowStockAt: 20, variants: [], active: true },
  { id: "socks", name: "মোজা (৩ জোড়া)", category: "অ্যাক্সেসরিজ", sku: "ACC-SOCK3", unit: "প্যাকেট", price: 150, cost: 90, warehouse: 0, withSellers: 0, pendingTransfer: 0, damaged: 0, lowStockAt: 10, variants: [], active: true },
];

export const categories = [
  { name: "জার্সি", count: 3, archived: false },
  { name: "টি-শার্ট", count: 5, archived: false },
  { name: "প্যান্ট", count: 3, archived: false },
  { name: "অ্যাক্সেসরিজ", count: 3, archived: false },
  { name: "শীতের পোশাক", count: 0, archived: true },
];

export const sales: Sale[] = [
  { id: "বি-১০৪৮২", time: "১০:৪৮", seller: "রাকিব হাসান", product: "জার্সি — বাংলাদেশ (L)", qty: 2, unitPrice: 450, cost: 350, commissionRate: 0.4, payment: "bkash", status: "confirmed" },
  { id: "বি-১০৪৮১", time: "১০:৪৫", seller: "নুসরাত জাহান", product: "পোলো টি-শার্ট (XL)", qty: 1, unitPrice: 380, cost: 260, commissionRate: 0, payment: "cash", status: "confirmed" },
  { id: "বি-১০৪৮০", time: "১০:৪১", seller: "সাকিব হোসেন", product: "জগার প্যান্ট (M)", qty: 1, unitPrice: 550, cost: 360, commissionRate: 0, payment: "cash", status: "confirmed" },
  { id: "বি-১০৪৭৯", time: "১০:২০", seller: "রাকিব হাসান", product: "পোলো টি-শার্ট (XL)", qty: 1, unitPrice: 380, cost: 260, commissionRate: 0.4, payment: "cash", status: "confirmed" },
  { id: "বি-১০৪৭১", time: "০৯:৫২", seller: "মিম আক্তার", product: "ক্রিকেট ক্যাপ", qty: 1, unitPrice: 180, cost: 110, commissionRate: 0, payment: "nagad", status: "correction" },
  { id: "বি-১০৪৬৮", time: "০৯:৪০", seller: "নুসরাত জাহান", product: "বেসিক টি-শার্ট (M)", qty: 3, unitPrice: 250, cost: 160, commissionRate: 0, payment: "cash", status: "confirmed" },
];

export const handovers: CashHandover[] = [
  { id: "h1", sellerId: "rakib", seller: "রাকিব হাসান", amount: 3200, method: "inPerson", note: "আজকের সব ক্যাশ", time: "আজ ১১:৩০", status: "pending" },
  { id: "h2", sellerId: "sakib", seller: "সাকিব হোসেন", amount: 1500, method: "bkash", reference: "TX9P4L", time: "আজ ১১:১০", status: "pending" },
  { id: "h3", sellerId: "mim", seller: "মিম আক্তার", amount: 1600, method: "nagad", reference: "NG77K2", time: "আজ ১০:৫০", status: "pending" },
  { id: "h4", sellerId: "nusrat", seller: "নুসরাত জাহান", amount: 4000, method: "inPerson", time: "আজ ০৯:৩০", status: "verified" },
  { id: "h5", sellerId: "shahriar", seller: "শাহরিয়ার কবির", amount: 1450, method: "bkash", reference: "TX1A9Z", time: "গতকাল", status: "rejected" },
];

export const dashboard = {
  todaySales: 48650,
  grossProfit: 11240,
  netProfit: 6890,
  cashOutstanding: 18200,
  sellerEarnings: 3450,
  activeSellers: 12,
  totalSellers: 15,
  hourly: [18, 34, 52, 70, 100, 64, 48, 58, 30, 0],
  pending: { applications: 4, cash: 6, returns: 3, settlements: 5, corrections: 2 },
};

export const financialSummary = {
  revenue: 984200,
  refunds: 4300,
  cogs: 746800,
  sellerCompensation: 68420,
  expenses: 34860,
  cashReceived: 841600,
};
