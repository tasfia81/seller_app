# স্ট্রিট সেলস — Seller App

> This repository also contains the **admin web panel** in [`admin_panel/`](admin_panel/README.md) (Next.js), the **FastAPI backend** in [`backend/`](backend/README.md) and the **investor app** in [`investor_app/`](investor_app/README.md) (Flutter).

Bangla-first Flutter seller app. Use the shared local FastAPI backend for the Seller app, Investor app and Admin panel. The default storage is local JSON.

## First-time setup

This folder contains `lib/`, `test/` and `pubspec.yaml`. Generate the Android
platform folder once (it won't overwrite existing files), then run:

```powershell
cd D:\androidStudioproject\seller_app
flutter create . --platforms android --project-name seller_app --org com.streetsales
flutter pub get
flutter analyze
flutter test
flutter run
```

### Run in Chrome (quick preview)

```powershell
flutter create . --platforms android,web --project-name seller_app --org com.streetsales
flutter run -d chrome
```

Open Chrome DevTools → device toolbar to see it at phone size.

### Seller login and registration

- Run FastAPI, then start the Seller app. The Android emulator defaults to
  `http://10.0.2.2:8000/api/v1`. For a physical device or release, pass the
  backend URL with `--dart-define=API_URL=https://your-server/api/v1`.
- Set `BULKSMSBD_API_KEY` in the backend environment to enable registration
  verification and password recovery. Set `BULKSMSBD_SENDER_ID` if the approved
  sender differs from the repository default.
- For a local UI preview, run with `--dart-define=PREVIEW_AUTH=true`. This enables
  the demo entry button and preview-only forms.

## Tech

| Concern | Choice |
|---|---|
| State | flutter_riverpod 2 (FutureProvider / Notifier) |
| Navigation | go_router — `StatefulShellRoute.indexedStack` for the 4 tabs (tabs keep their state, switching is instant), full-screen pages on the root navigator |
| Responsive | flutter_screenutil, design frame 360×760. Touch targets are clamped to ≥ 48dp; system text scale respected (capped at 1.3) |
| Locale | `bn_BD` — Material widgets (date picker, dialogs) are Bangla too |
| Font | System font (Android renders Bangla with Noto Sans Bengali). To bundle a font, add it to `assets/fonts` and set `fontFamily` in `app_theme.dart` |
| Images | image_picker; photos stay in the app's private cache, never saved to the gallery |

## Structure

```
lib/
  app/            app.dart, router/ (routes, shell), theme/ (colors, text, sizes)
  core/           constants, errors (typed Failures), utils (Bangla format, validators),
                  widgets (buttons, fields, cards, chips, states, stepper, pills, upload card),
                  demo/demo_data.dart  ← preview fixtures only
  shared/         models (Product, Sale, finance, inventory, seller), commerce widgets
  features/<name>/
    domain/       abstract repository + payload types
    data/         Preview… repository + Riverpod providers
    presentation/ screens (+ controller where there is logic)
```

## Local backend for all three apps

Run FastAPI from the `backend` directory with Python 3.12:

```sh
python -m pip install -r requirements.txt
STORAGE=local SEED_DEMO_DATA=true python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

`SEED_DEMO_DATA=true` fills an empty local database with the sample accounts
listed in [backend/README.md](backend/README.md). Subsequent launches preserve
data in `backend/data/db.json`. Set the rotated BulkSMSBD key in the backend
environment before testing registration or password recovery.

- **Seller App** — run `flutter pub get` and `flutter run` from the repository root.
- **Investor App** — run those commands from `investor_app/`.
- **Admin Panel** — run `npm ci` and `npm run dev` from `admin_panel/`, then open `http://localhost:3000`.
- For both Android emulators the default API URL is `http://10.0.2.2:8000/api/v1`.
  For a Flutter web preview use `--dart-define=API_URL=http://127.0.0.1:8000/api/v1`
  and add the preview origin to `CORS_ORIGINS`. The admin defaults to the same local API.
- Seller UI-only preview is available in debug builds with
  `--dart-define=PREVIEW_AUTH=true`.

## Screen inventory

| # | Screen | Route | Status |
|---|---|---|---|
| 01 | Splash | `/` | Restores the saved seller session or opens the intro |
| — | Intro (3 slides) | `/intro` | Done |
| 02 | Welcome | `/welcome` | Done |
| 03 | Login | `/login` | FastAPI mobile/password login and secure session restore |
| 04–05 | Forgot password: mobile → OTP → new password | `/forgot-password` | Seller SMS reset via FastAPI |
| 06–10 | Registration steps 1–5 (personal, identity + NID/photo capture, emergency, security, review) | `/register` | FastAPI application, SMS verification and document upload |
| 11 | Application submitted | `/application-submitted` | Done |
| 12 | Application status (+ resubmit one document) | `/application-status` | Done |
| 13 | Home dashboard | `/home` | Done |
| 14 | My products (search, category, stock filter) | `/products` | Done |
| 15 | Product details | `/product/:id` | Done |
| 16 | Quick sale (variant, unit-aware quantity, price limits, payment, idempotent submit) | `/new-sale` | Done |
| 17 | Sale success | `/sale-success` | Done — only shown with a confirmed sale |
| 18 | Sales history (today / yesterday / 7 days / date range, ID search, status filter) | `/sales` | Done |
| — | Sale details / receipt / correction request | `/sale-details/:id` | FastAPI sale detail and correction requests |
| 19 | My earnings (earnings + payout history) | `/earnings` | Done |
| 20 | My inventory (policy, summary, movements) | `/inventory` | Done |
| 21 | Stock return request | `/stock-return` | Done (stays pending) |
| 22 | Cash handover (pending verification) | `/cash-handover` | Done |
| 23 | Day closing (policy requirements) | `/day-closing` | FastAPI reconciliation and submission |
| 24 | Notifications (filters, read/unread) | `/notifications` | Done |
| 25 | Account | `/account` | Done |
| 26 | Profile (masked NID) | `/profile` | Done |
| 27 | Settings & help (FAQ) | `/settings` | Done |

## Not done yet

- Remembered phone number.
- English translations (all copy is Bangla; strings are inline).
- Real logo and product images (icons are placeholders).
- Dark theme (colors are centralised in `AppColors` so it can be added).
