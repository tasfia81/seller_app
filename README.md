# স্ট্রিট সেলস — Seller App (UI phase)

Bangla-first Flutter UI for the street-sales seller app. This phase is **UI only**: no backend, no real auth/OTP, no real money movement.

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

### Easy access during the UI phase

- `AppConfig.skipAuthValidation = true`: login, password reset and the seller application accept any input (even empty) so every screen can be reached. Set to `false` to turn validation back on.
- Welcome screen has **"ডেমো: সরাসরি অ্যাপ দেখুন"** to jump straight to Home (only while `demoMode` is on).

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

## Demo mode

`AppConfig.demoMode = true` (lib/core/constants/app_config.dart):

- A yellow **ডেমো** banner shows in the corner.
- Repositories return clothing-product fixtures from `core/demo/demo_data.dart` (no real people, NIDs or transactions).
- OTP / password reset are **never simulated**: the screens can be previewed but show "শুধু স্ক্রিন দেখানো হচ্ছে".
- Set it to `false` and every screen shows a "সার্ভারের সাথে সংযোগ এখনো চালু হয়নি" state instead of data.

To integrate FastAPI: implement each `domain/*` interface with an HTTP client and swap the provider in `data/*`.

## Screen inventory

| # | Screen | Route | Status |
|---|---|---|---|
| 01 | Splash | `/` | Done — routes to intro (session check is a TODO) |
| — | Intro (3 slides) | `/intro` | Done |
| 02 | Welcome | `/welcome` | Done |
| 03 | Login | `/login` | Done (validation; demo login opens Home) |
| 04–05 | Forgot password: mobile → OTP → new password | `/forgot-password` | UI done, backend required |
| 06–10 | Registration steps 1–5 (personal, identity + NID/photo capture, emergency, security, review) | `/register` | Done (local validation, camera/gallery, consents) |
| 11 | Application submitted | `/application-submitted` | Done |
| 12 | Application status (+ resubmit one document) | `/application-status` | Done |
| 13 | Home dashboard | `/home` | Done |
| 14 | My products (search, category, stock filter) | `/products` | Done |
| 15 | Product details | `/product/:id` | Done |
| 16 | Quick sale (variant, unit-aware quantity, price limits, payment, idempotent submit) | `/new-sale` | Done |
| 17 | Sale success | `/sale-success` | Done — only shown with a confirmed sale |
| 18 | Sales history (today / yesterday / 7 days / date range, ID search, status filter) | `/sales` | Done |
| — | Sale details / receipt / correction request | `/sale-details/:id` | Done (correction needs backend) |
| 19 | My earnings (earnings + payout history) | `/earnings` | Done |
| 20 | My inventory (policy, summary, movements) | `/inventory` | Done |
| 21 | Stock return request | `/stock-return` | Done (stays pending) |
| 22 | Cash handover (pending verification) | `/cash-handover` | Done |
| 23 | Day closing (policy requirements) | `/day-closing` | Done (submit needs backend) |
| 24 | Notifications (filters, read/unread) | `/notifications` | Done |
| 25 | Account | `/account` | Done |
| 26 | Profile (masked NID) | `/profile` | Done |
| 27 | Settings & help (FAQ) | `/settings` | Done |

## Not done yet

- Remembered phone number / stored session (needs secure storage).
- English translations (all copy is Bangla; strings are inline).
- Real logo and product images (icons are placeholders).
- Dark theme (colors are centralised in `AppColors` so it can be added).
