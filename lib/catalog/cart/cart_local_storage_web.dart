// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

import '../models/cart_item_model.dart';

class CartLocalStorage {
  static const String _key = 'cart';

  Future<List<CartItemModel>> readCart() async {
    final raw = html.window.localStorage[_key];
    if (raw == null || raw.trim().isEmpty) return <CartItemModel>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return <CartItemModel>[];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(CartItemModel.fromJson)
        .toList();
  }

  Future<void> writeCart(List<CartItemModel> items) async {
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    html.window.localStorage[_key] = encoded;
  }

  Future<void> clearCart() async {
    html.window.localStorage.remove(_key);
  }
}
