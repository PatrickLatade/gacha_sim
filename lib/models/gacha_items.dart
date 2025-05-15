import 'package:flutter/material.dart';

class Emote {
  final String name;
  final String description;
  final Color color;

  Emote({required this.name, required this.description, required this.color});
}

class GachaItem {
  final String name;
  final double rate;
  final IconData icon;
  final Color color;
  int badgeValue = 0;
  String? skinCharacter;
  List<Emote>? emotes;
  bool isConverted = false; // New flag to track converted state
  
  // Badge conversion rates
  static const Map<String, int> conversionRates = {
    'Collaboration Skin': 360,
    'Recall Effect': 90,
    'Kill Removal Effect': 68,
    'Kill Notification': 68,
    'Emote': 9,
    'Kakashi Emote': 9,
    'Sasuke Emote': 9,
    'Sakura Emote': 9,
  };

  GachaItem(this.name, this.rate, this.icon, this.color, {this.badgeValue = 0, this.skinCharacter, this.emotes});

  // Clone method to create a copy of the item
  static GachaItem clone(GachaItem source) {
    return GachaItem(
      source.name,
      source.rate,
      source.icon,
      source.color,
      badgeValue: source.badgeValue,
      skinCharacter: source.skinCharacter,
      emotes: source.emotes,
    );
  }
  
  // Convert to badges based on predefined rates
  int convertToBadges() {
    // Handle named emotes
    if (name.contains('Emote') && name != 'Emote') {
      return conversionRates['Emote'] ?? 9;
    }
    
    return conversionRates[name] ?? 0;
  }
  
  // Generate a unique identifier for collection tracking
  String get uniqueId {
    if (name == 'Badge') return 'badge'; // avoid treating as collectible
    if (skinCharacter != null) {
      return 'skin:$skinCharacter';
    } else if (name.contains('Emote') && name != 'Emote') {
      return 'emote:$name';
    }
    return name;
  }
}