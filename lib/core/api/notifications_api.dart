import '../../models/models.dart';
import 'api_client.dart';

class NotificationsApi {
  NotificationsApi(this.client);

  final ApiClient client;

  Future<List<ApiNotification>> getNotifications() async {
    final data = await client.get('/api/notifications');
    return (data as List<dynamic>)
        .map((n) => ApiNotification.fromJson(n as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(int id) => client.post('/api/notifications/$id/read');

  Future<void> markAllRead() => client.post('/api/notifications/read-all');
}
