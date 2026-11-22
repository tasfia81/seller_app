export type Tone = "ok" | "wa" | "er" | "nu" | "inf";

export type SellerStatus = "active" | "inactive" | "suspended";
export type CompensationModel = "profit" | "daily" | "perUnit" | "hybrid";
export type InventoryPolicy = "dailyReturn" | "carryForward";
export type ApplicationStatus = "pending" | "review" | "moreInfo" | "approved" | "rejected";
export type RequestStatus = "pending" | "verified" | "rejected";
export type SettlementStatus = "open" | "submitted" | "review" | "discrepancy" | "closed";
export type PaymentMethod = "cash" | "bkash" | "nagad" | "bank" | "inPerson" | "other";

export interface Seller {
  id: string;
  name: string;
  mobile: string;
  status: SellerStatus;
  compensation: string;
  model: CompensationModel;
  policy: InventoryPolicy;
  todaySales: number;
  todayItems: number;
  cashDue: number;
  trend: number;
  monthSales: number;
  assigned: number;
  available: number;
  payable: number;
}

export interface Application {
  id: string;
  name: string;
  mobile: string;
  submitted: string;
  status: ApplicationStatus;
  dob: string;
  gender?: string;
  email?: string;
  guardian?: string;
  presentAddress: string;
  permanentAddress: string;
  nidLast4: string;
  emergency: { name: string; relation: string; mobile: string };
  backImageFailed?: boolean;
}

export interface Product {
  id: string;
  name: string;
  category: string;
  sku: string;
  unit: string;
  price: number;
  minPrice?: number;
  maxPrice?: number;
  cost: number;
  warehouse: number;
  withSellers: number;
  pendingTransfer: number;
  damaged: number;
  lowStockAt: number;
  variants: string[];
  active: boolean;
}

export interface Sale {
  id: string;
  time: string;
  seller: string;
  product: string;
  qty: number;
  unitPrice: number;
  cost: number;
  commissionRate: number;
  payment: PaymentMethod;
  status: "confirmed" | "correction";
}

export interface CashHandover {
  id: string;
  sellerId: string;
  seller: string;
  amount: number;
  method: PaymentMethod;
  reference?: string;
  note?: string;
  time: string;
  status: RequestStatus;
}
