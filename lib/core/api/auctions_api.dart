import '../../models/models.dart';
import 'api_client.dart';

class AuctionsApi {
  AuctionsApi(this.client);

  final ApiClient client;

  Future<void> placeBid(int auctionId, int amountCents) =>
      client.post('/api/auctions/$auctionId/bids', body: {'amountCents': amountCents});

  Future<PlanStatus> myPlan() async {
    final data = await client.get('/api/subscriptions/me');
    return PlanStatus.fromJson(data as Map<String, dynamic>);
  }
}
