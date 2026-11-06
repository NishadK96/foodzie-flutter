# Foodzy Restaurant POS

A Flutter restaurant POS for desktop, web, and tablet layouts. It connects to the Foodzy REST API for authentication, catalog, tables, orders, kitchen tickets, payment confirmation, customers, reservations, printers, branches, and staff. An offline demo mode remains available for UI review without a backend.

## Run

Use Flutter 3.38 or newer:

```sh
flutter pub get
flutter run -d chrome
```

The app connects to `http://localhost:8080/api/v1` by default. Override the API host for another environment without changing source code:

```sh
flutter run -d windows --dart-define=FOODZY_API_BASE_URL=https://foodzy.cloud/api/v1
```

The sign-in screen uses the backend's rotating access/refresh token flow. Tokens are stored with `flutter_secure_storage` (Windows Credential Manager on Windows), refreshed automatically after an authenticated `401`, and removed on sign-out. After login, the active restaurant and branch are loaded from `/auth/me`; subsequent requests include `X-Branch-ID`. Menu categories, items, tables, order types, taxes, orders, KOTs, customers, reservations, printers, receipt settings, branches, and staff are loaded from the live API. Use **Continue with demo data** when the backend is unavailable or for a standalone UI preview.

For Windows, use `flutter run -d windows` on a Windows machine with the Flutter desktop toolchain installed. For a Windows executable, run `flutter build windows` there. You can also run `flutter run -d macos` or `flutter run -d android` on supported hosts.

The **Windows release** GitHub Actions workflow verifies the app and uploads the complete Windows release directory as the `Foodzy-Windows` artifact. Keep the `.exe`, DLLs, and `data` directory together when distributing it.

## Validate

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

To verify the complete local backend contract against a disposable development database:

```sh
python3 tool/verify_local_api.py --password '<local seeded password>'
```

## Demo workflow

The app opens to Table 08 with a populated order. Search or filter the 60-item menu, customize a dish, and add it to the active table. Identical configurations merge in the cart. The order panel supports notes, quantities, a fixed or percentage discount, a demo coupon (`FOODZY100`), tax calculation, split payment, and checkout. Sending to kitchen creates tickets only for quantities not already sent. Payment creates a receipt in order history and updates the open shift amount. The other navigation areas expose populated demo views.

The active table and draft carts are stored locally with `shared_preferences`. In live mode, sending an order to the kitchen creates a backend order and KOT, while checkout records a manually confirmed tender through the backend. The current payment API records cash, card, UPI, bank transfer, or other tender confirmation; it does not initiate an external payment gateway charge. Demo mode continues to use in-memory data.

## Structure

- `lib/app`: theme and routing
- `lib/core`: money formatting
- `lib/features/pos/domain`: typed models and billing calculations
- `lib/features/pos/data`: local menu and demo records
- `lib/features/pos/presentation`: state, screen widgets, and supporting views
- `assets/images`: bundled food and beverage photography sheets
- `test`: billing, controller, and responsive widget checks

The domain and presentation layers use integer paise for authoritative totals. Discount is applied before tax; tax is rounded to the nearest whole rupee for display and payment. The demo starts with a ₹1,265 subtotal, ₹100 discount, ₹58 tax, and ₹1,223 payable.
