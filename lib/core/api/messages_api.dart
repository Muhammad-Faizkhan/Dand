import '../../models/models.dart';
import 'api_client.dart';

class MessagesApi {
  MessagesApi(this.client);

  final ApiClient client;

  Future<List<ApiConversation>> getConversations(int myId) async {
    final data = await client.get('/api/messages/conversations');
    return (data as List<dynamic>)
        .map((c) => ApiConversation.fromJson(c as Map<String, dynamic>, myId))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getMessages(int conversationId) async {
    final data = await client.get('/api/messages/conversations/$conversationId/messages');
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<Map<String, dynamic>> startConversation(int userId, String body) async {
    final data = await client.post('/api/messages/conversations', body: {
      'userId': userId,
      'body': body,
    });
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendMessage(int conversationId, String body) async {
    final data = await client.post(
      '/api/messages/conversations/$conversationId/messages',
      body: {'body': body},
    );
    return data as Map<String, dynamic>;
  }

  Future<void> markRead(int conversationId) =>
      client.post('/api/messages/conversations/$conversationId/read');
}
