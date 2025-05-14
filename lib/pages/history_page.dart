import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/history_manager.dart';
import '../utils/color_extension.dart'; // Import your color extension

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final history = Provider.of<HistoryManager>(context);
    final drawSessions = history.drawSessions;
    final totalDiamonds = history.totalDiamondsSpent;
    final totalDraws = history.totalDraws;

    return Scaffold(
      appBar: AppBar(title: const Text('Draw History')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: drawSessions.isEmpty
            ? const Center(child: Text('No draws yet.'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Diamonds Spent: $totalDiamonds 💎',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Total Draws Made: $totalDraws 🎯',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: drawSessions.length,
                      itemBuilder: (context, index) {
                        final session = drawSessions[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Draw Type: ${session.drawCount == 10 ? '10x Draw (450 💎)' : '1x Draw (50 💎)'}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Total Badges Earned: ${session.badgeTotal}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: session.items.map((item) {
                                    final isCollabSkin = item.skinCharacter != null;
                                    final skinColor = isCollabSkin
                                        ? getSkinColor(item.skinCharacter!) // Use color from the extension
                                        : item.color; // Use original color for non-collabs
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(item.icon, size: 32, color: skinColor), // Icon with correct color
                                        const SizedBox(height: 4),
                                        // Show either skinCharacter or name *below* the icon
                                        Text(
                                          isCollabSkin ? item.skinCharacter! : item.name,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: skinColor, // Apply the correct color
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        if (item.badgeValue > 0)
                                          Text(
                                            '+${item.badgeValue} badges',
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
