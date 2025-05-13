import 'package:flutter/material.dart';

class GachaItem {
  final String name;
  final double rate;
  final IconData icon;
  final Color color;
  int badgeValue;

  GachaItem(this.name, this.rate, this.icon, this.color, [this.badgeValue = 0]);

  // Factory to clone an item
  factory GachaItem.clone(GachaItem original) {
    return GachaItem(
      original.name,
      original.rate,
      original.icon,
      original.color,
      original.badgeValue,
    );
  }
}
