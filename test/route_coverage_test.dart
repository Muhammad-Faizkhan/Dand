import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:dandcollection/core/routes/route_generator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the two ways a screen can go missing: a route with nothing behind it,
/// and a screen nothing can navigate to.
void main() {
  final routes = _declaredRoutes();

  test('every declared route builds a screen', () {
    expect(routes, hasLength(76));

    final unbuilt = <String>[];
    for (final entry in routes.entries) {
      final page = RouteGenerator.screenFor(RouteSettings(name: entry.value));
      if (page is UnknownRouteScreen) unbuilt.add('${entry.key} (${entry.value})');
    }
    expect(unbuilt, isEmpty, reason: 'routes with no screen behind them');
  });

  test('every declared route is reachable from a screen', () {
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('app_routes.dart'))
        .where((f) => !f.path.endsWith('route_generator.dart'))
        .map((f) => f.readAsStringSync())
        .join('\n');

    // The buy flow (Shipping -> Payment -> Order Placed) is parked until in-app
    // checkout returns; buyers make offers and settle with the seller instead.
    const parked = {'shipping'};

    final orphans = [
      for (final name in routes.keys)
        if (!parked.contains(name))
        // ignore: deprecated_member_use
        if (!RegExp('AppRoutes\\.$name\\b').hasMatch(sources)) name,
    ];
    expect(orphans, isEmpty, reason: 'routes nothing navigates to');
  });
}

/// Reads the route table straight out of the source so a newly added constant
/// is covered without touching this test.
Map<String, String> _declaredRoutes() {
  final source = File('lib/core/routes/app_routes.dart').readAsStringSync();
  return {
    // ignore: deprecated_member_use
    for (final m in RegExp(r"static const (\w+) = '([^']+)';").allMatches(source))
      m.group(1)!: m.group(2)!,
  };
}
