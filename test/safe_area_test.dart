import 'package:dandcollection/controllers/auth_controller.dart';
import 'package:dandcollection/core/routes/app_routes.dart';
import 'package:dandcollection/core/routes/route_generator.dart';
import 'package:dandcollection/core/theme/app_theme.dart';
import 'package:dandcollection/widgets/buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// The splash and onboarding CTAs are absolutely positioned, so they are the
/// two that can slide under the home indicator on a screen the design did not
/// account for. Pin them at the sizes real hardware reports.
void main() {
  const devices = <String, (Size, double, double)>{
    'design 390x844': (Size(390, 844), 47, 34),
    'iPhone 16 393x852': (Size(393, 852), 59, 34),
    'iPhone 16 Pro Max 440x956': (Size(440, 956), 62, 34),
    'small android 360x640': (Size(360, 640), 24, 0),
    'android 3-button 412x892': (Size(412, 892), 43, 48),
  };

  for (final route in [AppRoutes.splash, AppRoutes.onboarding]) {
    devices.forEach((label, spec) {
      final (size, top, bottom) = spec;
      testWidgets('$route CTA clears the bottom inset at $label', (tester) async {
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3.0;
        tester.view.padding = FakeViewPadding(top: top * 3, bottom: bottom * 3);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MultiProvider(
            providers: [ChangeNotifierProvider(create: (_) => AuthController())],
            child: ScreenUtilInit(
              designSize: const Size(390, 844),
              minTextAdapt: true,
              builder: (context, child) => MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.dark,
                initialRoute: route,
                onGenerateRoute: RouteGenerator.generate,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 60));

        final cta = tester.getRect(find.byType(PrimaryButton).first);
        expect(
          cta.bottom,
          lessThanOrEqualTo(size.height - bottom),
          reason: 'CTA runs into the home indicator / navigation bar',
        );
        expect(cta.top, greaterThan(top), reason: 'CTA runs into the status bar');
      });
    });
  }
}
