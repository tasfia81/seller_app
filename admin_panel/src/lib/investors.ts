import type { Tone } from "./types";

/** Investor management — demo data (all numbers agree with each other). */

export type InvestorStatus = "active" | "withdrawing" | "new" | "suspended";
export type InvestorAppStatus = "pending" | "review" | "moreInfo" | "approved" | "rejected";
export type PayoutPreference = "cash" | "reinvest";

export interface InvestorHolding {
  product: string;
  batch: string;
  bought: number;
  unitCost: number;
  sold: number;
  withSellers: number;
  share: number; // investor's profit share so far
}

export interface InvestorLedger {
  date: string;
  kind: "invest" | "profit" | "withdraw";
  label: string;
  amount: number;
  via: string;
  ref: string;
}

export interface Investor {
  id: string;
  code: string;
  name: string;
  mobileMasked: string;
  since: string;
  status: InvestorStatus;
  invested: number; // total ever given
  withdrawn: number;
  uninvested: number; // active capital not yet in stock
  profitTotal: number;
  profitPaid: number;
  profitThisMonth: number;
  netThisMonth: number; // net profit of this investor's stock this month
  sharePercent: number;
  preference: PayoutPreference;
  profitVia: string;
  capitalVia: string;
  nominee: string;
  holdings: InvestorHolding[];
  ledger: InvestorLedger[];
}

export const activeCapital = (i: Investor) => i.invested - i.withdrawn;
export const inStock = (i: Investor) => activeCapital(i) - i.uninvested;

export const investorStatus: Record<InvestorStatus, [string, Tone]> = {
  active: ["সক্রিয়", "ok"],
  withdrawing: ["ফেরত চেয়েছেন", "wa"],
  new: ["নতুন", "inf"],
  suspended: ["স্থগিত", "er"],
};

export const investorAppStatus: Record<InvestorAppStatus, [string, Tone]> = {
  pending: ["অপেক্ষমাণ", "wa"],
  review: ["যাচাই চলছে", "inf"],
  moreInfo: ["আরও তথ্য চাওয়া", "nu"],
  approved: ["অনুমোদিত", "ok"],
  rejected: ["বাতিল", "er"],
};

