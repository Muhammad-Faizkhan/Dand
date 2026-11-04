# Screens & navigation

71 named routes in `core/routes/app_routes.dart`, wired in `route_generator.dart`.

## Flow

```
/  splash
└── /onboarding  (3 pages, Skip)
    └── /login ──────────────► /main                    (Log In)
        ├── /forgot-password → /enter-otp → /create-new-password → /login
        └── /create-account → /verify-email → /enter-code → /congratulations
                                                           ├── /what-you-collect → /profile-completed → /main
                                                           └── /choose-plan → /plan-payment → /subscribed → /main
```

### `/main` — tab shell

| Tab | Screen | Reaches |
|---|---|---|
| Home | `HomeScreen` | side menu, `/messages`, `/notifications`, `/trade-matches`, `/wishlist`, `/item-detail` |
| Market | `MarketplaceScreen` | `/search`, `/filters`, `/item-detail`, `/auction-detail`, Map tab |
| Map | `MapScreen` | `/map-dealers` |
| Profile | `ProfileScreen` | `/settings`, `/edit-profile`, `/collections` |
| "+" | — | `/add-item` |

Side menu → Orders, Collections, Wish list, Order Request, Activity, Subscription Plan,
Payment Method, Settings, Log Out.

### Buy

```
/item-detail ──"I WANT THIS"──► get-item sheet
                                ├── Propose Trade → /propose-trade
                                └── Place an Order → /shipping → /checkout → /order-placed → /track-order
```

### Trade

```
/trade-matches → /propose-trade ⇄ /add-to-trade
                 └── /review-confirm → /trade-sent
/trade-completed   /trade-confirmed   /trade-rejected
```

Reached from Orders ▸ Trade, My Activity and the "accepted your trade" notification.

### Auctions

```
/auction-detail → /place-bid → /bid-placed
/auction-winner    /auction-lost
```

Outcomes are reached from Orders ▸ Auction, My Activity and the "outbid" notification.

### Sell

```
/add-item (camera / upload) → /item-form → /main
/collections ──"+"──► /create-category
/event-detail ──"+"──► /add-to-collection
```

### Orders

```
/order-requests ├── Received → /confirm-request → /request-sent | /order-rejected
                └── Sent     → /request-sent
/orders-purchase  /orders-trade   (Orders · Trade · Auction tabs)
```

### Settings

```
/settings ├── /push-notifications
          ├── /change-password → /thank-you-password → /login
          ├── /trade-preferences → /edit-collect
          ├── /privacy-policy   /terms
          └── /help-feedback → /thank-you-feedback
/payment-methods → /add-card → /card-added
                 └── /manage-card
```

### Profile

```
side menu avatar → /my-profile → /edit-profile
/collections → /event-detail
/item-detail seller → /seller-profile     /my-activity
profile "Trades" stat → /orders-trade
```

Every route in `AppRoutes` has a screen behind it and at least one screen that
navigates to it; `test/route_coverage_test.dart` fails if either stops being true.

## Route reference

| Route | Screen | Notes |
|---|---|---|
| `/` | `SplashScreen` | |
| `/onboarding` | `OnboardingScreen` | `PageView`, 3 pages |
| `/login` | `LoginScreen` | |
| `/create-account` | `CreateAccountScreen` | avatar picker |
| `/verify-email` | `VerifyEmailScreen` | step 2/3 |
| `/enter-code` | `EnterCodeScreen` | step 3/3 |
| `/enter-otp` | `EnterCodeScreen(isReset: true)` | password reset |
| `/forgot-password` | `ForgotPasswordScreen` | |
| `/create-new-password` | `CreateNewPasswordScreen` | |
| `/congratulations` | `CongratulationsScreen` | trial modal |
| `/choose-plan` | `ChoosePlanScreen` | Free / Silver / Gold / Platinum |
| `/plan-payment` | `PlanPaymentScreen` | blue flow |
| `/subscribed` | `SubscribedScreen` | |
| `/what-you-collect` | `WhatYouCollectScreen` | |
| `/edit-collect` | `WhatYouCollectScreen(isEdit: true)` | from settings |
| `/profile-completed` | `ProfileCompletedScreen` | |
| `/main` | `MainScaffold` | tab shell + drawer |
| `/filters` | `FiltersScreen` | sliders, pills |
| `/search` | `SearchScreen` | live results |
| `/wishlist` | `WishlistScreen` | |
| `/notifications` | `NotificationsScreen` | Today / Earlier; each tile opens its subject |
| `/map-dealers` | `MapDealersScreen` | map + dealer sheet |
| `/trade-matches` | `TradeMatchesScreen` | |
| `/propose-trade` | `ProposeTradeScreen` | takes `ChipItem` |
| `/add-to-trade` | `AddToTradeScreen` | |
| `/review-confirm` | `ReviewConfirmScreen` | |
| `/trade-sent` `/trade-completed` | `TradeSentScreen` | |
| `/trade-confirmed` `/trade-rejected` | `TradeOutcomeScreen` | |
| `/item-detail` | `ItemDetailScreen` | takes `ChipItem` |
| `/shipping` `/checkout` | `ShippingScreen` `CheckoutScreen` | blue CTAs |
| `/order-placed` `/track-order` | `OrderPlacedScreen` `TrackOrderScreen` | timeline |
| `/auction-detail` | `AuctionDetailScreen` | bid history |
| `/place-bid` `/bid-placed` | `PlaceBidScreen` `BidPlacedScreen` | |
| `/auction-winner` `/auction-lost` | `AuctionOutcomeScreen` | |
| `/messages` `/chat` | `MessagesScreen` `ChatScreen` | chat takes a user name |
| `/my-profile` `/edit-profile` `/seller-profile` | profile screens | |
| `/collections` `/event-detail` `/my-activity` | collection screens | |
| `/add-item` `/item-form` | sell flow | camera / picker |
| `/create-category` `/add-to-collection` | `CollectionFormScreen` | |
| `/settings` and children | settings screens | |
| `/payment-methods` `/add-card` `/card-added` `/manage-card` | card screens | |
| `/order-requests` `/confirm-request` `/request-sent` `/order-rejected` | request screens | |
| `/orders-purchase` `/orders-trade` | `OrdersScreen` | |
