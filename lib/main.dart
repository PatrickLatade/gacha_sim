import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

void main() {
  runApp(GachaApp());
}

class GachaApp extends StatelessWidget {
  const GachaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Gacha Simulator',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: GachaHomePage(),
    );
  }
}

class GachaHomePage extends StatefulWidget {
  const GachaHomePage({super.key});

  @override
  State<GachaHomePage> createState() => _GachaHomePageState();
}

class _GachaItem {
  final String name;
  final double rate;
  final IconData icon;
  final Color color;
  int badgeValue = 0;

  _GachaItem(this.name, this.rate, this.icon, this.color);
}

class _GachaHomePageState extends State<GachaHomePage> {
  final Random random = Random();
  List<Widget> results = [];
  List<Widget> history = [];
  int badgeCount = 0;
  int totalDraws = 0;
  int totalDiamondsSpent = 0;
  bool hasGuaranteedDropOccurred = false;
  int drawCounter = 0;

  final ScrollController _scrollController = ScrollController();
  late ConfettiController _confettiController;

  final List<_GachaItem> gachaPool = [
    _GachaItem('Collaboration Skin', 0.08, Icons.checkroom, Colors.red),
    _GachaItem('Recall Effect', 0.3, Icons.menu_book, Colors.green),
    _GachaItem('Kill Removal Effect', 0.5, Icons.dangerous, Colors.purple),
    _GachaItem('Kill Notification', 0.5, Icons.notifications, Colors.grey),
    _GachaItem('Emote', 7.95, Icons.emoji_emotions, Colors.amber),
    _GachaItem('Badge', 90.67, Icons.verified, Colors.blue),
  ];

  final List<int> badgeValues = [20, 15, 12, 10, 8, 5];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void draw(int times) {
    List<Widget> pulls = [];
    List<Widget> staticPulls = [];
    int cost = (times == 10) ? 450 : 50;
    bool shouldCelebrate = false;

    for (int i = 0; i < times; i++) {
      drawCounter++;
      bool applyGuarantee = (drawCounter == 10 && !hasGuaranteedDropOccurred);

      if (applyGuarantee) {
        hasGuaranteedDropOccurred = true;
        List<_GachaItem> guaranteedItems =
            gachaPool.where((item) => item.name != 'Badge').toList();
        double totalRate =
            guaranteedItems.fold(0, (sum, item) => sum + item.rate);
        double roll = random.nextDouble() * totalRate;
        double cumulative = 0;

        for (var item in guaranteedItems) {
          cumulative += item.rate;
          if (roll <= cumulative) {
            shouldCelebrate = true;
            pulls.add(ResultTile(item: item, badgeValue: item.badgeValue, delay: Duration(milliseconds: 100 * i)));
            staticPulls.add(ResultTile(item: item, badgeValue: item.badgeValue, delay: Duration.zero, animate: false));
            break;
          }
        }
      } else {
        double roll = random.nextDouble() * 100;
        double cumulative = 0;

        for (var item in gachaPool) {
          cumulative += item.rate;
          if (roll <= cumulative) {
            if (item.name == 'Badge') {
              item.badgeValue = badgeValues[random.nextInt(badgeValues.length)];
              badgeCount += item.badgeValue;
            } else if (item.name != 'Emote') {
              shouldCelebrate = true;
            }

            pulls.add(ResultTile(
              key: UniqueKey(),
              item: item,
              badgeValue: item.badgeValue,
              delay: Duration(milliseconds: 100 * i),
            ));

            staticPulls.add(ResultTile(
              key: UniqueKey(),
              item: item,
              badgeValue: item.badgeValue,
              delay: Duration.zero,
              animate: false,
            ));
            break;
          }
        }
      }
    }

    if (shouldCelebrate) {
      _confettiController.play();
    }

    setState(() {
      results = pulls;
      totalDraws += times;
      totalDiamondsSpent += cost;

      history.insert(
        0,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Draw ${times}x - Total Draws: $totalDraws | Diamonds Spent: $totalDiamondsSpent',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Wrap(spacing: 8, runSpacing: 8, children: staticPulls),
            Divider(),
          ],
        ),
      );

      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simple Gacha Simulator'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(Icons.verified, color: Colors.blue),
                SizedBox(width: 4),
                Text(
                  '$badgeCount',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton(onPressed: () => draw(1), child: Text('Draw 1x')),
                SizedBox(height: 12),
                ElevatedButton(onPressed: () => draw(10), child: Text('Draw 10x')),
                SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Results:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        ...results.map((r) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: r,
                            )),
                        SizedBox(height: 20),
                        Text('Draw History:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        ...history,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              maxBlastForce: 10,
              minBlastForce: 5,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class ResultTile extends StatefulWidget {
  final _GachaItem item;
  final int badgeValue;
  final Duration delay;
  final bool animate;

  const ResultTile({
    super.key,
    required this.item,
    required this.badgeValue,
    this.delay = Duration.zero,
    this.animate = true,
  });

  @override
  State<ResultTile> createState() => _ResultTileState();
}

class _ResultTileState extends State<ResultTile> with SingleTickerProviderStateMixin {
  double _scale = 0;
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      Future.delayed(widget.delay, () {
        if (mounted) {
          setState(() {
            _scale = 1;
            _opacity = 1;
          });
        }
      });
    } else {
      _scale = 1;
      _opacity = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: widget.animate ? Duration(milliseconds: 400) : Duration.zero,
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: widget.animate ? Duration(milliseconds: 300) : Duration.zero,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.item.icon, color: widget.item.color),
            SizedBox(width: 8),
            Text(
              widget.item.name,
              style: TextStyle(
                fontSize: 16,
                color: widget.item.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.item.name == 'Badge') ...[
              SizedBox(width: 8),
              Text(
                '+${widget.badgeValue} Badges',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}