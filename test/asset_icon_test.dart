import 'package:dandcollection/core/constants/app_assets.dart';
import 'package:dandcollection/widgets/asset_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The header icons are referenced by their final asset paths before the
/// artwork exists, so the fallback has to be reliable — and the swap has to
/// happen on its own the moment the files land.
void main() {
  testWidgets('falls back to the Material glyph while the asset is absent', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AssetIcon(
          asset: 'assets/images/definitely_not_here.png',
          fallback: Icons.forum_rounded,
          size: 24,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.forum_rounded), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('uses the artwork once it is in the bundle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AssetIcon(
          // Stands in for the header exports: a real file at a real path.
          asset: AppAssets.navHome,
          fallback: Icons.forum_rounded,
          size: 24,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.forum_rounded), findsNothing);
  });
}
