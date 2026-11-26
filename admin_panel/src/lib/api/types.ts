/** Shapes returned by the FastAPI backend (only the fields the panel uses). */

export interface ApiSale {
  id: string;
  receipt_no: string;
  seller_id: string;
  seller_name: string;
  product_id: string;
  product_name: string;
  variant: string | null;
  quantity: number;
  unit_price: number;
  total: number;
  payment: string;
  payment_label: string;
  status: string;
  status_label: string;
  created_at: string;
  corrected: boolean;
  note?: string | null;
  money_destination?: "seller_cash" | "business_account";
  unit_cost_snapshot?: number;
  original?: { qty: number; unit_price: number; payment: string };
  corrections?: ApiCorrection[];
  gross_profit?: number;
  commission?: number;
  cost_total?: number;
}

export interface ApiDashboard {
  period: { from: string; to: string };
  metrics: {
    total_sales: number;
    previous_total_sales: number;
    gross_profit: number;
    estimated_net_profit: number;
    cash_outstanding: number;
    seller_earnings: number;
    active_sellers: number;
    total_active_sellers: number;
  };
  hourly_sales: { hour: number; total: number }[];
  seller_performance: { seller_id: string; name: string; sales: number; quantity: number; cash_due: number; change_percent: number | null }[];
  recent_sales: ApiSale[];
  inventory_alerts: {
    low_central_stock: { product_id: string; name: string; warehouse: number }[];
    low_seller_stock: { seller_name: string; product: string; qty: number }[];
    pending_transfers: number;
    damaged_units: number;
  };
  pending_actions: { applications: number; cash_handovers: number; stock_returns: number; settlements: number; corrections: number };
  unread_notifications: number;
}

export interface ApiAddress { division: string; district: string; upazila: string; detail: string }

export type ApiApplicationStatus = "submitted" | "under_review" | "more_info" | "approved" | "rejected";

export interface ApiApplicationSummary {
  id: string;
  full_name: string;
  mobile: string;
  submitted_at: string;
  status: ApiApplicationStatus;
  status_label: string;
  has_photo: boolean;
}

export interface ApiApplication {
  id: string;
  status: ApiApplicationStatus;
  status_label: string;
  submitted_at: string;
  full_name: string;
  mobile: string;
  date_of_birth: string;
  gender: string | null;
  email: string | null;
  guardian_name: string | null;
  present_address: ApiAddress;
  permanent_address: ApiAddress;
  nid_masked: string;
  emergency: { name: string; relation: string; mobile: string };
  documents: Record<"nid_front" | "nid_back" | "photo", { uploaded: boolean; uploaded_at: string | null }>;
  requested_fields: string[];
  admin_message: string | null;
  rejection_reason: string | null;
  timeline: { title: string; at: string; by: string }[];
}

export const addressText = (a: ApiAddress) => [a.detail, a.upazila, a.district].filter(Boolean).join(", ");

export type ApiSellerStatus = "active" | "inactive" | "suspended";
export type ApiPolicy = "daily_return" | "carry_forward";

export interface ApiSellerRow {
  id: string;
  name: string;
  mobile: string;
  status: ApiSellerStatus;
  status_label: string;
  compensation: string;
  model: "profit" | "daily" | "per_unit" | "hybrid";
  policy: ApiPolicy;
  policy_label: string;
  today_sales: number;
  today_items: number;
  cash_due: number;
}

export interface ApiSellerOverview {
  seller: {
    id: string;
    name: string;
    mobile: string;
    status: ApiSellerStatus;
    status_label: string;
    present_address: ApiAddress | string;
    permanent_address: ApiAddress | string;
    emergency: { name: string; relation: string; mobile: string };
    nid_masked: string;
    policy: ApiPolicy;
    policy_label: string;
    permissions: { can_edit_price: boolean; can_discount: boolean; can_take_digital: boolean };
    joined_at: string;
  };
  profile_requests: { id: string; field: string; new_value: string; status: string; at: string }[];
  compensation: { label: string; effective_from?: string; model: string };
  kpis: { today_sales: number; month_sales: number; assigned: number; available: number; cash_due: number; earnings_payable: number };
  assignments: { id: string; status: string; created_at: string; items: { product_id: string; variant: string | null; name: string; quantity: number; sold: number; returned: number }[] }[];
  cash: { collected: number; verified: number; pending_verification: number; due: number; to_submit: number };
  earnings: { today: number; this_month: number; pending: number; approved: number; total_paid: number; outstanding: number };
}

export const placeText = (a: ApiAddress | string) => (typeof a === "string" ? a : addressText(a));

export type ApiUnit = "piece" | "kg" | "gram" | "liter" | "packet" | "bottle" | "box";
export const UNIT_LABELS: Record<ApiUnit, string> = { piece: "পিস", kg: "কেজি", gram: "গ্রাম", liter: "লিটার", packet: "প্যাকেট", bottle: "বোতল", box: "বক্স" };

