class ApiConfig {
  // ✅ Choose ONE depending on how you run your app:

  // Android Emulator -> points to your PC localhost
static const String baseUrl = "http://192.168.100.3:5000";  // Use your machine's IP


  // iOS Simulator:
  // static const String baseUrl = "http://localhost:5000";

  // Real device (phone) -> use your PC IP (same WiFi)
  // static const String baseUrl = "http://192.168.100.3:5000";

  static const String apiPrefix = "/api";

  // ✅ Your Node routes (based on server.js: app.use('/api/auth', ...))
  static String get login => "$baseUrl$apiPrefix/auth/login";
  static String get register => "$baseUrl$apiPrefix/auth/register";
  static String get health => "$baseUrl$apiPrefix/health";
}