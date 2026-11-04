# DAN D COLLECTION

A Flutter implementation of the **DAN D COLLECTION** Figma design — a marketplace for
collectible Harley-Davidson / casino chips, covering cataloguing, trading, buying,
auctions, messaging and dealer discovery.

The UI is a screen-for-screen rebuild of the Figma file, laid out against the design's
390 × 844 frame and verified against the exported design frames.

---

## Quick start

```bash
flutter pub get
flutter run                 # any connected device or simulator
```

Requires Flutter **3.41+** / Dart **3.11+**.

```bash
flutter analyze             # static analysis — currently clean
flutter test                # 68 rendering tests
flutter test --update-goldens   # refresh test/goldens/*.png
```

---

## What's implemented

| Area | Screens |
|---|---|
| Onboarding | Splash, 3-page onboarding carousel |
| Auth | Login, Create account, Verify email, Enter code, Forgot password, Enter OTP, Create new password |
| Setup | Congratulations, Choose your plan, Plan payment, Successfully subscribed, What do you collect, Profile completed |
| Core shell | Home, Marketplace, Map, Profile (+ side menu drawer) |
| Discovery | Filters, Search, Wishlist, Notifications, Map dealers list |
| Trading | Trade matches, Propose trade, Add to trade, Review & confirm, Trade sent / completed / confirmed / rejected |
| Item & buy | Item detail, Get-item sheet, Shipping, Payment, Order placed, Track order |
| Auctions | Auction detail, Place your bid, Bid placed, Auction winner, Auction lost |
| Messaging | Messages list, Chat thread |
| Profile | My profile, Edit profile, Seller profile, Collections, Event detail, My activity |
| Sell | Add item (camera scan), Item details form, Create category, Add to collection |
| Settings | Settings, Push notifications, Trade preferences, Change password, Privacy policy, Terms, Help & feedback, Thank-you screens, Payment methods, Add card, Manage card |
| Orders | Order requests, Confirm request, Request sent, Order rejected, Orders (purchase / trade / auction) |

Every screen is reachable through the app's own navigation — the whole flow can be
walked end to end from the splash screen.

## Working features

- **Map** — `flutter_map` with keyless OpenStreetMap raster tiles, colour-inverted to the
  design's dark basemap. Pan, pinch-zoom and tappable dealer pins all work. A dealer
  bottom-sheet screen mirrors the "Dealers near you" frame.
- **Camera / photo library** — `image_picker` drives *Take Photo* and *Upload* on the
  Add Item screen, the avatar picker on Edit Profile, and the attachment picker on
  Help & Feedback. iOS usage strings and Android permissions are configured.
- **Interactions** — tab navigation, drawer, bottom sheets, filter pills, range sliders,
  toggles, OTP entry, quantity/bid steppers, segmented tabs, wishlist favouriting,
  trade basket building, chat sending.

---

## Stack

| Concern | Choice |
|---|---|
| Responsive sizing | `flutter_screenutil` — `designSize: Size(390, 844)` |
| State management | `provider` (`ChangeNotifier` controllers) |
| Architecture | MVC — `models/`, `views/`, `controllers/` |
| Navigation | Named routes via `onGenerateRoute` |
| Map | `flutter_map` + `latlong2` |
| Media | `image_picker` |
| Type | Inter (bundled, weights 400–800) |

Start at [`docs/current/00-INDEX.md`](docs/current/00-INDEX.md), which says what
to trust first. From there:
[`ARCHITECTURE.md`](docs/current/ARCHITECTURE.md) for the layer breakdown,
[`DESIGN_SYSTEM.md`](docs/current/DESIGN_SYSTEM.md) for tokens and components,
[`SCREENS.md`](docs/current/SCREENS.md) for the route map, and
[`RESPONSIVE.md`](docs/current/RESPONSIVE.md) for how sizing works across phones
and tablets — read that one before touching any layout. Session logs record what
changed when; superseded docs live in [`docs/archive/`](docs/archive/).

---

## Design fidelity

Assets are taken from the design itself — the background texture, the DAN D logo, all
chip photography, event posters, avatars, feedback illustrations and the bottom-navigation
glyphs were extracted from the Figma export and live in `assets/images/`.

Layout was verified numerically rather than by eye. `test/screens_golden_test.dart`
renders every route at the exact Figma frame size (390 × 844 @3x, 47pt status-bar inset)
and writes a PNG per screen to `test/goldens/`. Those PNGs were measured against the
design exports — element positions and text widths were compared and the type scale,
header offsets and spacing were corrected until they lined up. Headers now land within
about half a point of the design, and title/body text widths sit within ~2%.

To re-verify after a change:

```bash
flutter test --update-goldens
# then diff test/goldens/<screen>.png against the design frame
```

### Known deviations

These are deliberate, and each has a reason:

1. **Status bar.** The design frames draw a mock iOS status bar ("9:41"). The app lets the
   OS draw the real one and offsets content by the same 47pt, so the result is identical
   on device with a live clock.
2. **Bottom navigation.** Most frames show *Home · Market · Map · Profile*; a few
   (My Profile, Collections) show *Home · Market · Messages · Profile*. The four-tab
   Map variant is used throughout for consistency; Messages is reached from the Home
   header icon, which the design also provides.
3. **Messages back arrow.** The design frame has no back affordance because it sits on a
   tab; here it is pushed from the Home header, so a back arrow was added.
4. **Map attribution.** A small "© OpenStreetMap" credit is required by the OSM tile
   usage policy, so it appears bottom-left over the map.
5. **Platinum plan.** The Choose-your-plan frames cut off before the Platinum tier's
   price and item allowance. `$19.99/year · 1000 items` is used as a placeholder —
   confirm the intended values and update `AppData.plans`.
6. **OTP keypad.** The design shows six code boxes with no visible keypad; the boxes are
   wired to the system keyboard through a transparent field.

### Scope

This is the **UI build** that was asked for: presentation, navigation and interaction are
complete, backed by seeded data in `lib/core/utils/app_data.dart`. There is no backend,
authentication, payment processing or persistence — the controllers are structured so a
data layer can be dropped in behind them without touching the views.
