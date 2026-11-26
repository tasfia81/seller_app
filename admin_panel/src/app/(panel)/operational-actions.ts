"use server";

import { refresh } from "next/cache";
import { api, toResult } from "@/lib/api/server";
import type { FormResult } from "@/components/ui/ApiForm";

type Operation =
  | "review-investor" | "approve-investor" | "reject-investor" | "investor-info" | "investor-status" | "investor-terms"
  | "investment" | "funding" | "profit-approve" | "profit-pay" | "withdraw-approve" | "withdraw-reject" | "withdraw-pay"
  | "profile-request" | "return-approve" | "return-reject" | "return-receive" | "close-day" | "day-exception" | "day-correction" | "settings";

export async function submitOperation(operation: Operation, id: string, _: FormResult | null, form: FormData): Promise<FormResult> {
  const value = (key: string) => String(form.get(key) ?? "").trim();
  const numeric = (key: string) => Number(value(key));
  const key = encodeURIComponent(id);
  const post = (path: string, body?: unknown) => api.post(`/admin${path}`, body);
  const terms = () => ({ share_percent: numeric("share_percent"), payout_day: numeric("payout_day"), notice_days: numeric("notice_days") });
  const requestId = () => value("request_id") || crypto.randomUUID();
  const app = `/investor-applications/${key}`;
  const wd = `/investor-withdrawals/${key}`;
  const ret = `/returns/${key}`;
  const day = `/settlements/${key}/${encodeURIComponent(value("day"))}`;
  const run = async () => {
    switch (operation) {
      case "review-investor": return post(`${app}/start-review`);
      case "approve-investor": return post(`${app}/approve`, { terms: terms() });
      case "reject-investor": return post(`${app}/reject`, { reason: value("reason") });
      case "investor-info": return post(`${app}/request-info`, { fields: form.getAll("fields"), message: value("message") });
      case "investor-status": return post(`/investors/${key}/status`, { status: value("status"), reason: value("reason") });
      case "investor-terms": return api.put(`/admin/investors/${key}/terms`, terms());
      case "investment": return post("/investments", {
        investor_id: value("investor_id"), amount: numeric("amount"), method: value("method"),
        reference: value("reference"), received_on: value("received_on"), seen_in_statement: form.has("seen_in_statement"),
        client_request_id: requestId(),
      });
      case "funding": return post("/fundings", {
        product_id: value("product_id"), variant: value("variant") || null, quantity: numeric("quantity"),
        unit_cost: numeric("unit_cost"), batch_ref: value("batch_ref"), supplier: value("supplier") || null,
        company_amount: numeric("company_amount"),
        parts: Array.from(form.entries()).filter(([name, amount]) => name.startsWith("part:") && Number(amount) > 0)
          .map(([name, amount]) => ({ investor_id: name.slice(5), amount: Number(amount) })),
      });
      case "profit-approve": return post(`/investor-profit/${key}/approve`);
      case "profit-pay": return post(`/investor-profit/${key}/pay`, {
        investor_id: value("investor_id"), reference: value("reference") || null, client_request_id: requestId(),
      });
      case "withdraw-approve": return post(`${wd}/approve`, { note: value("note") || null });
      case "withdraw-reject": return post(`${wd}/reject`, { reason: value("reason") });
      case "withdraw-pay": return post(`${wd}/pay`, {
        amount: numeric("amount"), reference: value("reference"), client_request_id: requestId(),
      });
      case "profile-request": {
        const decision = value("decision") === "approve" ? "approve" : "reject";
        return post(`/sellers/${key}/profile-requests/${encodeURIComponent(value("request_id"))}/${decision}`);
      }
      case "return-approve": return post(`${ret}/approve`, { destination: value("destination") });
      case "return-reject": return post(`${ret}/reject`, { note: value("note") || null });
      case "return-receive": return post(`${ret}/receive`);
      case "close-day": return post(`${day}/close`);
      case "day-exception": return post(`${day}/exception`, { note: value("note") });
      case "day-correction": return post(`${day}/request-correction`, { note: value("note") });
      case "settings": return api.put("/admin/settings", {
        business: { name: value("name"), phone: value("phone"), address: value("address") },
        inventory: { default_policy: value("default_policy"), low_stock_default: numeric("low_stock_default"),
          close_requires_cash: form.has("close_requires_cash"), close_requires_returns: form.has("close_requires_returns") },
        payments: Object.fromEntries(["cash", "bkash", "nagad", "bank", "other"].map((method) => [method, {
          enabled: form.has(`payment:${method}`),
          destination: method === "cash" || method === "other" ? "seller" : "business",
        } ])),
      });
    }
  };
  const result = await toResult(run, "সার্ভারে সংরক্ষিত হয়েছে।");
  if (result.ok) refresh();
  return { ok: result.ok, message: result.message ?? "কাজ সম্পন্ন হয়েছে।" };
}
