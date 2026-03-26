import 'package:flutter/material.dart';

// Shared styling for catalog screens to match app theme.
const Color kCatalogDark = Color(0xFF091925);
const Color kCatalogBlue = Color(0xFF2EABFE);
const Color kCatalogBg = Color(0xFFF6F7FB);
const Color kCatalogWhite = Colors.white;
const Color kCatalogMuted = Color(0x990B1220);
const Color kCatalogBorder = Color(0x1A020817);

final OutlineInputBorder kCatalogOutlineBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: const BorderSide(color: kCatalogBorder, width: 1),
);

InputDecoration kCatalogInputDecoration({
  required String hintText,
  IconData? prefixIcon,
  String? labelText,
  String? helperText,
}) {
  return InputDecoration(
    labelText: labelText,
    helperText: helperText,
    prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
    hintText: hintText,
    filled: true,
    fillColor: kCatalogWhite,
    hintStyle: const TextStyle(color: Color(0xFF6B8397), fontSize: 14),
    labelStyle: const TextStyle(color: kCatalogMuted, fontSize: 14),
    border: kCatalogOutlineBorder,
    enabledBorder: kCatalogOutlineBorder,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kCatalogBlue, width: 1.5),
    ),
  );
}

ButtonStyle kCatalogPrimaryButtonStyle() {
  return OutlinedButton.styleFrom(
    backgroundColor: kCatalogBlue,
    foregroundColor: kCatalogWhite,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    side: const BorderSide(color: kCatalogBlue),
  );
}
