import 'api_client.dart';

class ItemsApi {
  ItemsApi(this.client);

  final ApiClient client;

  Future<({List<Map<String, dynamic>> items, int total})> getItems({
    int? ownerId,
    String? status,
    int? categoryId,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await client.get('/api/items', auth: false, query: {
      'ownerId': ?ownerId,
      'status': ?status,
      'categoryId': ?categoryId,
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'pageSize': pageSize,
    }) as Map<String, dynamic>;
    return (
      items: List<Map<String, dynamic>>.from(data['items'] as List? ?? []),
      total: data['total'] as int? ?? 0,
    );
  }

  Future<Map<String, dynamic>> getItem(int id) async {
    final data = await client.get('/api/items/$id', auth: false);
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createItem({
    required String title,
    String? description,
    required String status,
    int? categoryId,
    int? collectionId,
    String? condition,
    String? brand,
    int? year,
    int? estimatedValueCents,
    List<String>? imageUrls,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'status': status,
      if (description != null && description.isNotEmpty) 'description': description,
      'categoryId': ?categoryId,
      'collectionId': ?collectionId,
      'condition': ?condition,
      'brand': ?brand,
      'year': ?year,
      'estimatedValueCents': ?estimatedValueCents,
      if (imageUrls != null && imageUrls.isNotEmpty) 'imageUrls': imageUrls,
    };
    final data = await client.post('/api/items', body: body);
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateItem(int id, Map<String, dynamic> fields) async {
    final data = await client.patch('/api/items/$id', body: fields);
    return data as Map<String, dynamic>;
  }

  Future<void> deleteItem(int id) => client.delete('/api/items/$id');
}
