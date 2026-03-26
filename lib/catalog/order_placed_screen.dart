import 'package:flutter/material.dart';
import 'package:nmls_mobile/courses_screen.dart';

import 'catalog_theme.dart';

class OrderPlacedScreen extends StatelessWidget {
  final String? orderId;

  const OrderPlacedScreen({super.key, this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCatalogBg,
      appBar: AppBar(
        backgroundColor: kCatalogBg,
        foregroundColor: kCatalogDark,
        elevation: 0,
        title: const Text('Order Placed'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: 420,
            decoration: BoxDecoration(
              color: kCatalogWhite,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE8F9EE),
                    border: Border.all(
                      color: const Color(0xFFB7EFC3),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 46,
                    color: Color(0xFF2BB673),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Order Placed!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: kCatalogDark,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your order has been saved successfully. '
                  'Order ID:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kCatalogMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  orderId == null ? '—' : orderId!,
                  style: TextStyle(
                    color: kCatalogDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E8),
                    border: Border.all(color: const Color(0xFFFFD8A6)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Once payment is confirmed by an admin, your courses will be unlocked and available to start.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: kCatalogDark,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => CoursesScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF091925),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Go to My Courses',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/course-catalog');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: kCatalogBorder),
                      foregroundColor: kCatalogDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Browse More Courses',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
