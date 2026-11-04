import 'package:flutter/material.dart';
import '../../core/utils/app_data.dart';
import '../../models/models.dart';
import '../../views/auctions/auction_detail_screen.dart';
import '../../views/auctions/auction_result_screens.dart';
import '../../views/auctions/place_bid_screen.dart';
import '../../views/auth/create_account_screen.dart';
import '../../views/auth/create_new_password_screen.dart';
import '../../views/auth/enter_code_screen.dart';
import '../../views/auth/forgot_password_screen.dart';
import '../../views/auth/login_screen.dart';
import '../../views/auth/verify_email_screen.dart';
import '../../views/buy/checkout_screen.dart';
import '../../views/buy/order_placed_screen.dart';
import '../../views/buy/shipping_screen.dart';
import '../../views/buy/track_order_screen.dart';
import '../../views/item/item_detail_screen.dart';
import '../../views/main/filters_screen.dart';
import '../../views/main/main_shell.dart';
import '../../views/main/map_dealers_screen.dart';
import '../../views/main/notifications_screen.dart';
import '../../views/main/profile_screen.dart';
import '../../views/main/search_screen.dart';
import '../../views/main/wishlist_screen.dart';
import '../../views/messaging/chat_screen.dart';
import '../../views/messaging/messages_screen.dart';
import '../../views/onboarding/onboarding_screen.dart';
import '../../views/orders/orders_screens.dart';
import '../../views/rewards/rewards_screens.dart';
import '../../views/profile/collections_screen.dart';
import '../../views/profile/edit_profile_screen.dart';
import '../../views/profile/my_activity_screen.dart';
import '../../views/profile/seller_profile_screen.dart';
import '../../views/sell/add_item_screen.dart';
import '../../views/sell/item_form_screen.dart';
import '../../views/settings/help_feedback_screen.dart';
import '../../views/settings/payment_screens.dart';
import '../../views/settings/preference_screens.dart';
import '../../views/settings/settings_screen.dart';
import '../../views/settings/thank_you_screen.dart';
import '../../views/onboarding/splash_screen.dart';
import '../../views/setup/choose_plan_screen.dart';
import '../../views/setup/congratulations_screen.dart';
import '../../views/setup/plan_payment_screen.dart';
import '../../views/setup/profile_completed_screen.dart';
import '../../views/setup/subscribed_screen.dart';
import '../../views/setup/what_you_collect_screen.dart';
import '../../views/trading/add_to_trade_screen.dart';
import '../../views/trading/propose_trade_screen.dart';
import '../../views/trading/review_confirm_screen.dart';
import '../../views/trading/trade_matches_screen.dart';
import '../../views/trading/trade_result_screens.dart';
import '../../widgets/app_background.dart';
import 'app_routes.dart';

class RouteGenerator {
  RouteGenerator._();

  static Route<dynamic> generate(RouteSettings settings) =>
      MaterialPageRoute(builder: (_) => screenFor(settings), settings: settings);

