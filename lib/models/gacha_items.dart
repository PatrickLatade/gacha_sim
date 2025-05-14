import 'package:flutter/material.dart';

// Emote class definition
class Emote {
  final String name;
  final String description;
  final Color color;

  Emote({required this.name, required this.description, required this.color});
}

// GachaItem class definition
class GachaItem {
  final String name;
  final double rate;
  final IconData icon;
  final Color color;
  int badgeValue;
  String? skinCharacter;
  List<Emote>? emotes;  // Add this line to hold the emote sub-items

  GachaItem(
    this.name,
    this.rate,
    this.icon,
    this.color, {
    this.badgeValue = 0,
    this.emotes,
  });

  // Clone constructor
  GachaItem.clone(GachaItem item)
      : name = item.name,
        rate = item.rate,
        icon = item.icon,
        color = item.color,
        badgeValue = item.badgeValue,
        skinCharacter = item.skinCharacter,
        emotes = item.emotes; // Make sure to copy the emotes list too
}