export const investors: Investor[] = [
  {
    id: "ashraful", code: "INV-০০০৭", name: "আশরাফুল করিম", mobileMasked: "০১৭১২-•••৬৭৮", since: "৪ আগস্ট ২০২৬",
    status: "active", invested: 500000, withdrawn: 50000, uninvested: 20200,
    profitTotal: 36260, profitPaid: 25460, profitThisMonth: 10800, netThisMonth: 21600, sharePercent: 50,
    preference: "cash", profitVia: "বিকাশ ••৭৭০২", capitalVia: "ব্যাংক ••৪৮২১", nominee: "স্ত্রী · ০১৮১৯-•••১১১",
    holdings: [
      { product: "জার্সি — বাংলাদেশ", batch: "ব্যাচ-৮৮ · ১২ অক্টো", bought: 428, unitCost: 350, sold: 296, withSellers: 84, share: 8260 },
      { product: "পোলো টি-শার্ট", batch: "ব্যাচ-৮৪ · ১০ সেপ্টে", bought: 400, unitCost: 260, sold: 268, withSellers: 70, share: 9200 },
      { product: "জগার প্যান্ট", batch: "ব্যাচ-৮৫ · ১৪ সেপ্টে", bought: 250, unitCost: 360, sold: 141, withSellers: 52, share: 7600 },
      { product: "বেসিক টি-শার্ট (সাদা)", batch: "ব্যাচ-৭৯ · ৬ আগস্ট", bought: 400, unitCost: 160, sold: 322, withSellers: 48, share: 8300 },
      { product: "ক্রিকেট ক্যাপ", batch: "ব্যাচ-৮০ · ৮ আগস্ট", bought: 200, unitCost: 110, sold: 150, withSellers: 30, share: 2900 },
    ],
    ledger: [
      { date: "১৮ নভে", kind: "withdraw", label: "মূলধন ফেরত", amount: 50000, via: "ব্যাংক ••৪৮২১", ref: "W-০০১২" },
      { date: "০৫ নভে", kind: "profit", label: "অক্টোবরের লাভ", amount: 11460, via: "বিকাশ ••৭৭০২", ref: "P-০০৩১" },
      { date: "১২ অক্টো", kind: "invest", label: "বিনিয়োগ (৩য় কিস্তি)", amount: 150000, via: "ব্যাংক ট্রান্সফার", ref: "I-০০২৪" },
      { date: "০৫ অক্টো", kind: "profit", label: "সেপ্টেম্বরের লাভ", amount: 8600, via: "বিকাশ ••৭৭০২", ref: "P-০০২২" },
      { date: "১০ সেপ্টে", kind: "invest", label: "বিনিয়োগ (২য় কিস্তি)", amount: 150000, via: "ব্যাংক ট্রান্সফার", ref: "I-০০১৭" },
      { date: "০৫ সেপ্টে", kind: "profit", label: "আগস্টের লাভ", amount: 5400, via: "বিকাশ ••৭৭০২", ref: "P-০০১১" },
      { date: "০৪ আগস্ট", kind: "invest", label: "প্রথম বিনিয়োগ", amount: 200000, via: "ব্যাংক ট্রান্সফার", ref: "I-০০০৯" },
    ],
  },
  {
    id: "farhana", code: "INV-০০০৯", name: "ফারহানা ইয়াসমিন", mobileMasked: "০১৮১১-•••২০৪", since: "১২ সেপ্টেম্বর ২০২৬",
    status: "withdrawing", invested: 300000, withdrawn: 0, uninvested: 18000,
    profitTotal: 22400, profitPaid: 15200, profitThisMonth: 7200, netThisMonth: 14400, sharePercent: 50,
    preference: "cash", profitVia: "ব্যাংক ••২২৯১", capitalVia: "ব্যাংক ••২২৯১", nominee: "মা · ০১৭১৫-•••৩৪৪",
    holdings: [], ledger: [],
  },
  {
    id: "mahbub", code: "INV-০০১১", name: "মাহবুব আলম", mobileMasked: "০১৯১৩-•••৫৮০", since: "২০ সেপ্টেম্বর ২০২৬",
    status: "active", invested: 200000, withdrawn: 0, uninvested: 12200,
    profitTotal: 9800, profitPaid: 4700, profitThisMonth: 5100, netThisMonth: 10200, sharePercent: 50,
    preference: "reinvest", profitVia: "—", capitalVia: "ব্যাংক ••৯১১০", nominee: "ভাই · ০১৬১২-•••৭৭১",
    holdings: [], ledger: [],
  },
  {
    id: "rubina", code: "INV-০০১৪", name: "রুবিনা আক্তার", mobileMasked: "০১৫৫৫-•••১২৩", since: "৩ নভেম্বর ২০২৬",
    status: "new", invested: 100000, withdrawn: 0, uninvested: 12000,
    profitTotal: 1200, profitPaid: 0, profitThisMonth: 1200, netThisMonth: 2400, sharePercent: 50,
    preference: "cash", profitVia: "নগদ ••৫০৩৩", capitalVia: "নগদ ••৫০৩৩", nominee: "বোন · ০১৭৩৩-•••৯০৮",
    holdings: [], ledger: [],
  },
];

export interface InvestorApplication {
  id: string;
  code: string;
  name: string;
  mobileMasked: string;
  submitted: string;
  proposed: number;
  status: InvestorAppStatus;
  dob: string;
  occupation: string;
  source: string;
  address: string;
  nidMasked: string;
  bankName: string;
  accountName: string;
  accountMasked: string;
  nominee: string;
}

