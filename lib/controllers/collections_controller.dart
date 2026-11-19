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

  /// Renames a collection or changes its description or cover. Returns the
  /// updated collection, or null with [error] set.
  Future<ApiCollection?> update(int id, {String? name, String? description, String? coverImageUrl}) async {
    final c = client;
    if (c == null) return null;
    try {
      final saved = await CollectionsApi(c).updateCollection(
        id,
        name: name,
        description: description,
        coverImageUrl: coverImageUrl,
      );
      final i = _collections.indexWhere((col) => col.id == id);
      // PATCH answers without the item count or the resolved default cover; keep those.
      final merged = i < 0
          ? saved
          : _collections[i].copyWith(
              name: saved.name,
              description: saved.description,
              coverImageUrl: saved.coverImageUrl,
            );
      if (i >= 0) _collections[i] = merged;
      notifyListeners();
      return merged;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  /// Deletes one of the user's own chips.
  Future<bool> deleteItem(int itemId) async {
    final c = client;
    if (c == null) return true;
    try {
      await c.delete('/api/items/$itemId');
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
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
