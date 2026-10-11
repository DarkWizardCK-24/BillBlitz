<p align="center">
  <img src="assets/images/logo.png" alt="BillBlitz logo" width="128">
</p>

# BillBlitz ⚡

**Fast, clean billing for small shops.** BillBlitz is a Flutter + Firebase app for creating customer bills in seconds, saving them to the cloud, and printing or sharing them as professional PDF invoices. It runs on the web, Android, iOS and desktop from a single codebase.

<p align="center">
  <img src="docs/screenshots/07-desktop.png" alt="BillBlitz on desktop" width="760">
</p>

## 🎨 Logo and app icon

<p align="center">
  <img src="assets/images/logo.png" alt="BillBlitz logo (512 x 512)" width="200">
</p>

A torn-edge receipt struck by a lightning bolt: bills created in a flash. Royal purple with an amber bolt.

The logo is a 512 x 512 px image, used in the app's screens and as the launcher icon on Android, iOS and the web (Android gets an adaptive icon). It is drawn by code, so it can be tweaked and regenerated:

```bash
pip install pillow numpy
python tool/generate_logo.py        # writes assets/images/*.png
dart run flutter_launcher_icons     # applies the launcher icons to every platform
```

| File | Size | Use |
| --- | --- | --- |
| `assets/images/logo.png` | 512 x 512 | README and in-app logo |
| `assets/images/launcher_icon.png` | 1024 x 1024 | iOS and legacy Android icon |
| `assets/images/launcher_foreground.png` / `launcher_background.png` | 1024 x 1024 | Android adaptive icon layers |

## ✨ Features

- **Quick billing** – add items with price and quantity, adjust quantities with a `− / +` stepper, and remove an item with one tap (with **Undo**).
- **Live totals** – subtotal, discount %, taxable amount, tax % and grand total update as you type. All maths lives in one tested calculator, so what you see is exactly what is saved and printed.
- **Payment method** – record each bill as Cash, UPI or Card.
- **Cloud storage** – bills are stored in Cloud Firestore with safe, sequential IDs (`BILL-00000001`, `BILL-00000002`, …) that can never collide, even when several devices save at once.
- **Saved bills** – search by customer, phone or bill ID, see the number of bills and their total value, open any bill for the full breakdown, and delete it if needed.
- **PDF invoices** – print or share (WhatsApp, e-mail, save to files) a branded A4 invoice with your shop name, address and phone. Multi-page for long bills. Reprinting an old bill always reproduces the original (same date, rates and totals).
- **Shop settings** – set your shop details, default tax rate and footer message once; they are used on every bill.
- **Indian-friendly formatting** – `₹` currency with lakh/crore digit grouping (`₹12,34,567.50`).
- **Responsive** – the phone layout is untouched; on wide screens (web and Windows, 960 px and up) the bill editor becomes two columns, with the customer and items on the left and a running summary on the right.
- **Works offline-first for fonts** – Inter ships with the app, so screens and PDFs render without a network request.

## 📸 Screenshots

<table>
  <tr>
    <td align="center"><b>New bill</b></td>
    <td align="center"><b>Items &amp; customer</b></td>
    <td align="center"><b>Summary &amp; payment</b></td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/01-new-bill.png" alt="New bill screen" width="260"></td>
    <td><img src="docs/screenshots/02-bill-items.png" alt="Bill with items" width="260"></td>
    <td><img src="docs/screenshots/03-bill-summary.png" alt="Bill summary and payment method" width="260"></td>
  </tr>
  <tr>
    <td align="center"><b>Saved bills</b></td>
    <td align="center"><b>Bill details</b></td>
    <td align="center"><b>Shop settings</b></td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/04-saved-bills.png" alt="Saved bills list" width="260"></td>
    <td><img src="docs/screenshots/05-bill-details.png" alt="Bill details sheet" width="260"></td>
    <td><img src="docs/screenshots/06-shop-settings.png" alt="Shop settings" width="260"></td>
  </tr>
</table>

### On the web and Windows

<p align="center">
  <img src="docs/screenshots/07-desktop.png" alt="Two-column bill editor on desktop" width="520">
  &nbsp;
  <img src="docs/screenshots/09-desktop-saved-bills.png" alt="Saved bills on desktop" width="520">
