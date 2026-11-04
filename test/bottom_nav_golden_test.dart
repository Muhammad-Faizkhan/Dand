import 'dart:io';

import 'package:dandcollection/controllers/app_controller.dart';
import 'package:dandcollection/controllers/user_controller.dart';
import 'package:dandcollection/core/theme/app_theme.dart';
import 'package:dandcollection/views/main/home_screen.dart';
import 'package:dandcollection/widgets/app_background.dart';
import 'package:dandcollection/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Renders the bottom bar in each of its four states at the Figma frame size,
/// so `test/goldens/nav_*.png` can be measured against the design export.
///
/// The bottom view padding is set to the 19.8 the design frames leave for the
/// home indicator, so the bar comes out at its design height of 91 and the
/// goldens line up with the Figma frames row for row.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
      final loader = FontLoader('Inter')
        ..addFont(
          File('assets/fonts/Inter-$w.ttf').readAsBytes().then((b) => ByteData.view(b.buffer)),
        );
      await loader.load();
    }
    final iconFont = _materialIconFont();
    if (iconFont != null) {
      final icons = FontLoader('MaterialIcons')
        ..addFont(iconFont.readAsBytes().then((b) => ByteData.view(b.buffer)));
      await icons.load();
    }
  });

  for (var index = 0; index < kNavTabs.length; index++) {
    final name = kNavTabs[index].label.toLowerCase();
    testWidgets('render nav_$name', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 19.8 * 3);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => NavController()),
            ChangeNotifierProvider(create: (_) => UserController()),
            ChangeNotifierProvider(create: (_) => MarketplaceController()),
            ChangeNotifierProvider(create: (_) => WishlistController()),
            ChangeNotifierProvider(create: (_) => TradeController()),
          ],
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            minTextAdapt: true,
            builder: (context, child) => MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              home: AppScaffold(
                safeAreaTop: false,
                bottomNavigationBar: AppBottomNav(currentIndex: index, onTap: (_) {}, onAdd: () {}),
                body: HomeScreen(onMenu: () {}, onTab: (_) {}),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(() async {
        for (final element in find.byType(Image).evaluate()) {
          await precacheImage((element.widget as Image).image, element);
        }
        await Future<void>.delayed(const Duration(milliseconds: 60));
      });
      await tester.pumpAndSettle();

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/nav_$name.png'));
    });
  }

  // The indicator drifting off its icon was the original bug, so pin it at the
  // sizes a phone actually reports rather than only at the design frame.
  const sizes = <String, Size>{
    'design 390x844': Size(390, 844),
    'small 360x640': Size(360, 640),
    'tall 393x873': Size(393, 873),
    'large 430x932': Size(430, 932),
  };

  sizes.forEach((label, size) {
    for (var index = 0; index < kNavTabs.length; index++) {
      testWidgets('indicator is centred on ${kNavTabs[index].label} at $label', (tester) async {
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3.0;
        tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(390, 844),
            minTextAdapt: true,
            builder: (context, child) => MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              home: Scaffold(
                bottomNavigationBar: AppBottomNav(currentIndex: index, onTap: (_) {}, onAdd: () {}),
                body: const SizedBox.expand(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final indicator = tester.getCenter(find.byKey(const Key('nav-indicator')));
        final icon = tester.getCenter(
          find.descendant(
            of: find.byKey(Key('nav-tab-$index')),
            matching: find.byKey(const Key('nav-tab-icon')),
          ),
        );
        expect(indicator.dx, moreOrLessEquals(icon.dx, epsilon: 0.5));

        // ...and it stays on the top edge of the bar, not floating above it.
        final indicatorTop = tester.getTopLeft(find.byKey(const Key('nav-indicator'))).dy;
        final barTop = tester.getTopLeft(find.byType(AppBottomNav)).dy + 31.5.w;
        expect(indicatorTop, moreOrLessEquals(barTop, epsilon: 0.5));
      });
    }
  });
}

/// Locates the engine's bundled Material icon font so the "+" glyph renders as
/// a plus rather than tofu, whatever Flutter version is installed.
File? _materialIconFont() {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final roots = <String>[
    ?flutterRoot,
    '/opt/homebrew/Caskroom/flutter',
    '/usr/local/Caskroom/flutter',
  ];
  for (final root in roots) {
    final direct = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (direct.existsSync()) return direct;
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    for (final entry in dir.listSync()) {
      final nested = File(
        '${entry.path}/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      );
      if (nested.existsSync()) return nested;
    }
  }
  return null;
}
