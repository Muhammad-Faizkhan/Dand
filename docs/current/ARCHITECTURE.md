# Architecture

The project follows an **MVC** split. Views never own domain state; controllers never
build widgets.

```
lib/
├── main.dart                  # providers + ScreenUtilInit + MaterialApp
├── models/
│   └── models.dart            # ChipItem, Seller, TradeMatch, Dealer, ChatThread,
│                              # ChatMessage, AppNotification, OrderModel, PaymentCard,
│                              # PlanModel, CollectionEvent, ActivityEntry, enums
├── controllers/               # ChangeNotifier — the "C" layer
│   ├── auth_controller.dart
│   └── app_controller.dart    # Nav, Marketplace, Wishlist, Trade, Checkout,
│                              # Auction, Chat, Settings, Sell
├── views/                     # screens, grouped by feature
│   ├── onboarding/  auth/  setup/  main/  trading/
│   ├── item/  buy/  auctions/  messaging/
│   └── profile/  sell/  settings/  orders/
├── widgets/                   # reusable presentation components
└── core/
    ├── constants/             # app_colors, app_text_styles, app_assets
    ├── theme/                 # app_theme
    ├── routes/                # app_routes (names) + route_generator (wiring)
    └── utils/                 # app_data (seed content), layout (frame maths)
```

## Controllers

Registered once in `main.dart` via `MultiProvider`. Views read them with
`context.watch` / `context.read`, or `Consumer` where only a subtree should rebuild.

| Controller | Responsibility |
|---|---|
| `AuthController` | Sign-up / sign-in fields, OTP value, onboarding page, collecting interests, selected plan |
| `NavController` | Bottom-tab index for the shell |
| `MarketplaceController` | Category filter, search query, price/distance/rarity/condition filters |
| `WishlistController` | Saved items, `toggle()` / `contains()` |
| `TradeController` | Trade basket — what you give, the target item, the note |
| `CheckoutController` | Shipping address fields, shipping method, card selection, totals |
| `AuctionController` | Current bid, bid count, the user's bid and increments |
| `ChatController` | Per-thread message lists and sending |
| `SettingsController` | Notification and trade-preference toggles |
| `SellController` | Captured photo path, listing type, form fields |

## Navigation

Every destination is a constant in `core/routes/app_routes.dart`; `RouteGenerator.generate`
maps names to widgets in a single `switch`, so the whole graph is readable in one place.

Arguments are passed positionally through `RouteSettings.arguments` and narrowed at the
switch — a `ChipItem` for item/auction routes, a `String` for chat and event names — with
a seeded fallback so every route is also reachable directly (which is what the golden
test harness relies on).

## Responsive sizing

`ScreenUtilInit(designSize: Size(390, 844))` — the Figma frame. Widths use `.w`, heights
`.h`, radii `.r`, type `.sp`.

Figma Y-coordinates include the 47pt status bar, but screens render inside a `SafeArea`.
`AppLayout.top(designY)` bridges the two:

```dart
static const double statusBar = 47;
static double top(double designY) => (designY - statusBar).h;
```

so a header measured at y=67 in Figma is written as `AppLayout.top(67)`.
`AppLayout.gutter` is the standard 22pt page padding.

## Rendering tests

`test/screens_golden_test.dart` loads the bundled Inter weights plus the Material icon
font, sets a 390 × 844 @3x view with a 47pt top inset, pumps each route, pre-caches its
images and writes `test/goldens/<screen>.png`. It doubles as a regression suite (a layout
overflow fails the test) and as the comparison surface for design review.

The `/main` shell is covered by standalone `tab_home` / `tab_market` cases: its map tab
needs `path_provider`, which has no implementation in the test environment.
