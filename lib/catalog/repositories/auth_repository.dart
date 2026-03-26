import '../api_client.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient apiClient;

  const AuthRepository(this.apiClient);

  Future<UserModel> fetchMe() async {
    // Prefer /api/auth/profile, fallback to older /api/auth/me.
    Map<String, dynamic> response;
    try {
      response = await apiClient.getJson('/api/auth/profile');
    } on HttpErrorException catch (e) {
      if (e.statusCode == 404) {
        response = await apiClient.getJson('/api/auth/me');
      } else {
        rethrow;
      }
    }

    final userJson = response['user'];
    if (userJson is! Map<String, dynamic>) {
      throw const ApiClientException('Invalid auth profile response shape.');
    }

    return UserModel.fromJson(userJson);
  }
}
