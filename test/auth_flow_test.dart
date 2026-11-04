import 'package:dandcollection/controllers/auth_controller.dart';
import 'package:dandcollection/core/routes/app_routes.dart';
import 'package:dandcollection/core/routes/route_generator.dart';
import 'package:dandcollection/core/theme/app_theme.dart';
import 'package:dandcollection/widgets/app_text_field.dart';
import 'package:dandcollection/widgets/auth_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Future<void> _pumpRoute(WidgetTester tester, String route, AuthController auth) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ChangeNotifierProvider<AuthController>.value(
      value: auth,
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
  await tester.pump(const Duration(milliseconds: 50));
}

Finder get _otpField =>
    find.descendant(of: find.byType(OtpInput), matching: find.byType(EditableText));

void main() {
  group('OTP input', () {
    // Both entry points share EnterCodeScreen, so both are covered.
    for (final route in [AppRoutes.enterCode, AppRoutes.enterOtp]) {
      testWidgets('$route accepts, deletes and edits digits', (tester) async {
        final auth = AuthController()..setOtp('');
        addTearDown(auth.dispose);
        await _pumpRoute(tester, route, auth);

        await tester.enterText(_otpField, '4827');
        await tester.pump();
        expect(auth.otp, '4827');
        expect(find.text('7'), findsOneWidget);

        // Backspace: the old build-time controller lost the selection every
        // frame, so deleting either did nothing or wiped the field.
        await tester.enterText(_otpField, '482');
        await tester.pump();
        expect(auth.otp, '482');
        expect(find.text('7'), findsNothing);

        await tester.enterText(_otpField, '48');
        await tester.pump();
        expect(auth.otp, '48');

        // ...and typing resumes from where the user left off.
        await tester.enterText(_otpField, '4891');
        await tester.pump();
        expect(auth.otp, '4891');

        // The caret stays pinned after the last digit, whatever the platform
        // hands back, so the next backspace always removes the last digit.
        final state = tester.state<EditableTextState>(_otpField);
        expect(state.textEditingValue.selection.isCollapsed, isTrue);
        expect(state.textEditingValue.selection.baseOffset, 4);
      });
    }

    testWidgets('survives a rebuild of the screen above it', (tester) async {
      final auth = AuthController()..setOtp('');
      addTearDown(auth.dispose);
      await _pumpRoute(tester, AppRoutes.enterCode, auth);

      await tester.enterText(_otpField, '482');
      await tester.pump();

      // Anything that notifies the controller rebuilds the screen. The old
      // implementation built a throwaway TextEditingController here, which
      // dropped the caret to offset -1 and broke the next keystroke.
      auth.setOnboardingPage(1);
      await tester.pump();

      final state = tester.state<EditableTextState>(_otpField);
      expect(state.textEditingValue.text, '482');
      expect(state.textEditingValue.selection.isCollapsed, isTrue);
      expect(state.textEditingValue.selection.baseOffset, 3);
    });

    testWidgets('pulls a stray caret back to the end of the code', (tester) async {
      final auth = AuthController()..setOtp('');
      addTearDown(auth.dispose);
      await _pumpRoute(tester, AppRoutes.enterCode, auth);

      await tester.enterText(_otpField, '4827');
      await tester.pump();

      // A long-press or a platform quirk can drop the caret mid-string; the
      // next backspace would then delete a digit out of the middle.
      final state = tester.state<EditableTextState>(_otpField);
      state.updateEditingValue(
        const TextEditingValue(text: '4827', selection: TextSelection.collapsed(offset: 1)),
      );
      await tester.pump();

      expect(state.textEditingValue.selection.baseOffset, 4);
    });

    testWidgets('rejects non-digits and stops at six', (tester) async {
      final auth = AuthController()..setOtp('');
      addTearDown(auth.dispose);
      await _pumpRoute(tester, AppRoutes.enterCode, auth);

      await tester.enterText(_otpField, '12a3b4');
      await tester.pump();
      expect(auth.otp, '1234');

      await tester.enterText(_otpField, '123456789');
      await tester.pump();
      expect(auth.otp, '123456');
    });
  });

  group('resend countdown', () {
    testWidgets('counts down, unlocks, and restarts on resend', (tester) async {
      final auth = AuthController()..setOtp('12');
      addTearDown(auth.dispose);
      await _pumpRoute(tester, AppRoutes.enterCode, auth);

      expect(find.text('0:30'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('0:29'), findsOneWidget);

      await tester.pump(const Duration(seconds: 25));
      expect(find.text('0:04'), findsOneWidget);

      // Tapping while it is still running must not restart it.
      await tester.tap(find.text('Resend code'));
      await tester.pump();
      expect(find.text('0:04'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Ready'), findsOneWidget);

      await tester.tap(find.text('Resend code'));
      await tester.pump();
      expect(find.text('0:30'), findsOneWidget);
      expect(auth.otp, isEmpty, reason: 'a fresh code clears the old digits');

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('0:29'), findsOneWidget);

      // Let the timer finish so the test does not end with it pending.
      await tester.pump(const Duration(seconds: 30));
    });
  });

  group('password fields', () {
    Finder eyeIn(Finder field) => find.descendant(
      of: field,
      matching: find.byWidgetPredicate(
        (w) =>
            w is Icon &&
            (w.icon == Icons.visibility_outlined || w.icon == Icons.visibility_off_outlined),
      ),
    );

    const cases = <String, int>{
      AppRoutes.login: 1,
      AppRoutes.createAccount: 2,
      AppRoutes.createNewPassword: 2,
      AppRoutes.changePassword: 3,
    };

    cases.forEach((route, expected) {
      testWidgets('$route shows an eye on every password field', (tester) async {
        final auth = AuthController();
        addTearDown(auth.dispose);
        await _pumpRoute(tester, route, auth);

        final obscured = find.byWidgetPredicate((w) => w is AppTextField && w.obscure);
        expect(obscured, findsNWidgets(expected));

        for (var i = 0; i < expected; i++) {
          final field = obscured.at(i);
          expect(eyeIn(field), findsOneWidget, reason: 'field $i has no toggle');

          var text = tester.widget<EditableText>(
            find.descendant(of: field, matching: find.byType(EditableText)),
          );
          expect(text.obscureText, isTrue);

          await tester.tap(eyeIn(field));
          await tester.pump();

          text = tester.widget<EditableText>(
            find.descendant(of: field, matching: find.byType(EditableText)),
          );
          expect(text.obscureText, isFalse, reason: 'field $i did not reveal');

          await tester.tap(eyeIn(field));
          await tester.pump();
        }
      });
    });
  });
}