</p>

## PDF invoice

<p align="center">
  <img src="docs/screenshots/08-pdf-invoice.png" alt="Generated PDF invoice" width="520">
</p>

> The screenshots are generated from the real widgets with sample data (see [Regenerating the screenshots](#-regenerating-the-screenshots)), so they always match the current UI.

## 🛠️ Tech stack

| Area | Choice |
| --- | --- |
| UI | Flutter (Material 3), Inter font bundled as an asset |
| Database | Cloud Firestore (`cloud_firestore`) |
| PDF | `pdf` + `printing` (print dialog and share sheet) |
| Local settings | `shared_preferences` |
| Formatting | `intl` |

## 🚀 Getting started

### Prerequisites

- Flutter SDK (3.8 or newer) – check with `flutter --version`
- A Firebase project with **Cloud Firestore** enabled

### Setup

```bash
git clone <your-repo-url>
cd BillBlitz
flutter pub get

# Connect your own Firebase project (regenerates lib/firebase_options.dart)
dart pub global activate flutterfire_cli
flutterfire configure

flutter run            # pick a device, or: flutter run -d chrome
flutter run -d windows # Windows desktop app
flutter build windows --release   # -> build\windowsdunner\Release\
```

### Firestore rules

The app uses two collections: `bills` and `counters` (a single `counters/bills` document that hands out the next bill number).

> ⚠️ BillBlitz does not have a sign-in screen yet, so the app talks to Firestore anonymously. Only use open rules for local testing. Before going live, add Firebase Authentication and lock the rules down, for example:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /bills/{bill}     { allow read, write: if request.auth != null; }
    match /counters/{doc}   { allow read, write: if request.auth != null; }
  }
}
```

**Upgrading from an older version?** Existing bills keep working. On the first save the counter starts after your highest existing `BILL-xxxxxxxx` ID, and older bills without a stored payment method or rates are shown as *Cash* with rates derived from their amounts.

### First run checklist

1. Open **Shop settings** (store icon, top right) and enter your shop name, address, phone and default tax rate.
2. Create a bill and tap **Save & Print**.

## 🗂️ Project structure

```
lib/
├── main.dart                     # App entry, Firebase init, wiring
├── theme/app_theme.dart          # Colours, Material theme, gradient header
├── models/                       # Bill, BillingItem, PaymentMethod, ShopProfile
├── services/
│   ├── bill_repository.dart      # BillRepository interface + Firestore implementation
│   └── shop_profile_store.dart   # Shop details (shared_preferences)
├── utils/
│   ├── bill_calculator.dart      # Single source of truth for totals
│   ├── formatters.dart           # ₹ / date formatting
│   ├── pdf_bill_generator.dart   # Build / print / share the PDF invoice
│   └── snackbar.dart             # One helper for all snackbars
├── screens/                      # Billing, Saved bills, Shop settings
└── widgets/                      # Section card, add-item form, item list, summary, bill sheet
assets/fonts/                     # Inter (SIL OFL licence included)
test/                             # Unit + widget tests, fake repository, screenshot generator
tool/pdf_to_png.py                # Rasterises the sample PDF for the README
```

The screens only depend on the `BillRepository` interface, which is why they can be tested without Firebase.

## ✅ Tests

```bash
flutter analyze
flutter test
```

Covered: bill calculations (discount before tax, rounding, clamping), loading bills saved by older versions, the add-item validation, totals and quantity changes, undo on delete, saving (success and failure), and searching saved bills.

## 🖼️ Regenerating the screenshots

The screenshot test is skipped in a normal `flutter test`. To refresh `docs/screenshots/`:

```bash
flutter test test/screenshots --dart-define=SCREENSHOTS=true

# PDF page -> PNG (needs: pip install pymupdf)
python tool/pdf_to_png.py build/screenshots/invoice.pdf docs/screenshots/08-pdf-invoice.png
```

## 🔮 Ideas for later

- Firebase Authentication and per-user data
- GST split (CGST/SGST) and per-item tax rates
- Edit an existing bill and export bills to CSV
- Customer autocomplete and a sales dashboard

---

Built with 💥 by DarkWizardCK
