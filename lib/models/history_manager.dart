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

  // 🔁 New state: tracking total draws and guarantee flag
  int _totalDraws = 0;
  bool _guaranteedGiven = false;

  // 🔁 Expose new values via getters
  List<DrawSession> get drawSessions => _drawSessions.reversed.toList();
  int get badgeTotal => _badgeTotal;
  int get totalDraws => _totalDraws;
  bool get guaranteedGiven => _guaranteedGiven;

  void addSession(List<GachaItem> items, int drawCount) {
    int sessionBadgeTotal = 0;

    for (var item in items) {
      sessionBadgeTotal += item.badgeValue;
    }

    _drawSessions.add(
      DrawSession(items: items, drawCount: drawCount, badgeTotal: sessionBadgeTotal),
    );

    _badgeTotal += sessionBadgeTotal;

    // 🔁 Update draw counter
    _totalDraws += drawCount;

    notifyListeners();
  }

  // 🔁 Mark guaranteed reward as claimed
  void markGuaranteedGiven() {
    _guaranteedGiven = true;
    notifyListeners();
  }

  // Optional: reset everything (for debug or reset button)
  void resetHistory() {
    _drawSessions.clear();
    _badgeTotal = 0;
    _totalDraws = 0;
    _guaranteedGiven = false;
    notifyListeners();
  }

  // Optional: diamonds spent tracker
  int get totalDiamondsSpent {
    int total = 0;
    for (var session in _drawSessions) {
      total += session.drawCount == 10 ? 450 : 50;
    }
    return total;
  }
}
