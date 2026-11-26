# Street Sales API (FastAPI)

The backend for the Seller app (Flutter) and the Admin panel (Next.js). It runs locally on a JSON file for now; a Firebase (Firestore) adapter will be plugged in later.

## Running it

```powershell
cd backend
py -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload --port 8000
```

- API docs (Swagger): http://127.0.0.1:8000/docs
- Health: http://127.0.0.1:8000/health
- Tests: `.\.venv\Scripts\python.exe -m pytest -q`

Data is stored in `data/db.json` (photos in `data/uploads/`). Set `SEED_DEMO_DATA=true` to seed an empty local database with demo accounts. To reset, delete the `data/` folder.

## Demo logins (local only)

| Role | Mobile | Password |
|---|---|---|
| Admin | 01711000000 | admin1234 |
| Seller (Rakib, active, has sales) | 01712345678 | seller1234 |
| Seller (Nusrat, assignment pending) | 01819223344 | seller1234 |
| Investor (Ashraful — funded jersey L batch) | 01913000000 | invest1234 |

Login: `POST /api/v1/auth/login` `{ "identifier": "...", "password": "..." }` → `access_token`. After that, send `Authorization: Bearer <token>` with every request.

## Environment variables

| Name | Default | Purpose |
|---|---|---|
| `STORAGE` | `local` | `local` or (later) `firestore` |
| `DATA_FILE` | `data/db.json` | Local database file |
| `UPLOAD_DIR` | `data/uploads` | Private photo folder |
| `SECRET_KEY` | `dev-only-change-me` | Token signing key — **change it in production** |
| `TOKEN_TTL_HOURS` | `72` | Login lifetime |
| `SEED_DEMO_DATA` | `false` | Fill demo data into an empty DB |
| `CORS_ORIGINS` | `http://localhost:3000,...` | Admin panel URL |

## SMS verification and recovery

Set `BULKSMSBD_API_KEY` as a server secret and set `BULKSMSBD_SENDER_ID` if
using a different approved sender. Use a private `SECRET_KEY` in production.
Seller and investor registration plus seller, investor and admin password recovery use single-use SMS codes with a
five-minute lifetime and a five-attempt limit. Local deployments without an
SMS key keep the legacy application API available for development tests. The
mobile apps expect SMS verification during registration.

## Structure

```
app/
  main.py            FastAPI app, CORS, routers (/api/v1)
  core/              config, errors (Bangla messages), security (tokens), deps (role checks)
  storage/           Store/Tx interface → local.py (JSON), firestore.py (later), seed.py
  services/          All business rules (sales, stock, cash, commission, settlements...)
  api/               auth.py, seller.py, admin.py, uploads.py
tests/               17 end-to-end tests
```

Error format: `{"error": {"code": "insufficient_stock", "message": "<Bangla message>", "details": {}}}`

## Main endpoints

**Auth** — `POST /auth/login`, `GET /auth/me`, `POST /auth/password/otp` and `POST /auth/password/reset` (seller SMS recovery)

**Seller** (`/api/v1/seller`)
- Application: `POST /application/otp`, `POST /applications`, `POST /application/documents/{nid_front|nid_back|photo}`, `GET /application`, `POST /application/resubmit`
- Home / products: `GET /dashboard`, `GET /products`, `GET /products/{id}` (cost is never shown)
- Assignments: `GET /assignments`, `POST /assignments/{id}/accept`
- Sales: `POST /sales` (with `client_request_id`, duplicate-safe), `GET /sales`, `GET /sales/{id}`, `POST /sales/{id}/corrections`
- Earnings / stock: `GET /earnings`, `GET /inventory`, `POST|GET /returns`
- Cash: `GET /cash`, `POST /cash/handovers`
- Day closing: `GET /day-closing`, `POST /day-closing/submit`
- Others: `GET /notifications`, `GET /profile`, `POST /profile/change-requests`

**Admin** (`/api/v1/admin`)
- `GET /dashboard`, `GET /reports/{financial|sellers|products}`
- Applications: list/detail, `start-review`, `approve`, `reject`, `request-info`, `reveal-nid` (audited), documents
- Sellers: list/detail, `PATCH`, `status/{active|suspended|...}`, `revoke-sessions`, `PUT compensation`, earnings
- Products / categories: CRUD, archive
- Inventory: overview, `receipts`, `movements`, `transfers`, `damages`
- Assignments: create, cancel, close; Returns: approve, reject, receive
- Sales / corrections: list, `corrections/{id}/{approve|reject|clarify}`
- Cash / payouts / expenses: handovers verify/reject, `POST /payouts` (duplicate-safe), expenses
- Settlements: `settlements/{seller_id}/{day}` detail, `close`, `exception`, `request-correction`
- System: notifications, `audit-log`, `settings`

**Investor app** (`/api/v1/investor`)
- Application: `POST /application/otp`, `POST /applications`, `POST /application/documents/{nid_front|nid_back|selfie}`, `GET /application`, `POST /application/resubmit`
- `GET /dashboard`, `GET /portfolio`, `GET /products/{id}`, `GET /sellers` (name and area only — no phone/NID), `GET /ledger`, `GET /reports`
- `PUT /preferences` (take profit as cash / reinvest), `GET|POST /withdrawals`, `GET /notifications`

**Admin · investors and messages** (`/api/v1/admin`)
- KYC: `investor-applications` list/detail, `start-review`, `approve` (with terms), `reject`, `request-info`, `reveal-nid` (audited), documents
- `GET /investors`, `GET /investors/{id}`, `POST /investors/{id}/status`, `PUT /investors/{id}/terms`
- Money: `POST /investments` (same reference never twice), `GET /investor-capital`, `GET|POST /fundings` (put a new batch into stock + split who funded it)
- Profit: `GET /investor-profit/{YYYY-MM}` (draft/approved), `POST …/approve` (only after month-end), `POST …/pay` (no double payment)
- Capital return: `GET /investor-withdrawals`, `…/{id}/approve|reject|pay` (pays only up to the investor's uninvested money)
- Messages: `POST /messages` (to all/selected sellers or investors → in-app notification), `GET /messages`

### How investor profit is calculated
Every stock receipt is a **lot**. Investors' money funds lots (company money covers the rest). Sales are matched to lots of the same product and size **oldest-first**. Net profit = sale − lot's cost price − seller commission; an investor gets (their amount ÷ lot cost) × net × their share %. Money that is not in unsold stock is "uninvested" — usable for new stock or for withdrawal. Once a month's profit is approved it is locked, and later corrections don't change it.

Full list with request/response schemas: `/docs`.

## Plan for connecting Firebase

1. Implement the `Store`/`Tx` interface in `app/storage/firestore.py` using `firebase-admin` (Firestore transactions).
2. Move photos to Firebase Storage with short-lived signed URLs.
3. Switch over with `STORAGE=firestore` — the services/routes stay the same.
4. Optionally swap login to Firebase Auth (phone OTP).
5. Store money as integers in paisa (instead of floats).