  /// The screen behind a route name, or [UnknownRouteScreen] if there is none.
  static Widget screenFor(RouteSettings settings) {
    final args = settings.arguments;
    ChipItem chip(ChipItem fallback) => args is ChipItem ? args : fallback;

    final Widget page = switch (settings.name) {
      // Onboarding + auth
      AppRoutes.splash => const SplashScreen(),
      AppRoutes.onboarding => const OnboardingScreen(),
      AppRoutes.login => const LoginScreen(),
      AppRoutes.createAccount => const CreateAccountScreen(),
      AppRoutes.verifyEmail => const VerifyEmailScreen(),
      AppRoutes.enterCode => const EnterCodeScreen(),
      AppRoutes.enterOtp => const EnterCodeScreen(isReset: true),
      AppRoutes.forgotPassword => const ForgotPasswordScreen(),
      AppRoutes.createNewPassword => const CreateNewPasswordScreen(),

      // Setup
      AppRoutes.congratulations => const CongratulationsScreen(),
      AppRoutes.choosePlan => const ChoosePlanScreen(),
      AppRoutes.planPayment => PlanPaymentScreen(plan: args is PlanModel ? args : null),
      AppRoutes.subscribed => const SubscribedScreen(),
      AppRoutes.whatYouCollect => const WhatYouCollectScreen(),
      AppRoutes.editCollect => const WhatYouCollectScreen(isEdit: true),
      AppRoutes.profileCompleted => const ProfileCompletedScreen(),

      // Shell + core
      AppRoutes.main => const MainScaffold(),
      AppRoutes.filters => const FiltersScreen(),
      AppRoutes.mapDealers => const MapDealersScreen(),
      AppRoutes.wishlist => const WishlistScreen(),
      AppRoutes.search => const SearchScreen(),
      AppRoutes.notifications => const NotificationsScreen(),

      // Trading
      AppRoutes.tradeMatches => const TradeMatchesScreen(),
      AppRoutes.proposeTrade => ProposeTradeScreen(target: args is ChipItem ? args : null),
      AppRoutes.addToTrade => const AddToTradeScreen(),
      AppRoutes.reviewConfirm => const ReviewConfirmScreen(),
      AppRoutes.tradeSent => TradeSentScreen(trade: args is ApiTradeRequest ? args : null),
      AppRoutes.tradeCompleted => TradeSentScreen(completed: true, trade: args is ApiTradeRequest ? args : null),
      AppRoutes.tradeConfirmed => TradeOutcomeScreen(rejected: false, trade: args is ApiTradeRequest ? args : null),
      AppRoutes.tradeRejected => TradeOutcomeScreen(rejected: true, trade: args is ApiTradeRequest ? args : null),

      // Item + buy
      AppRoutes.itemDetail => ItemDetailScreen(item: chip(AppData.yankeeBristol)),
      AppRoutes.shipping => const ShippingScreen(),
      AppRoutes.checkout => const CheckoutScreen(),
      AppRoutes.orderPlaced => const OrderPlacedScreen(),
      AppRoutes.trackOrder => const TrackOrderScreen(),

      // Auctions
      AppRoutes.auctionDetail => AuctionDetailScreen(item: chip(AppData.bourbonSpecial)),
      AppRoutes.placeBid => PlaceBidScreen(item: chip(AppData.bourbonSpecial)),
      AppRoutes.bidPlaced => BidPlacedScreen(item: args is ChipItem ? args : null),
      AppRoutes.auctionWinner => const AuctionOutcomeScreen(won: true),
      AppRoutes.auctionLost => const AuctionOutcomeScreen(won: false),

      // Messaging
      AppRoutes.messages => const MessagesScreen(),
      AppRoutes.chat => args is ChatThread
          ? ChatScreen(user: args.name, thread: args)
          : ChatScreen(user: args is String ? args : 'ChipKing92'),

      // Profile
      AppRoutes.myProfile => const AppScaffold(body: ProfileScreen(showBack: true)),
      AppRoutes.editProfile => const EditProfileScreen(),
      AppRoutes.sellerProfile => switch (args) {
        final ({int id, String name}) s => SellerProfileScreen(name: s.name, userId: s.id),
        final String name => SellerProfileScreen(name: name),
        _ => const SellerProfileScreen(),
      },
      AppRoutes.collections => const CollectionsScreen(),
      AppRoutes.eventDetail => args is ApiCollection
          ? EventDetailScreen(collection: args)
          : EventDetailScreen(eventName: args is String ? args : 'Event 5'),
      AppRoutes.myActivity => const MyActivityScreen(),

      // Sell
      AppRoutes.addItem => const AddItemScreen(),
      AppRoutes.itemForm => const ItemFormScreen(),
      AppRoutes.createCategory => const CollectionFormScreen(isCategory: true),
      AppRoutes.addToCollection => const CollectionFormScreen(isCategory: false),

      // Settings
      AppRoutes.settings => const SettingsScreen(),
      AppRoutes.pushNotifications => const PushNotificationsScreen(),
      AppRoutes.tradePreferences => const TradePreferencesScreen(),
      AppRoutes.changePassword => const ChangePasswordScreen(),
      AppRoutes.privacyPolicy => const PolicyScreen(title: 'Privacy Policy'),
      AppRoutes.terms => const PolicyScreen(title: 'Terms & Condition'),
      AppRoutes.helpFeedback => const HelpFeedbackScreen(),
      AppRoutes.thankYouPassword => const ThankYouScreen(
        message: 'Your password has been changed\nsuccessfully!',
        buttonLabel: 'Login',
        goLogin: true,
      ),
      AppRoutes.thankYouFeedback => const ThankYouScreen(
        message: 'Your feedback has been submitted\nsuccessfully!',
        buttonLabel: 'Done',
      ),
      AppRoutes.paymentMethods => const PaymentMethodsScreen(),
      AppRoutes.addCard => const AddCardScreen(),
      AppRoutes.manageCard => const ManageCardScreen(),
      AppRoutes.cardAdded => const ThankYouScreen(
        message: 'Your card has been added\nsuccessfully!',
        buttonLabel: 'Done',
      ),

      // Orders
      AppRoutes.orderRequests => const OrderRequestsScreen(),
      AppRoutes.confirmRequest => const ConfirmRequestScreen(),
      AppRoutes.requestSent => const RequestResultScreen(rejected: false),
      AppRoutes.orderRejected => const RequestResultScreen(rejected: true),
      AppRoutes.ordersPurchase => const OrdersScreen(),
      AppRoutes.ordersTrade => const OrdersScreen(initialTab: 1),
      AppRoutes.wallet => const WalletScreen(),
      AppRoutes.walletHistory => const TransactionHistoryScreen(),
      AppRoutes.leaderboard => const LeaderboardScreen(),
      AppRoutes.dealerRanking => const DealerRankingScreen(),
      AppRoutes.chipStore => const ChipStoreScreen(),

      _ => UnknownRouteScreen(name: settings.name ?? '?'),
    };

    return page;
  }
}

/// Fallback for a name that has no screen. Nothing in [AppRoutes] should reach
/// it — `route_coverage_test.dart` fails if one does.
class UnknownRouteScreen extends StatelessWidget {
  const UnknownRouteScreen({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(name, style: const TextStyle(color: Colors.white70)),
            TextButton(onPressed: () => Navigator.maybePop(context), child: const Text('Back')),
          ],
        ),
      ),
    );
  }
}
