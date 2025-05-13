import 'package:flutter/material.dart';
import 'gacha_items.dart';

class DrawSession {
  final List<GachaItem> items;
  final int drawCount; // 1 or 10
  final int badgeTotal;

  DrawSession({required this.items, required this.drawCount, required this.badgeTotal});
}

class HistoryManager with ChangeNotifier {
  final List<DrawSession> _drawSessions = [];
  int _badgeTotal = 0;

  List<DrawSession> get drawSessions => _drawSessions.reversed.toList();

  int get badgeTotal => _badgeTotal;

  void addSession(List<GachaItem> items, int drawCount) {
    int sessionBadgeTotal = 0; // Track badges in the current session

    // Calculate the total badges earned in this session
    for (var item in items) {
      sessionBadgeTotal += item.badgeValue;
    }

    _drawSessions.add(DrawSession(items: items, drawCount: drawCount, badgeTotal: sessionBadgeTotal));

    // Accumulate badge value in total
    _badgeTotal += sessionBadgeTotal;

    notifyListeners();
  }

  int get totalDiamondsSpent {
    int total = 0;
    for (var session in _drawSessions) {
      total += session.drawCount == 10 ? 450 : 50;
    }
    return total;
  }
}
