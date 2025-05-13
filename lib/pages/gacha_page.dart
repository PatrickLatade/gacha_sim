import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../models/gacha_items.dart';
import '../models/history_manager.dart';

class GachaPage extends StatefulWidget {
  @override
  State<GachaPage> createState() => _GachaPageState();
}

class _GachaPageState extends State<GachaPage> {
  final List<GachaItem> _items = [
    GachaItem('Collaboration Skin', 0.08, Icons.checkroom, Colors.red),
    GachaItem('Recall Effect', 0.3, Icons.menu_book, Colors.green),
    GachaItem('Kill Removal Effect', 0.5, Icons.dangerous, Colors.purple),
    GachaItem('Kill Notification', 0.5, Icons.notifications, Colors.grey),
    GachaItem('Emote', 7.95, Icons.emoji_emotions, Colors.amber),
    GachaItem('Badge', 90.67, Icons.verified, Colors.blue),
  ];

  final List<int> badgeValues = [20, 15, 12, 10, 8, 5];
  int _totalDrawCount = 0;
  bool _guaranteedGiven = false;

  final ConfettiController _confettiController = ConfettiController(duration: const Duration(seconds: 1));
  List<GachaItem> _lastDrawnItems = [];

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _drawItem(BuildContext context, {int times = 1}) {
    final totalRate = _items.fold(0.0, (sum, item) => sum + item.rate);
    final List<GachaItem> drawnItems = [];

    for (int i = 0; i < times; i++) {
      final double roll = Random().nextDouble() * totalRate;
      double cumulative = 0.0;
      GachaItem? selectedItem;

      for (final item in _items) {
        cumulative += item.rate;
        if (roll <= cumulative) {
          selectedItem = GachaItem.clone(item); // Prevent modifying shared state
          break;
        }
      }

      if (selectedItem != null) {
        if (selectedItem.name == 'Badge') {
          selectedItem.badgeValue = badgeValues[Random().nextInt(badgeValues.length)];
        }

        drawnItems.add(selectedItem);

        if (selectedItem.name == 'Collaboration Skin') {
          _confettiController.play();
        }
      }

      _totalDrawCount++;
    }

    // ✅ Apply guarantee on *first* time reaching 10 draws
    if (_totalDrawCount >= 10 && !_guaranteedGiven) {
      const guaranteedPool = [
        'Collaboration Skin',
        'Recall Effect',
        'Kill Removal Effect',
        'Kill Notification',
        'Emote',
      ];

      bool hasGuaranteed = drawnItems.any((item) => guaranteedPool.contains(item.name));

      if (!hasGuaranteed) {
        final randomName = guaranteedPool[Random().nextInt(guaranteedPool.length)];
        final itemToInject = _items.firstWhere((item) => item.name == randomName);
        drawnItems[0] = GachaItem.clone(itemToInject);

        if (itemToInject.name == 'Collaboration Skin') {
          _confettiController.play();
        }
      }

      _guaranteedGiven = true;
    }

    Provider.of<HistoryManager>(context, listen: false).addSession(drawnItems, times);

    setState(() {
      _lastDrawnItems = drawnItems;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('Gacha Simulator')),
          body: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ Add Banner
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '🎉 Guaranteed Rare Item on Your First 10th Draw!',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Draw buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => _drawItem(context, times: 1),
                        child: const Text('Draw 1'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _drawItem(context, times: 10),
                        child: const Text('Draw 10'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 20),

                  if (_lastDrawnItems.isNotEmpty) ...[
                    const Text(
                      'You got:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: _lastDrawnItems.map((item) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(item.icon, size: 40, color: item.color),
                            const SizedBox(height: 4),
                            Text(item.name, style: const TextStyle(fontSize: 14)),
                            if (item.badgeValue > 0)
                              Text('+${item.badgeValue} badges', style: const TextStyle(fontSize: 12)),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
          ),
        ),
      ],
    );
  }
}
