# স্ট্রিট সেলস — অ্যাডমিন প্যানেল (ওয়েব)

Bangla-first admin web panel for the Street Sales business. Responsive: full sidebar on desktop, bottom navigation on phones.

**Tech:** Next.js 16 (App Router, Turbopack), React 19, TypeScript, Tailwind CSS 4, Noto Sans Bengali via `next/font`.

## Run

```powershell
cd admin_panel
npm install
npm run dev
```

Open http://localhost:3000 (redirects to `/dashboard`). Production: `npm run build` then `npm start`.

## Local FastAPI

Start the backend before opening the panel. Its default API address is
`http://127.0.0.1:8000/api/v1`. Set `API_URL` in the Next.js environment if it
runs on a different address. The backend stores local data in `backend/data/db.json`.

Seller approvals, stock, cash, payouts, investor applications, investment
receipts, funded batches, monthly profit, withdrawals and in-app messages use
the backend. The account page uses the signed-in admin's server session.

## Structure

```
src/
  app/(auth)/      login, forgot-password
  app/(panel)/     dashboard, applications, sellers, sellers/[id], compensation,
                   products, products/new, inventory, assignments(+new, [id]),
                   sales, corrections, cash, payouts, returns, settlements,
                   expenses, reports(+performance), activity, settings, account, more
  components/      shell (sidebar, bottom nav, top bar), ui (icons, chips, toast, confirm)
  lib/             API client, format (Bangla digits/money), labels, nav, types
```
