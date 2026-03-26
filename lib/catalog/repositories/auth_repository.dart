import '../api_client.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient apiClient;

  const AuthRepository(this.apiClient);

  Future<UserModel> fetchMe() async {
    final response = await apiClient.getJson('/api/auth/me');
    final userJson = response['user'];

    if (userJson is! Map<String, dynamic>) {
      throw const ApiClientException('Invalid /api/auth/me response shape.');
    }

    return UserModel.fromJson(userJson);
  }
}
