import 'package:flutter/material.dart';
import 'dart:math';
import '../models/gacha_items.dart';

class GachaService {
  final Random _random = Random();

  final List<GachaItem> _items = [
    GachaItem('Collaboration Skin', 0.08, Icons.checkroom, Colors.red),
    GachaItem('Recall Effect', 0.3, Icons.menu_book, Colors.green),
    GachaItem('Kill Removal Effect', 0.5, Icons.dangerous, Colors.purple),
    GachaItem('Kill Notification', 0.5, Icons.notifications, Colors.grey),
    GachaItem('Emote', 7.95, Icons.emoji_emotions, Colors.amber, emotes: [
      Emote(name: 'Kakashi Emote', description: 'Grey Smiley Face', color: Colors.grey),
      Emote(name: 'Sasuke Emote', description: 'Indigo Smiley Face', color: Colors.indigo),
      Emote(name: 'Sakura Emote', description: 'Pink Smiley Face', color: Colors.pink),
    ]),
    GachaItem('Badge', 90.67, Icons.verified, Colors.blue),
  ];

  final List<int> badgeValues = [20, 15, 12, 10, 8, 5];
  final List<String> skinCharacters = [
    'Kakashi Hatake',
    'Sasuke Uchiha',
    'Naruto Uzumaki',
    'Sakura Haruno'
  ];

  // Draw one item, with optional guaranteed draw logic
  GachaItem drawItem({bool guaranteed = false}) {
    GachaItem? selectedItem;

    if (guaranteed) {
      final guaranteedItems = _items.where((item) => item.name != 'Badge').toList();
      final totalRate = guaranteedItems.fold(0.0, (sum, item) => sum + item.rate);
      final roll = _random.nextDouble() * totalRate;
      double cumulative = 0;
      for (var item in guaranteedItems) {
        cumulative += item.rate;
        if (roll <= cumulative) {
          selectedItem = GachaItem.clone(item);
          break;
        }
      }
    } else {
      final totalRate = _items.fold(0.0, (sum, item) => sum + item.rate);
      final roll = _random.nextDouble() * totalRate;
      double cumulative = 0;
      for (var item in _items) {
        cumulative += item.rate;
        if (roll <= cumulative) {
          selectedItem = GachaItem.clone(item);
          break;
        }
      }
    }

    if (selectedItem == null) {
      throw Exception('No item selected in draw!');
    }

    // Set special fields for certain items
    if (selectedItem.name == 'Badge') {
      selectedItem.badgeValue = badgeValues[_random.nextInt(badgeValues.length)];
    } else if (selectedItem.name == 'Collaboration Skin') {
      selectedItem.skinCharacter = skinCharacters[_random.nextInt(skinCharacters.length)];
    } else if (selectedItem.name == 'Emote' && selectedItem.emotes != null && selectedItem.emotes!.isNotEmpty) {
      final emote = selectedItem.emotes![_random.nextInt(selectedItem.emotes!.length)];
      selectedItem = GachaItem(
        emote.name,
        selectedItem.rate,
        selectedItem.icon,
        emote.color,
        emotes: [emote],
      );
    }

    return selectedItem;
  }

  // Draw multiple items
  List<GachaItem> drawMultiple(int times, {bool guaranteed = false}) {
    final results = <GachaItem>[];
    for (int i = 0; i < times; i++) {
      final isGuaranteedDraw = guaranteed && (i == times - 1);
      results.add(drawItem(guaranteed: isGuaranteedDraw));
    }
    return results;
  }
}