export interface ApiCategory { id: string; name: string; archived: boolean; product_count: number }

export interface ApiProduct {
  id: string;
  name: string;
  category_id: string;
  category_name: string | null;
  sku: string;
  description: string | null;
  unit: ApiUnit;
  unit_label: string;
  quantity_step: number;
  unit_cost: number;
  price: number;
  min_price: number | null;
  max_price: number | null;
  price_editable: boolean;
  variant_label: string | null;
  variants: string[];
  low_stock_at: number;
  track_stock: boolean;
  track_expiry: boolean;
  discount_allowed: boolean;
  active: boolean;
  stock: { warehouse: number; reserved: number; damaged: number; with_sellers: number };
  stock_status: "ok" | "low_stock" | "out_of_stock";
}

export interface ApiInventory {
  totals: { warehouse: number; with_sellers: number; reserved: number; damaged: number; total: number; low_stock_products: number };
  products: {
    product_id: string;
    name: string;
    unit_label: string;
    warehouse: number;
    with_sellers: number;
    reserved: number;
    damaged: number;
    stock_value: number;
    low: boolean;
    by_variant: { variant: string | null; warehouse: number; reserved: number }[];
  }[];
}

export type ApiAssignmentStatus = "pending_handover" | "active" | "partially_returned" | "closed" | "cancelled";

export interface ApiAssignment {
  id: string;
  seller_id: string;
  seller_name: string;
  status: ApiAssignmentStatus;
  status_label: string;
  price_mode: "fixed" | "flexible";
  discount_allowed?: boolean;
  policy?: string;
  created_at: string;
  accepted_at: string | null;
  items: { product_id: string; variant: string | null; name: string; quantity: number; sold: number; returned: number; remaining: number }[];
  totals: { quantity: number; sold: number; returned: number; remaining: number };
  history: { title: string; by: string; at: string }[];
}

export interface ApiMovement {
  id: string;
  kind: "receipt" | "assignment" | "sale" | "return" | "damage" | "transfer_out" | "adjustment";
  product_id: string;
  product_name: string;
  variant: string | null;
  qty: number;
  source: string;
  destination: string;
  ref: string;
  by: string;
  at: string;
}

export interface ApiSalesList {
  from: string;
  to: string;
  summary: { count: number; total: number; quantity: number; gross_profit?: number; seller_earnings?: number };
  items: ApiSale[];
}

export type ApiCorrectionStatus = "pending" | "clarification" | "approved" | "rejected";

export interface ApiCorrection {
  id: string;
  sale_id: string;
  receipt_no: string;
  seller_id: string;
  seller_name: string;
  current: { qty: number; unit_price: number; payment: string };
  requested: { qty?: number; unit_price?: number; payment?: string };
  reason: string;
  status: ApiCorrectionStatus;
  admin_note: string | null;
  decided_by?: string;
  decided_at?: string;
  created_at: string;
}


export type ApiHandoverStatus = "pending" | "verified" | "rejected";

export interface ApiHandover {
  id: string;
  seller_id: string;
  seller_name: string;
  amount: number;
  method: string;
  reference: string | null;
  note: string | null;
  status: ApiHandoverStatus;
  submitted_at: string;
  received_amount: number | null;
  shortfall?: number;
  verified_by?: string;
  verified_at?: string;
  history: { action: string; by: string; at: string; note: string | null }[];
}

export interface ApiCashSummary { collected: number; verified: number; pending_verification: number; due: number; to_submit: number }

export interface ApiCashOverview {
  totals: ApiCashSummary;
  business_direct_today: number;
  sellers: (ApiCashSummary & { seller_id: string; seller_name: string })[];
}

export interface ApiPayout { id: string; seller_id: string; seller_name: string; amount: number; method: string; reference: string | null; note: string | null; by: string; at: string; status: string }

export interface ApiPayoutsOverview {
  totals: { earned: number; approved: number; paid: number; outstanding: number };
  sellers: { seller_id: string; seller_name: string; earned: number; approved: number; paid: number; outstanding: number }[];
  history: ApiPayout[];
}

export interface ApiExpense { id: string; category: string; amount: number; date: string; description: string; seller_id: string | null; product_id: string | null; recorded_by: string; at: string }
export interface ApiExpenseList { total: number; by_category: Record<string, number>; items: ApiExpense[] }

export interface ApiSupportThread {
  id: string;
  topic: string;
  topic_label: string;
  status: "open" | "resolved";
  status_label: string;
  created_at: string;
  updated_at: string;
  last_message: string;
  last_from: "user" | "admin";
  unread: number;
  owner_kind: "seller" | "investor";
  owner_name: string;
  owner_mobile: string | null;
  seller_id: string | null;
  investor_id: string | null;
  is_applicant: boolean;
}

export interface ApiSupportMessage { id: string; sender: "user" | "admin"; author: string; text: string; at: string }

export interface ApiSupportInbox {
  counts: { open: number; waiting: number; resolved: number };
  items: ApiSupportThread[];
}
