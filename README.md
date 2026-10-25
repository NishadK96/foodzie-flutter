# Foodzy Restaurant POS

A Flutter demo of the Foodzy cashier experience, built for desktop, web, and tablet layouts. It uses local mock data and does not connect to the Foodzy backend yet.

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

The sign-in screen uses the backend's rotating access/refresh token flow. Tokens are stored with `flutter_secure_storage` (Windows Credential Manager on Windows), refreshed automatically after an authenticated `401`, and removed on sign-out. After login, the menu categories, items, and tables are loaded from the active branch using `X-Branch-ID`. Use **Continue with demo data** when the backend is unavailable or has no demonstration catalog.

For Windows, use `flutter run -d windows` on a Windows machine with the Flutter desktop toolchain installed. For a Windows executable, run `flutter build windows` there. You can also run `flutter run -d macos` or `flutter run -d android` on supported hosts.

## Validate

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Demo workflow

The app opens to Table 08 with a populated order. Search or filter the 60-item menu, customize a dish, and add it to the active table. Identical configurations merge in the cart. The order panel supports notes, quantities, a fixed or percentage discount, a demo coupon (`FOODZY100`), tax calculation, split payment, and checkout. Sending to kitchen creates tickets only for quantities not already sent. Payment creates a receipt in order history and updates the open shift amount. The other navigation areas expose populated demo views.

The active table and draft carts are stored locally with `shared_preferences`. Product data, orders, tables, kitchen tickets, and payment outcomes are mock data or in-memory state. Payment controls simulate a transaction and never charge a real payment method.

## Structure

- `lib/app`: theme and routing
- `lib/core`: money formatting
- `lib/features/pos/domain`: typed models and billing calculations
- `lib/features/pos/data`: local menu and demo records
- `lib/features/pos/presentation`: state, screen widgets, and supporting views
- `assets/images`: bundled food and beverage photography sheets
- `test`: billing, controller, and responsive widget checks

The domain and presentation layers use integer paise for authoritative totals. Discount is applied before tax; tax is rounded to the nearest whole rupee for display and payment. The demo starts with a ₹1,265 subtotal, ₹100 discount, ₹58 tax, and ₹1,223 payable.
