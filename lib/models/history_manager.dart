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
  int _badgeTotal = 0;
  int _totalDraws = 0;
  bool _guaranteedGiven = false;

  // Getters
  List<DrawSession> get drawSessions => _drawSessions.reversed.toList();
  Set<String> get ownedItems => _ownedItems;
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
    return _ownedItems.contains(item.uniqueId);
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
    _badgeTotal = 0;
    _totalDraws = 0;
    _guaranteedGiven = false;
    notifyListeners();
  }
}
