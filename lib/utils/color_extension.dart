import 'package:flutter/material.dart';

extension ColorAlpha on Color {
  Color withAlphaPercent(double opacity) {
    return withValues(
      red: r.toDouble(),
      green: g.toDouble(),
      blue: b.toDouble(),
      alpha: (opacity.clamp(0.0, 1.0) * 255).roundToDouble(),
    );
  }
}