export const investorApplications: InvestorApplication[] = [
  {
    id: "nazmul", code: "বিআ-০০২৪", name: "নাজমুল হক", mobileMasked: "০১৭১৮-•••৪২১", submitted: "আজ ১০:১৫", proposed: 200000,
    status: "pending", dob: "৮ জানুয়ারি ১৯৮৮ (৩৮ বছর)", occupation: "চাকরিজীবী", source: "বেতন / সঞ্চয়", address: "উত্তরা, ঢাকা",
    nidMasked: "•••• •••• ৪৮২১", bankName: "[ব্যাংকের নাম]", accountName: "MD NAZMUL HAQUE", accountMasked: "••••••৭৩১০", nominee: "শামীমা হক · স্ত্রী",
  },
  {
    id: "touhid", code: "বিআ-০০২৩", name: "তৌহিদ ইসলাম", mobileMasked: "০১৯১২-•••০৯৮", submitted: "গতকাল", proposed: 100000,
    status: "review", dob: "২ মে ১৯৯২ (৩৪ বছর)", occupation: "ব্যবসায়ী", source: "ব্যবসার আয়", address: "মিরপুর, ঢাকা",
    nidMasked: "•••• •••• ১১৯০", bankName: "[ব্যাংকের নাম]", accountName: "TOUHIDUL ISLAM", accountMasked: "••••••৪৪০২", nominee: "রহিমা বেগম · মা",
  },
  {
    id: "sadia", code: "বিআ-০০২১", name: "সাদিয়া রহমান", mobileMasked: "০১৬১৪-•••৫৫৭", submitted: "৩ দিন আগে", proposed: 50000,
    status: "moreInfo", dob: "১৯ আগস্ট ১৯৯৫ (৩১ বছর)", occupation: "প্রবাসী", source: "রেমিট্যান্স", address: "সিলেট সদর",
    nidMasked: "•••• •••• ৬০২৭", bankName: "[ব্যাংকের নাম]", accountName: "SADIA RAHMAN", accountMasked: "••••••৯৮১৫", nominee: "আরিফ রহমান · ভাই",
  },
];

/** A new stock batch whose cost is split across investors' uninvested money. */
export const draftBatch = { product: "পোলো টি-শার্ট · ব্যাচ-৯১ (নতুন)", qty: 200, unitCost: 260 };

/** This month's profit run (November is still open → draft). */
export const profitRun = {
  month: "নভেম্বর ২০২৬",
  closed: false,
  closesOn: "৩০ নভেম্বর",
  payOn: "৫ ডিসেম্বর",
  byProduct: [
    { product: "জার্সি — বাংলাদেশ", revenue: 126000, cost: 98000, commission: 11200, other: 900 },
    { product: "পোলো টি-শার্ট", revenue: 106400, cost: 72800, commission: 13440, other: 800 },
    { product: "অন্যান্য (৩টি)", revenue: 195600, cost: 153000, commission: 17040, other: 12220 },
  ],
};

export interface WithdrawalRequest {
  id: string;
  investorId: string;
  amount: number;
  requested: string;
  deadline: string;
  reason: string;
  status: "pending" | "approved" | "paid" | "rejected";
  paidOn?: string;
}

export const withdrawalStatus: Record<WithdrawalRequest["status"], [string, Tone]> = {
  pending: ["সিদ্ধান্ত বাকি", "wa"],
  approved: ["অনুমোদিত · পেমেন্ট বাকি", "inf"],
  paid: ["সম্পন্ন", "ok"],
  rejected: ["বাতিল", "er"],
};

export const withdrawals: WithdrawalRequest[] = [
  { id: "w14", investorId: "farhana", amount: 100000, requested: "২০ নভে", deadline: "২০ ডিসে", reason: "পারিবারিক প্রয়োজন", status: "pending" },
  { id: "w13", investorId: "mahbub", amount: 20000, requested: "১৫ নভে", deadline: "১৫ ডিসে", reason: "চিকিৎসা খরচ", status: "approved" },
  { id: "w12", investorId: "ashraful", amount: 50000, requested: "২ নভে", deadline: "২ ডিসে", reason: "জমি কেনা", status: "paid", paidOn: "১৮ নভে" },
];

export const investorById = (id: string) => investors.find((i) => i.id === id);
