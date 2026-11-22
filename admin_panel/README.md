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

## UI phase — demo data

- All figures come from `src/lib/demo-data.ts` (clearly labelled demo; no real people or transactions).
- Actions that need the backend (approve, verify cash, pay, save…) ask for confirmation where needed and then show a
  "server not connected yet" notice. Nothing is faked as saved or successful.
- Login accepts any input and opens the dashboard; password recovery never sends or verifies a real code.

## Structure

```
src/
  app/(auth)/      login, forgot-password
  app/(panel)/     dashboard, applications, sellers, sellers/[id], compensation,
                   products, products/new, inventory, assignments(+new, [id]),
                   sales, corrections, cash, payouts, returns, settlements,
                   expenses, reports(+performance), activity, settings, account, more
  components/      shell (sidebar, bottom nav, top bar), ui (icons, chips, toast, confirm)
  lib/             demo-data, format (Bangla digits/money), labels, nav, types
```

To connect the FastAPI backend, replace the imports from `lib/demo-data.ts` with API calls.
