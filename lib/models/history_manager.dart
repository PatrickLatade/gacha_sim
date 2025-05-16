import 'package:flutter/material.dart';
import 'gacha_items.dart';

class DrawSession {
  final List<GachaItem> items;
  final int drawCount;
  final int badgeTotal;

  DrawSession({
    required this.items,
    required this.drawCount,
    required this.badgeTotal,
  });
}

class HistoryManager with ChangeNotifier {
  final List<DrawSession> _drawSessions = [];
  final Set<String> _ownedItems = {}; // Track owned items by uniqueId
  final Set<String> _ownedEmotes = {}; // Track owned emotes by name
  int _badgeTotal = 0;
  int _totalDraws = 0;
  bool _guaranteedGiven = false;

  // Getters
  List<DrawSession> get drawSessions => _drawSessions.reversed.toList();
  Set<String> get ownedItems => _ownedItems;
  Set<String> get ownedEmotes => _ownedEmotes;
  int get badgeTotal => _badgeTotal;
  int get totalDraws => _totalDraws;
  bool get guaranteedGiven => _guaranteedGiven;

  int get totalDiamondsSpent {
    int total = 0;
    for (final session in _drawSessions) {
      total += session.drawCount == 10 ? 450 : 50;
    }
    return total;
  }

  void addSession(List<GachaItem> items, int drawCount) {
    int sessionBadgeTotal = 0;

    for (final item in items) {
      // Skip duplication logic for actual Badge items
      if (item.name == 'Badge') {
        sessionBadgeTotal += item.badgeValue;
        continue;
      }

      // Check if this is an emote item
      if (item.emotes != null && item.emotes!.isNotEmpty) {
        final emoteName = item.emotes![0].name;
        
        // Check if emote is already owned
        if (_ownedEmotes.contains(emoteName)) {
          // Duplicate emote → convert to badges
          final badgeValue = item.convertToBadges();
          item.badgeValue = badgeValue;
          item.isConverted = true;
          sessionBadgeTotal += badgeValue;
        } else {
          // Add emote to owned list
          _ownedEmotes.add(emoteName);
          
          // Also add to owned items
          _ownedItems.add(item.uniqueId);
        }
      } else {
        // Handle regular items
        final uniqueId = item.uniqueId;

        if (_ownedItems.contains(uniqueId)) {
          // Duplicate → convert to badges
          final badgeValue = item.convertToBadges();
          item.badgeValue = badgeValue;
          item.isConverted = true;
          sessionBadgeTotal += badgeValue;
        } else {
          _ownedItems.add(uniqueId);
        }
      }
    }

    _drawSessions.add(DrawSession(
      items: items,
      drawCount: drawCount,
      badgeTotal: sessionBadgeTotal,
    ));

    _badgeTotal += sessionBadgeTotal;
    _totalDraws += drawCount;

    notifyListeners();
  }

  // Check if an item is already owned
  bool isItemOwned(GachaItem item) {
    // For emotes, check by emote name
    if (item.emotes != null && item.emotes!.isNotEmpty) {
      return _ownedEmotes.contains(item.emotes![0].name);
    }
    
    // For regular items, check by uniqueId
    return _ownedItems.contains(item.uniqueId);
  }
  
  // Check if an emote is already owned
  bool isEmoteOwned(String emoteName) {
    return _ownedEmotes.contains(emoteName);
  }
  
  // UPDATED: Purchase an item with badges
  void purchaseItem(GachaItem item) {
    if (_badgeTotal < item.price || isItemOwned(item)) {
      return; // Not enough badges or already owned
    }
    
    // Deduct the badges
    _badgeTotal -= item.price.toInt();
    
    // Add to owned items
    _ownedItems.add(item.uniqueId);
    
    // Create a virtual draw session for this purchase
    final purchasedItem = GachaItem(
      item.name,
      item.rate,
      item.icon,
      item.color,
      price: item.price,
      skinCharacter: item.skinCharacter,
      emotes: item.emotes,
    );
    
    _drawSessions.add(DrawSession(
      items: [purchasedItem],
      drawCount: 0, // Not from a gacha pull
      badgeTotal: -item.price.toInt(), // Negative to show spent
    ));
    
    notifyListeners();
  }
  
  // UPDATED: Purchase an emote with badges
  void purchaseEmote(String emoteName, double price, Color emoteColor, String description) {
    if (_badgeTotal < price || isEmoteOwned(emoteName)) {
      return; // Not enough badges or already owned
    }
    
    // Deduct the badges
    _badgeTotal -= price.toInt();
    
    // Add to owned emotes
    _ownedEmotes.add(emoteName);
    
    // Create an emote object to match how emotes are stored from gacha pulls
    final emoteObj = Emote(
      name: emoteName,
      description: description,
      color: emoteColor,
    );
    
    // Create a virtual GachaItem that contains the emote
    // Use the exact same name format as when pulled from gacha
    final purchasedItem = GachaItem(
      emoteName, // Use the EXACT same name format as when pulled from gacha
      0.0,
      Icons.emoji_emotions,
      emoteColor,
      price: price,
      emotes: [emoteObj], // Include the emote in the emotes list
    );
    
    _drawSessions.add(DrawSession(
      items: [purchasedItem],
      drawCount: 0, // Not from a gacha pull
      badgeTotal: -price.toInt(), // Negative to show spent
    ));
    
    notifyListeners();
  }

  // Mark guaranteed reward as claimed
  void markGuaranteedGiven() {
    _guaranteedGiven = true;
    notifyListeners();
  }

  // Clear history and reset state
  void resetHistory() {
    _drawSessions.clear();
    _ownedItems.clear();
    _ownedEmotes.clear();
    _badgeTotal = 0;
    _totalDraws = 0;
    _guaranteedGiven = false;
    notifyListeners();
  }
}