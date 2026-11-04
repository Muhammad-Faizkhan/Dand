import '../../models/models.dart';
import 'api_client.dart';

class UserApi {
  UserApi(this.client);

  final ApiClient client;

  Future<ApiUser> me() async {
    final data = await client.get('/api/users/me');
    return ApiUser.fromJson(data as Map<String, dynamic>);
  }

  Future<ApiUser> getUser(int id) async {
    final data = await client.get('/api/users/$id', auth: false);
    return ApiUser.fromJson(data as Map<String, dynamic>);
  }

  Future<ApiUser> updateProfile({
    String? fullName,
    String? bio,
    String? phone,
    String? address,
    String? avatarUrl,
    double? lat,
    double? lng,
  }) async {
    final body = <String, dynamic>{
      'fullName': ?fullName,
      'bio': ?bio,
      'phone': ?phone,
      'address': ?address,
      'avatarUrl': ?avatarUrl,
      'lat': ?lat,
      'lng': ?lng,
    };
    final data = await client.patch('/api/users/me', body: body);
    return ApiUser.fromJson(data as Map<String, dynamic>);
  }

  Future<void> changePassword(String currentPassword, String newPassword) =>
      client.post('/api/users/me/change-password', body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

  Future<List<int>> getUserInterests() async {
    // interests come from the user profile via /api/categories/me/interests
    // Currently returns empty; interests are stored server-side.
    return [];
  }

  Future<void> setInterests(List<int> categoryIds) =>
      client.put('/api/categories/me/interests', body: {'categoryIds': categoryIds});

  Future<List<Map<String, dynamic>>> getCategories() async {
    final data = await client.get('/api/categories', auth: false);
    return List<Map<String, dynamic>>.from(data as List);
  }
}
