import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nmls_mobile/login_screen.dart';
import 'package:nmls_mobile/sign_up_screen.dart';
import 'package:nmls_mobile/verify_email_screen.dart';
import 'package:nmls_mobile/forgot_password_screen.dart';
import 'package:nmls_mobile/states_screen.dart';
import 'package:nmls_mobile/dashboard_screen.dart';
import 'package:nmls_mobile/account_setup_screen.dart';
import 'package:nmls_mobile/catalog/api_client.dart' as catalog;
import 'package:nmls_mobile/catalog/courses_catalog_controller.dart';
import 'package:nmls_mobile/catalog/courses_catalog_screen.dart';
import 'package:nmls_mobile/catalog/repositories/auth_repository.dart';
import 'package:nmls_mobile/catalog/repositories/course_repository.dart';
import 'package:nmls_mobile/catalog/token_provider.dart';
import 'package:nmls_mobile/catalog/checkout_screen.dart';
import 'package:nmls_mobile/catalog/order_placed_screen.dart';
import 'package:nmls_mobile/catalog/course_portal_screen.dart';
import 'package:nmls_mobile/config/api_config.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  MainApp({super.key});

  final TokenProvider _tokenProvider = SharedPreferencesTokenProvider();

  @override
  Widget build(BuildContext context) {
    // Minimal provider wiring for the state-scoped course catalog flow.
    return ChangeNotifierProvider<CoursesCatalogController>(
      create: (context) {
        final apiClient = catalog.ApiClient(
          baseUrl: ApiConfig.baseUrl,
          tokenProvider: _tokenProvider,
        );
        return CoursesCatalogController(
          authRepository: AuthRepository(apiClient),
          courseRepository: CourseRepository(apiClient),
          onUnauthorized: () {
            // TODO(Dianne): Replace with app-level auth navigation handling.
            // Example: Navigator.of(context).pushReplacementNamed('/login');
          },
        );
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Poppins',
          iconTheme: const IconThemeData(color: Colors.black),
          textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Poppins'),
        ),
        initialRoute: '/login',
        onGenerateRoute: (settings) {
          final name = settings.name;
          if (name != null) {
            const prefix = '/courses/';
            const suffix = '/learn';
            if (name.startsWith(prefix) && name.endsWith(suffix)) {
              final courseId = name.substring(prefix.length, name.length - suffix.length);
              if (courseId.trim().isNotEmpty) {
                return MaterialPageRoute(
                  builder: (_) => CoursePortalScreen(courseId: courseId.trim()),
                );
              }
            }
          }
          return null;
        },
        routes: {
          '/login': (context) => LoginScreen(),
          '/signup': (context) => const RegisterScreen(),
          '/verify-email': (context) => const VerifyEmailScreen(),
          '/forgot-password': (context) => ForgotPasswordScreen(),
          '/states': (context) => const StatesScreen(),
          '/dashboard': (context) {
            final user =
                ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>?;
            final token = user?['token']?.toString();
            final userSansToken = user != null
                ? (Map<String, dynamic>.from(user)..remove('token'))
                : null;
            return DashboardScreen(user: userSansToken, token: token);
          },
          '/account-setup': (context) => const AccountSetupScreen(),
          '/course-catalog': (context) => const CoursesCatalogScreen(),
          '/checkout': (context) => const CheckoutScreen(),
          '/order-placed': (context) {
            final args = ModalRoute.of(context)!.settings.arguments;
            final orderId = args is Map<String, dynamic>
                ? args['orderId'] as String?
                : null;
            final directId = args is String ? args : null;
            return OrderPlacedScreen(orderId: directId ?? orderId);
          },
        },
      ),
    );
  }
}
