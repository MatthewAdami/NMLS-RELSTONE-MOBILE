import 'package:shared_preferences/shared_preferences.dart';

abstract class TokenProvider {
  Future<String?> getToken();
}

class StubTokenProvider implements TokenProvider {
  @override
  Future<String?> getToken() async {
    // TODO(Dianne): Wire this to your real token storage source.
    // Example: SharedPreferences, secure storage, or an auth session service.
    return null;
  }
}

/// Reads the JWT token from SharedPreferences.
///
/// TODO(Dianne): If your storage key differs from `token` or you switch to
/// secure storage, update this implementation accordingly.
class SharedPreferencesTokenProvider implements TokenProvider {
  @override
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
