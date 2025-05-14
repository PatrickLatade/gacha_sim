import 'package:flutter/material.dart';

// Extension to add alpha percent method to Color
extension ColorAlpha on Color {
  Color withAlphaPercent(double opacity) {
    return withAlpha((opacity.clamp(0.0, 1.0) * 255).round());
  }
}

// Top-level helper method
Color getSkinColor(String character) {
  switch (character) {
    case 'Kakashi Hatake':
      return Colors.grey[700]!;
    case 'Sasuke Uchiha':
      return Colors.indigo[800]!;
    case 'Naruto Uzumaki':
      return Colors.orange[700]!;
    case 'Sakura Haruno':
      return Colors.pink[400]!;
    default:
      return Colors.black;
  }
}
