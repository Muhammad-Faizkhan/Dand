import '../../models/models.dart';
import 'api_client.dart';

class TradesApi {
  TradesApi(this.client);

  final ApiClient client;

  Future<List<ApiTradeRequest>> getTrades(int myId) async {
    final data = await client.get('/api/trades');
    return (data as List<dynamic>)
        .map((t) => ApiTradeRequest.fromJson(t as Map<String, dynamic>, myId))
        .toList();
  }

  Future<ApiTradeRequest> createTrade({
    required int recipientId,
    required List<Map<String, dynamic>> offerItems,
    String? message,
  }) async {
    final body = <String, dynamic>{
      'recipientId': recipientId,
      'offerItems': offerItems,
      if (message != null && message.isNotEmpty) 'message': message,
    };
    final data = await client.post('/api/trades', body: body);
    return ApiTradeRequest.fromJson(data as Map<String, dynamic>, 0);
  }

  Future<void> respondToTrade(int id, {required bool accept}) =>
      client.post('/api/trades/$id/respond', body: {'accept': accept});

  Future<void> cancelTrade(int id) => client.post('/api/trades/$id/cancel');
}
