import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../core/api/api_client.dart';
import '../models/models.dart';

/// Dealers for the map, nearest first, from `/api/dealers/nearby`.
class DealersController extends ChangeNotifier {
  DealersController({this.client});

  final ApiClient? client;

  /// Sturgis, SD. Used until the phone's location is known, or if it never is.
  static const fallbackCenter = LatLng(44.4097, -103.5091);

  static const _radiusKm = 160; // about 100 miles

  LatLng center = fallbackCenter;
  bool located = false;
  bool loading = false;
  bool _loaded = false;
  List<Dealer> dealers = const [];

  /// The last fix from the phone, kept for check-ins.
  Position? position;

  static const checkInRadiusM = 50.0;

  /// The closest dealer the user is standing at, if any (accuracy forgiven up to 25 m, as on the server).
  Dealer? get dealerHere {
    final p = position;
    if (p == null) return null;
    Dealer? best;
    var bestM = double.infinity;
    for (final d in dealers) {
      final m = Geolocator.distanceBetween(p.latitude, p.longitude, d.lat, d.lng);
      if (m - p.accuracy.clamp(0, 25) <= checkInRadiusM && m < bestM) {
        best = d;
        bestM = m;
      }
    }
    return best;
  }

  /// Takes a fresh fix and reloads the list, e.g. after a check-in or on pull-to-refresh.
  Future<void> refresh() => load(force: true);

  Future<void> load({bool force = false}) async {
    final c = client;
    if (c == null || loading || (_loaded && !force)) return;
    loading = true;
    notifyListeners();
    try {
      final here = await _locate();
      if (here != null) {
        position = here;
        center = LatLng(here.latitude, here.longitude);
        located = true;
      }
      final data = await c.get(
        '/api/dealers/nearby',
        // Signed in, each dealer also says when this user may check in there again.
        // Without a location, list every dealer rather than only those around the fallback.
        query: {'lat': center.latitude, 'lng': center.longitude, 'radiusKm': located ? _radiusKm : 20000},
      ) as List<dynamic>;
      dealers = [for (final d in data.cast<Map<String, dynamic>>()) Dealer.fromJson(d)];
      _loaded = true;
    } on ApiException {
      // Keep whatever was shown.
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<Position?> _locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return null;
      // Check-ins need a fix good to tens of metres.
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
      );
    } catch (_) {
      // Timeouts and platform errors just mean we use the fallback.
      return null;
    }
  }
}
