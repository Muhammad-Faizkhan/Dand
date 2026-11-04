import 'package:flutter/material.dart';

import '../core/api/api_client.dart';
import '../core/api/collections_api.dart';
import '../models/models.dart';

class CollectionsController extends ChangeNotifier {
  CollectionsController({this.client});

  final ApiClient? client;

  List<ApiCollection> _collections = [];
  bool _loading = false;
  String? _error;

  List<ApiCollection> get collections => _collections;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    final c = client;
    if (c == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _collections = await CollectionsApi(c).getCollections();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<ApiCollection?> create({
    required String name,
    String? description,
    String? coverImageUrl,
    String? eventDate,
  }) async {
    final c = client;
    if (c == null) return null;
    try {
      final col = await CollectionsApi(c).createCollection(
        name: name,
        description: description,
        coverImageUrl: coverImageUrl,
        eventDate: eventDate,
      );
      _collections = [col, ..._collections];
      notifyListeners();
      return col;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> delete(int id) async {
    final c = client;
    if (c == null) return true;
    try {
      await CollectionsApi(c).deleteCollection(id);
      _collections.removeWhere((col) => col.id == id);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }
}
