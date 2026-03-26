import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item_model.dart';

class CartLocalStorage {
  static const String _key = 'cart';

  Future<List<CartItemModel>> readCart() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return <CartItemModel>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return <CartItemModel>[];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(CartItemModel.fromJson)
        .toList();
  }

  Future<void> writeCart(List<CartItemModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
