class CartItemModel {
  final String id; // Backend expects `_id`
  final String title;
  final num price;

  // Optional textbook pricing.
  final bool hasTextbook;
  final num textbookPrice;

  // Mirrors `include_textbook`.
  final bool includeTextbook;

  const CartItemModel({
    required this.id,
    required this.title,
    required this.price,
    required this.hasTextbook,
    required this.textbookPrice,
    required this.includeTextbook,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final idRaw = json['_id'] ?? json['id'] ?? '';
    final priceRaw = json['price'];
    final textbookPriceRaw =
        json['textbook_price'] ?? json['textbookPrice'] ?? 0;
    final includeTextbookRaw =
        json['include_textbook'] ?? json['includeTextbook'] ?? false;
    final hasTextbookRaw = json['has_textbook'] ?? json['hasTextbook'] ?? false;

    num parseNum(dynamic value) {
      if (value is num) return value;
      if (value is String) return num.tryParse(value.trim()) ?? 0;
      return 0;
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final v = value.trim().toLowerCase();
        return v == 'true' || v == '1' || v == 'yes';
      }
      return false;
    }

    return CartItemModel(
      id: idRaw.toString(),
      title: json['title']?.toString() ?? '',
      price: parseNum(priceRaw),
      hasTextbook: parseBool(hasTextbookRaw),
      textbookPrice: parseNum(textbookPriceRaw),
      includeTextbook: parseBool(includeTextbookRaw),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'price': price,
      'has_textbook': hasTextbook,
      'textbook_price': textbookPrice,
      'include_textbook': includeTextbook,
    };
  }
}
