import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../models/gacha_items.dart';
import '../models/history_manager.dart';
import '../utils/color_extension.dart';

class GachaPage extends StatefulWidget {
  const GachaPage({super.key});

  @override
  State<GachaPage> createState() => _GachaPageState();
}

class _GachaPageState extends State<GachaPage> with TickerProviderStateMixin {
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

  // Define lists for randomized values
  final List<int> badgeValues = [20, 15, 12, 10, 8, 5];
  final List<String> skinCharacters = [
    'Kakashi Hatake',
    'Sasuke Uchiha',
    'Naruto Uzumaki',
    'Sakura Haruno'
  ];
  
  bool _isDrawing = false;

  // Animations
  late AnimationController _revealController;
  late AnimationController _shakeController;
  late AnimationController _conversionController; // New controller for conversion animation
  late Animation<double> _shakeAnimation;
  final ConfettiController _confettiController = ConfettiController(duration: Duration(seconds: 2));
  List<GachaItem> _lastDrawnItems = [];

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(vsync: this, duration: Duration(milliseconds: 800));
    _shakeController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _conversionController = AnimationController(vsync: this, duration: Duration(milliseconds: 1200));
    
    _shakeAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticInOut,
    ));
    
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _shakeController.reverse();
    });
    
    // Start conversion animation after reveal is complete
    _revealController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _lastDrawnItems.any((item) => item.isConverted)) {
        _conversionController.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _revealController.dispose();
    _shakeController.dispose();
    _conversionController.dispose();
    super.dispose();
  }

  Future<void> _drawItem(BuildContext context, {int times = 1}) async {
    if (_isDrawing) return;

    setState(() {
      _isDrawing = true;
      _lastDrawnItems = [];
    });

    _revealController.reset();
    _conversionController.reset();
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
        // Create a subset of items for guaranteed pool (excluding Badge)
        final guaranteedItems = _items.where((item) => item.name != 'Badge').toList();
        
        // Calculate total rate for the guaranteed pool
        final guaranteedTotalRate = guaranteedItems.fold(0.0, (sum, item) => sum + item.rate);
        
        // Roll within the guaranteed pool using their original relative probabilities
        final double roll = Random().nextDouble() * guaranteedTotalRate;
        double cumulative = 0.0;
        
        for (final item in guaranteedItems) {
          cumulative += item.rate;
          if (roll <= cumulative) {
            selectedItem = GachaItem.clone(item);
            break;
          }
        }
        
        history.markGuaranteedGiven(); // Mark that guarantee has been triggered
      } else {
        // Regular gacha roll
        final totalRate = _items.fold(0.0, (sum, item) => sum + item.rate);
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
        } else if (selectedItem.name == 'Collaboration Skin') {
          selectedItem.skinCharacter = skinCharacters[Random().nextInt(skinCharacters.length)];
        } else if (selectedItem.name == 'Emote' && selectedItem.emotes != null && selectedItem.emotes!.isNotEmpty) {
          final randomEmote = selectedItem.emotes![Random().nextInt(selectedItem.emotes!.length)];
          selectedItem = GachaItem(
            randomEmote.name,
            selectedItem.rate,
            selectedItem.icon,
            randomEmote.color,
            emotes: [randomEmote],
          );
        }

        // Check if this is a duplicate item
        final isDuplicate = history.isItemOwned(selectedItem);
        if (isDuplicate && selectedItem.name != 'Badge') {
          // Mark as converted for animation purposes
          selectedItem.isConverted = true;
        }

        drawnItems.add(selectedItem);

        // Play effects for rare items
        if (selectedItem.name == 'Collaboration Skin' && !isDuplicate) {
          _confettiController.play();
          _shakeController.forward(from: 0.0);
        }
      }

      if (times > 1 && i < times - 1) {
        await Future.delayed(Duration(milliseconds: 50));
      }
    }

    // Add items to history (which will also check for duplicates)
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
                      animation: Listenable.merge([_revealController, _conversionController]),
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
                            final isRare = item.name == 'Collaboration Skin' && !item.isConverted;
                            
                            // Handle conversion animation
                            if (item.isConverted) {
                              final conversionProgress = _conversionController.value;
                              final showBadges = conversionProgress > 0.5;
                              
                              // First half of animation: show original item
                              if (!showBadges) {
                                return Transform.scale(
                                  scale: 0.5 + (0.5 * animationValue) * (1 - conversionProgress * 2),
                                  child: Opacity(
                                    opacity: animationValue * (1 - conversionProgress * 2),
                                    child: _buildItemContainer(item, isRare, showDuplicate: true),
                                  ),
                                );
                              } 
                              // Second half of animation: show badges
                              else {
                                final badgeProgress = (conversionProgress - 0.5) * 2;
                                return Transform.scale(
                                  scale: 0.5 + (0.5 * badgeProgress),
                                  child: Opacity(
                                    opacity: badgeProgress,
                                    child: _buildBadgeContainer(item),
                                  ),
                                );
                              }
                            }
                            
                            // Regular non-converted item
                            return Transform.scale(
                              scale: 0.5 + (0.5 * animationValue),
                              child: Opacity(
                                opacity: animationValue,
                                child: _buildItemContainer(item, isRare),
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
  
  // Helper to build item container
  Widget _buildItemContainer(GachaItem item, bool isRare, {bool showDuplicate = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRare ? Colors.amber.withAlphaPercent(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isRare
            ? Border.all(color: Colors.amber, width: 2)
            : Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: isRare ? Colors.amber.withAlphaPercent(0.5) : Colors.black12,
            blurRadius: 8,
            spreadRadius: isRare ? 2 : 0,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Icon(item.icon, size: 50, color: item.color),
              if (showDuplicate)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    'x2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isRare ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (item.badgeValue > 0 && !item.isConverted)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${item.badgeValue} badges',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          if (item.skinCharacter != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                item.skinCharacter!,
                style: TextStyle(
                  fontSize: 14,
                  color: getSkinColor(item.skinCharacter!),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper to build badge conversion container
  Widget _buildBadgeContainer(GachaItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withAlphaPercent(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withAlphaPercent(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 50, color: Colors.blue),
          const SizedBox(height: 8),
          Text(
            'Converted to',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
          Text(
            '+${item.badgeValue} badges',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}