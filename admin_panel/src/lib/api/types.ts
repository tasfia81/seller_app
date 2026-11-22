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
  compensation: { label: string; effective_from?: string; model: string };
  kpis: { today_sales: number; month_sales: number; assigned: number; available: number; cash_due: number; earnings_payable: number };
  assignments: { id: string; status: string; created_at: string; items: { product_id: string; variant: string | null; name: string; quantity: number; sold: number; returned: number }[] }[];
  cash: { collected: number; verified: number; pending_verification: number; due: number; to_submit: number };
  earnings: { today: number; this_month: number; pending: number; approved: number; total_paid: number; outstanding: number };
}

export const placeText = (a: ApiAddress | string) => (typeof a === "string" ? a : addressText(a));
