import type { ApplicationStatus, PaymentMethod, RequestStatus, SellerStatus, SettlementStatus, Tone } from "./types";

export const sellerStatus: Record<SellerStatus, [string, Tone]> = {
  active: ["সক্রিয়", "ok"],
  inactive: ["নিষ্ক্রিয়", "nu"],
  suspended: ["স্থগিত", "er"],
};

export const applicationStatus: Record<ApplicationStatus, [string, Tone]> = {
  pending: ["অপেক্ষমাণ", "wa"],
  review: ["যাচাই চলছে", "inf"],
  moreInfo: ["আরও তথ্য প্রয়োজন", "wa"],
  approved: ["অনুমোদিত", "ok"],
  rejected: ["বাতিল", "er"],
};

export const requestStatus: Record<RequestStatus, [string, Tone]> = {
  pending: ["যাচাই বাকি", "wa"],
  verified: ["যাচাই হয়েছে", "ok"],
  rejected: ["প্রত্যাখ্যাত", "er"],
};

export const settlementStatus: Record<SettlementStatus, [string, Tone]> = {
  open: ["খোলা", "nu"],
  submitted: ["জমা হয়েছে", "inf"],
  review: ["যাচাই চলছে", "wa"],
  discrepancy: ["গরমিল", "er"],
  closed: ["বন্ধ", "ok"],
};

export const paymentLabel: Record<PaymentMethod, string> = {
  cash: "ক্যাশ",
  bkash: "বিকাশ",
  nagad: "নগদ",
  bank: "ব্যাংক",
  inPerson: "অফিসে হাতে",
  other: "অন্যান্য",
};

export const policyLabel = { dailyReturn: "প্রতিদিন ফেরত", carryForward: "পরের দিনে চলবে" } as const;
