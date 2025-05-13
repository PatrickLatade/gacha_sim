// Same imports
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

class _GachaPageState extends State<GachaPage> with TickerProviderStateMixin {
  final List<GachaItem> _items = [
    GachaItem('Collaboration Skin', 0.08, Icons.checkroom, Colors.red),
    GachaItem('Recall Effect', 0.3, Icons.menu_book, Colors.green),
    GachaItem('Kill Removal Effect', 0.5, Icons.dangerous, Colors.purple),
    GachaItem('Kill Notification', 0.5, Icons.notifications, Colors.grey),
    GachaItem('Emote', 7.95, Icons.emoji_emotions, Colors.amber),
    GachaItem('Badge', 90.67, Icons.verified, Colors.blue),
  ];

  final List<int> badgeValues = [20, 15, 12, 10, 8, 5];
  bool _isDrawing = false;

  // Animations
  late AnimationController _revealController;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  final ConfettiController _confettiController = ConfettiController(duration: Duration(seconds: 2));
  List<GachaItem> _lastDrawnItems = [];

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(vsync: this, duration: Duration(milliseconds: 800));
    _shakeController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _shakeAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticInOut,
    ));
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _shakeController.reverse();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _revealController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _drawItem(BuildContext context, {int times = 1}) async {
    if (_isDrawing) return;

    setState(() {
      _isDrawing = true;
      _lastDrawnItems = [];
    });

    _revealController.reset();
    final totalRate = _items.fold(0.0, (sum, item) => sum + item.rate);
    final List<GachaItem> drawnItems = [];

    final history = Provider.of<HistoryManager>(context, listen: false);
    int currentTotalDraws = history.totalDraws;
    bool guaranteedGiven = history.guaranteedGiven;

    await Future.delayed(Duration(milliseconds: 300));

    for (int i = 0; i < times; i++) {
      currentTotalDraws++;

      bool isGuaranteedDraw = (currentTotalDraws == 10) && !guaranteedGiven;

      GachaItem? selectedItem;

      if (isGuaranteedDraw) {
        // Force a rare item from the guaranteed pool
        const guaranteedPool = [
          'Collaboration Skin',
          'Recall Effect',
          'Kill Removal Effect',
          'Kill Notification',
          'Emote',
        ];
        final randomName = guaranteedPool[Random().nextInt(guaranteedPool.length)];
        selectedItem = GachaItem.clone(_items.firstWhere((item) => item.name == randomName));
        history.markGuaranteedGiven(); // Mark that guarantee has been triggered

        if (selectedItem.name == 'Collaboration Skin') {
          _confettiController.play();
          _shakeController.forward(from: 0.0);
        }
      } else {
        // Regular gacha roll
        final double roll = Random().nextDouble() * totalRate;
        double cumulative = 0.0;
        for (final item in _items) {
          cumulative += item.rate;
          if (roll <= cumulative) {
            selectedItem = GachaItem.clone(item);
            break;
          }
        }
      }

      if (selectedItem != null) {
        if (selectedItem.name == 'Badge') {
          selectedItem.badgeValue = badgeValues[Random().nextInt(badgeValues.length)];
        }

        drawnItems.add(selectedItem);

        if (selectedItem.name == 'Collaboration Skin' && !isGuaranteedDraw) {
          _confettiController.play();
          _shakeController.forward(from: 0.0);
        }
      }

      if (times > 1 && i < times - 1) {
        await Future.delayed(Duration(milliseconds: 50));
      }
    }

    history.addSession(drawnItems, times);

    setState(() {
      _lastDrawnItems = drawnItems;
      _isDrawing = false;
    });

    _revealController.forward();
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
                children: [
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(_shakeAnimation.value, 0),
                      child: child,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4.0,
                            offset: Offset(0, 2),
                          )
                        ],
                      ),
                      child: const Text(
                        '🎉 Guaranteed Rare Item on Your First 10th Draw!',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _isDrawing ? null : () => _drawItem(context, times: 1),
                        child: _isDrawing
                            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text('Draw 1'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _isDrawing ? null : () => _drawItem(context, times: 10),
                        child: _isDrawing
                            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text('Draw 10'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  if (_lastDrawnItems.isNotEmpty) ...[
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.6, end: 1.0).animate(
                        CurvedAnimation(parent: _revealController, curve: Curves.elasticOut),
                      ),
                      child: FadeTransition(
                        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(parent: _revealController, curve: Curves.easeIn),
                        ),
                        child: const Text(
                          'You got:',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedBuilder(
                      animation: _revealController,
                      builder: (context, child) {
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: List.generate(_lastDrawnItems.length, (index) {
                            final delay = index * 0.1;
                            final startValue = delay;
                            final endValue = 1.0;
                            double animationValue = 0.0;
                            if (_revealController.value > startValue) {
                              animationValue = (_revealController.value - startValue) / (endValue - startValue);
                              animationValue = animationValue.clamp(0.0, 1.0);
                            }
                            final item = _lastDrawnItems[index];
                            final isRare = item.name == 'Collaboration Skin';
                            return Transform.scale(
                              scale: 0.5 + (0.5 * animationValue),
                              child: Opacity(
                                opacity: animationValue,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isRare ? Colors.amber.withOpacity(0.2) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: isRare
                                        ? Border.all(color: Colors.amber, width: 2)
                                        : Border.all(color: Colors.grey.shade300),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isRare ? Colors.amber.withOpacity(0.5) : Colors.black12,
                                        blurRadius: 8,
                                        spreadRadius: isRare ? 2 : 0,
                                      )
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(item.icon, size: 50, color: item.color),
                                      const SizedBox(height: 8),
                                      Text(
                                        item.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isRare ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                      if (item.badgeValue > 0)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            '+${item.badgeValue} badges',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      },
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
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.1,
            shouldLoop: false,
            colors: const [Colors.red, Colors.amber, Colors.purple, Colors.green, Colors.blue],
          ),
        ),
      ],
    );
  }
}
