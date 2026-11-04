import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'controllers/app_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/collections_controller.dart';
import 'controllers/dealers_controller.dart';
import 'controllers/rewards_controller.dart';
import 'controllers/notifications_controller.dart';
import 'controllers/user_controller.dart';
import 'core/api/api_client.dart';
import 'core/api/auth_api.dart';
import 'core/api/token_store.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/route_generator.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/responsive.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF070709),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  final client = ApiClient(tokens: SecureTokenStore());
  final authApi = AuthApi(client);
  // Only a local check, so launch never waits on the network. If the saved
  // session turns out to be dead, the first request sends the user to login.
  final signedIn = await authApi.hasSession;
  runApp(DanDCollectionApp(client: client, authApi: authApi, signedIn: signedIn));
}

final _navigatorKey = GlobalKey<NavigatorState>();

class DanDCollectionApp extends StatelessWidget {
  const DanDCollectionApp({super.key, required this.client, required this.authApi, this.signedIn = false});

  final ApiClient client;
  final AuthApi authApi;
  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    client.onSessionExpired = () =>
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRoutes.login, (r) => r.settings.name == AppRoutes.splash);

    final userCtrl = UserController(client: client);
    final marketCtrl = MarketplaceController(client: client);
    final collectCtrl = CollectionsController(client: client);
    final notifCtrl = NotificationsController(client: client);
    final chatCtrl = ChatController(client: client);
    final tradeCtrl = TradeController(client: client);
    final wishCtrl = WishlistController(client: client);
    final settingsCtrl = SettingsController(client: client);

    void onSignedIn() {
      userCtrl.load().then((_) {
        // These need the user id.
        final uid = userCtrl.userId;
        if (uid > 0) {
          tradeCtrl.loadTrades(uid);
          tradeCtrl.loadMyItems(uid);
          chatCtrl.loadConversations(uid);
        }
      });
      marketCtrl.load();
      collectCtrl.load();
      notifCtrl.load();
      wishCtrl.load();
      settingsCtrl.load();
      tradeCtrl.loadMatches();
    }

    // If a valid session token already existed, kick off the loads now.
    if (signedIn) onSignedIn();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController(api: authApi, onSignedIn: onSignedIn)),
        ChangeNotifierProvider.value(value: userCtrl),
        ChangeNotifierProvider(create: (_) => NavController()),
        ChangeNotifierProvider.value(value: marketCtrl),
        ChangeNotifierProvider.value(value: wishCtrl),
        ChangeNotifierProvider.value(value: tradeCtrl),
        ChangeNotifierProvider(create: (_) => CheckoutController()),
        ChangeNotifierProvider(create: (_) => AuctionController(client: client)),
        ChangeNotifierProvider.value(value: chatCtrl),
        ChangeNotifierProvider.value(value: settingsCtrl),
        ChangeNotifierProvider(create: (_) => SellController(client: client)),
        ChangeNotifierProvider(create: (_) => ProfileController(client: client)),
        ChangeNotifierProvider.value(value: collectCtrl),
        ChangeNotifierProvider.value(value: notifCtrl),
        ChangeNotifierProvider(create: (_) => DealersController(client: client)),
        ChangeNotifierProvider(create: (_) => RewardsController(client: client)),
      ],
      child: ResponsiveScreenUtil(
        builder: (context, child) => MaterialApp(
          title: 'DAN D COLLECTION',
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          initialRoute: signedIn ? AppRoutes.main : AppRoutes.splash,
          onGenerateRoute: RouteGenerator.generate,
        ),
      ),
    );
  }
}

/// Initialises `flutter_screenutil` with a design size chosen for the viewport
/// the app actually finds itself in, and re-chooses it whenever that changes.
///
/// `ScreenUtilInit` takes its design size once, at construction. That is all a
/// phone-only app needs, but it is what makes a fixed design size scale a
/// phone layout to 2.1x on a tablet. Recomputing it here — via
/// [AppResponsive.designSizeFor] — is what gives every `.w`, `.h`, `.sp` and
/// `.r` in the app its tablet behaviour, without a single call site changing.
///
/// Rebuilding on [didChangeMetrics] covers rotation, iPad multitasking and
/// desktop window resizing.
class ResponsiveScreenUtil extends StatefulWidget {
  const ResponsiveScreenUtil({super.key, required this.builder});

  final Widget Function(BuildContext context, Widget? child) builder;

  @override
  State<ResponsiveScreenUtil> createState() => _ResponsiveScreenUtilState();
}

class _ResponsiveScreenUtilState extends State<ResponsiveScreenUtil> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final view = View.maybeOf(context);
    final size = view == null ? AppResponsive.phoneDesign : MediaQueryData.fromView(view).size;

    return ScreenUtilInit(
      designSize: AppResponsive.designSizeFor(size),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: widget.builder,
    );
  }
}
