# Street Sales — Investor app (Flutter)

The app for investors: where their money is invested, which product it bought, which seller holds that stock, how much has sold, how much profit they earned and when it was paid. All text is in Bangla.

Design: the "ইনভেস্টর অ্যাপ ডিজাইন" canvas — this code follows it screen by screen.

## Running it

```powershell
cd investor_app
flutter pub get
flutter run            # phone / emulator
flutter run -d chrome  # browser
flutter test           # number-consistency tests
```

Make sure the `flutter --version` command works first.

## Screens

| Flow | Screens |
|---|---|
| Start | Splash (pre-loads fonts) → Onboarding 1–3 (transparency, how the money works, trust & risk) → Welcome |
| Opening an account | Mobile + OTP → personal info → NID/selfie → payout method + nominee → agreement → "verification in progress" |
| Bottom tabs | Home · Portfolio · Ledger · Report |
| Others | Product detail, seller-wise stock, withdraw profit/capital, notifications, profile, side menu (push-aside animation) |

## Structure

```
lib/
  app/        app.dart, router (go_router + 4-tab shell + side menu), theme (colors, fonts)
  core/       config, Bangla number/money format, shared widgets
  data/       models.dart, investor_repository.dart (interface + demo data + providers)
  features/   intro, signup, home, menu, portfolio, sellers, ledger, report, withdraw, notifications, profile
```

## Things to know

- **Demo data:** `DemoInvestorRepository` supplies the numbers, and they all agree with each other (`test/numbers_test.dart` checks this). Later, implement the `InvestorRepository` interface against the FastAPI backend and swap the provider — no screen needs changing.
- **No fake success:** withdraw requests, PDF downloads and new investments currently show a "ডেমো মোড" message. Without the server, nothing claims "sent".
- **Validation:** `AppConfig.skipValidation = true` (UI phase). Set it to `false` to turn checks on.
- **Bracketed text:** fill in the real values in `AppConfig` — `[ট্রেড লাইসেন্স নম্বর]`, `[অফিসের ঠিকানা]`, `[হেল্পলাইন নম্বর]`, `[সর্বনিম্ন বিনিয়োগ]`.
- **Terms:** profit share 50%, seller commission 40%, payout on the 5th of each month, 30-day notice for capital return — all in `AppConfig`; update them to match the final agreement.

## Smoothness (no lag)

- The side menu animation only runs transform/scale/clip; the screen sits in a `RepaintBoundary`, so nothing is rebuilt while it animates.
- Charts are painted with `CustomPainter` inside a `RepaintBoundary`, and only repaint when the data changes.
- Lists use `SliverList` / `ListView.builder`; heavy shadows are kept to a minimum.
- NID/selfie photos are compressed (1600px, 75%) and previewed with `cacheWidth`, so memory stays low.
- `InkRipple` is used (no shader jank on first tap); fonts are pre-loaded on the splash screen.
- Text size follows the system setting, capped at 1.25×, so the layout doesn't break.
