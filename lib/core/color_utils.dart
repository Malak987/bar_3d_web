import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Convert "#RRGGBB" → Color
Color hexToColor(String hex) {
  final c = hex.replaceAll('#', '');
  return Color(int.parse(c.length == 6 ? 'FF$c' : c, radix: 16));
}

/// Check perceived luminance < 128
bool isDarkColor(Color c) =>
    (0.299 * c.red + 0.587 * c.green + 0.114 * c.blue) < 128;

/// Decode `data:image/...;base64,...` → Uint8List
Uint8List? tryDecodeDataUrl(String v) {
  if (!v.startsWith('data:')) return null;
  final i = v.indexOf(',');
  if (i == -1) return null;
  return base64Decode(v.substring(i + 1));
}

/// Null-safe `firstOrNull`
extension FirstOrNullX<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
