import '../../models/models.dart';
import 'api_client.dart';

class MarketplaceApi {
  MarketplaceApi(this.client);

  final ApiClient client;

  Future<({List<ChipItem> items, int total})> getListings({
    String? listingType,
    int? categoryId,
    int? minPriceCents,
    int? maxPriceCents,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await client.get('/api/marketplace', auth: false, query: {
      'listingType': ?listingType,
      'categoryId': ?categoryId,
      'minPriceCents': ?minPriceCents,
      'maxPriceCents': ?maxPriceCents,
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'pageSize': pageSize,
    }) as Map<String, dynamic>;
    final listings = data['listings'] as List<dynamic>? ?? [];
    return (
      items: listings.map((l) => ChipItem.fromApiListing(l as Map<String, dynamic>)).toList(),
      total: data['total'] as int? ?? 0,
    );
  }

  Future<Map<String, dynamic>> getListing(int id) async {
    final data = await client.get('/api/marketplace/$id', auth: false);
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createListing({
    required int itemId,
    required String listingType,
    int? priceCents,
    Map<String, dynamic>? auction,
  }) async {
    final body = <String, dynamic>{
      'itemId': itemId,
      'listingType': listingType,
      'priceCents': ?priceCents,
      'auction': ?auction,
    };
    final data = await client.post('/api/marketplace', body: body);
    return data as Map<String, dynamic>;
  }

  Future<void> cancelListing(int id) => client.post('/api/marketplace/$id/cancel');
}
