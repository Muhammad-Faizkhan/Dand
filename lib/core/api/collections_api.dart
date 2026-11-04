import '../../models/models.dart';
import 'api_client.dart';

class CollectionsApi {
  CollectionsApi(this.client);

  final ApiClient client;

  Future<List<ApiCollection>> getCollections() async {
    final data = await client.get('/api/collections');
    return (data as List<dynamic>)
        .map((c) => ApiCollection.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<ApiCollection> createCollection({
    required String name,
    String? description,
    String? coverImageUrl,
    String? eventDate,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
      'coverImageUrl': ?coverImageUrl,
      'eventDate': ?eventDate,
    };
    final data = await client.post('/api/collections', body: body);
    return ApiCollection.fromJson(data as Map<String, dynamic>);
  }

  Future<ApiCollection> updateCollection(int id, {String? name, String? description}) async {
    final body = <String, dynamic>{
      'name': ?name,
      'description': ?description,
    };
    final data = await client.patch('/api/collections/$id', body: body);
    return ApiCollection.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteCollection(int id) => client.delete('/api/collections/$id');
}
