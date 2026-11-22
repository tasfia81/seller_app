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

Data is stored in `data/db.json` (photos in `data/uploads/`). On first start the database is empty, so demo data is filled in automatically. To reset, delete the `data/` folder.

## Demo logins (local only)

| Role | Mobile | Password |
|---|---|---|
| Admin | 01711000000 | admin1234 |
| Seller (Rakib, active, has sales) | 01712345678 | seller1234 |
| Seller (Nusrat, assignment pending) | 01819223344 | seller1234 |

Login: `POST /api/v1/auth/login` `{ "identifier": "...", "password": "..." }` → `access_token`. After that, send `Authorization: Bearer <token>` with every request.

## Environment variables

| Name | Default | Purpose |
|---|---|---|
| `STORAGE` | `local` | `local` or (later) `firestore` |
| `DATA_FILE` | `data/db.json` | Local database file |
| `UPLOAD_DIR` | `data/uploads` | Private photo folder |
| `SECRET_KEY` | `dev-only-change-me` | Token signing key — **change it in production** |
| `TOKEN_TTL_HOURS` | `72` | Login lifetime |
| `SEED_DEMO_DATA` | `true` | Fill demo data into an empty DB |
| `CORS_ORIGINS` | `http://localhost:3000,...` | Admin panel URL |

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

**Auth** — `POST /auth/login`, `GET /auth/me`, `POST /auth/password/otp` (501 until an SMS provider is connected)

**Seller** (`/api/v1/seller`)
- Application: `POST /applications`, `POST /application/documents/{nid_front|nid_back|photo}`, `GET /application`, `POST /application/resubmit`
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

Full list with request/response schemas: `/docs`.

## Plan for connecting Firebase

1. Implement the `Store`/`Tx` interface in `app/storage/firestore.py` using `firebase-admin` (Firestore transactions).
2. Move photos to Firebase Storage with short-lived signed URLs.
3. Switch over with `STORAGE=firestore` — the services/routes stay the same.
4. Optionally swap login to Firebase Auth (phone OTP).
5. Store money as integers in paisa (instead of floats).
