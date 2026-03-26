import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api_client.dart';
import 'cart/cart_local_storage.dart';
import 'courses_catalog_controller.dart';
import 'models/cart_item_model.dart';
import 'token_provider.dart';
import 'catalog_theme.dart';
import '../config/api_config.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartLocalStorage _cartStorage = CartLocalStorage();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool loading = true;
  String? errorMessage;
  List<CartItemModel> cart = <CartItemModel>[];

  // Billing & Shipping form controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: 'United States');
  final _streetAddressCtrl = TextEditingController();
  final _townCityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _zipCodeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _companyNameCtrl = TextEditingController();
  final _additionalInfoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      cart = await _cartStorage.readCart();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      setState(() => loading = false);
    }
  }

  num get total {
    return cart.fold<num>(
      0,
      (sum, item) =>
          sum +
          item.price +
          (item.includeTextbook == true ? item.textbookPrice : 0),
    );
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _countryCtrl.dispose();
    _streetAddressCtrl.dispose();
    _townCityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCodeCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _companyNameCtrl.dispose();
    _additionalInfoCtrl.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _emailValidator(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Required';
    if (!v.contains('@')) return 'Enter a valid email';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCatalogBg,
      appBar: AppBar(
        backgroundColor: kCatalogDark,
        foregroundColor: kCatalogWhite,
        title: const Text('Checkout'),
      ),
      body: Builder(
        builder: (context) {
          if (loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (errorMessage != null) {
            return _ErrorView(message: errorMessage!, onRetry: _load);
          }

          if (cart.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Your cart is empty.'),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...cart.map((item) {
                final itemTotal =
                    item.price +
                    (item.includeTextbook ? item.textbookPrice : 0);
                return Card(
                  color: kCatalogWhite,
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: kCatalogDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Price: \$$item.price',
                          style: const TextStyle(
                            color: kCatalogMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        if (item.hasTextbook) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Textbook: ${item.includeTextbook ? 'Included' : 'Not included'}',
                            style: const TextStyle(
                              color: kCatalogMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Item total: \$$itemTotal',
                          style: const TextStyle(
                            color: kCatalogDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              Text(
                'Grand total: \$$total',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: kCatalogDark,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Billing & Shipping',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _firstNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'First Name *',
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(fontSize: 13),
                      ),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lastNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Last Name *',
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(fontSize: 13),
                      ),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _countryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Country / Region *',
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(fontSize: 13),
                      ),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _streetAddressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Street Address *',
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(fontSize: 13),
                      ),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _townCityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Town / City *',
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(fontSize: 13),
                      ),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _stateCtrl,
                      decoration: const InputDecoration(
                        labelText: 'State *',
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(fontSize: 13),
                      ),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _zipCodeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Zip Code *',
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(fontSize: 13),
                      ),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Phone *',
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(fontSize: 13),
                      ),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Email Address *',
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(fontSize: 13),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: _emailValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _companyNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Company Name (optional)',
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _additionalInfoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Additional Information (optional)',
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(fontSize: 13),
                      ),
                      minLines: 3,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        final form = _formKey.currentState;
                        if (form == null) return;
                        if (!form.validate()) return;

                        final controller = context
                            .read<CoursesCatalogController>();

                        final payloadItems = cart.map((item) {
                          return {
                            'course_id': item.id,
                            'include_textbook': item.includeTextbook,
                            'price': item.price,
                            'textbook_price': item.includeTextbook == true
                                ? item.textbookPrice
                                : 0,
                          };
                        }).toList();

                        final payload = <String, dynamic>{
                          'items': payloadItems,
                          'total_amount': total,
                          'billing': {
                            'first_name': _firstNameCtrl.text.trim(),
                            'last_name': _lastNameCtrl.text.trim(),
                            'company_name': _companyNameCtrl.text.trim().isEmpty
                                ? null
                                : _companyNameCtrl.text.trim(),
                            'country': _countryCtrl.text.trim(),
                            'street_address': _streetAddressCtrl.text.trim(),
                            'town_city': _townCityCtrl.text.trim(),
                            'state': _stateCtrl.text.trim(),
                            'zip_code': _zipCodeCtrl.text.trim(),
                            'phone': _phoneCtrl.text.trim(),
                            'email': _emailCtrl.text.trim(),
                            'additional_info':
                                _additionalInfoCtrl.text.trim().isEmpty
                                ? null
                                : _additionalInfoCtrl.text.trim(),
                          },
                        };

                        final apiClient = ApiClient(
                          baseUrl: ApiConfig.baseUrl,
                          tokenProvider: SharedPreferencesTokenProvider(),
                        );

                        try {
                          final response = await apiClient.postJson(
                            '/api/orders',
                            body: payload,
                          );

                          await controller.clearCartFromLocalStorage();
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Order placed!')),
                          );
                          final orderId =
                              response['order_id']?.toString() ??
                              response['orderId']?.toString() ??
                              response['order']?['_id']?.toString() ??
                              response['_id']?.toString();

                          navigator.pushNamed(
                            '/order-placed',
                            arguments: {'orderId': orderId},
                          );
                        } on UnauthorizedException catch (e) {
                          controller.onUnauthorized?.call();
                          messenger.showSnackBar(
                            SnackBar(content: Text(e.message)),
                          );
                        } on ApiClientException catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(e.message)),
                          );
                        }
                      },
                      style: kCatalogPrimaryButtonStyle(),
                      child: const Text('Place Order'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kCatalogMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              style: kCatalogPrimaryButtonStyle(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
