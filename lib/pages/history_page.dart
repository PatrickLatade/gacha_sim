import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/history_manager.dart';
import '../utils/color_extension.dart';

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
                                    // Handle converted items
                                    if (item.isConverted) {
                                      return _buildConvertedItemContainer(item);
                                    }
                                    
                                    // Handle regular items
                                    final isCollabSkin = item.skinCharacter != null;
                                    final skinColor = isCollabSkin
                                        ? getSkinColor(item.skinCharacter!)
                                        : item.color;
                                    
                                    return _buildRegularItemContainer(item, skinColor);
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
  
  Widget _buildRegularItemContainer(item, Color skinColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.icon, size: 32, color: skinColor),
        const SizedBox(height: 4),
        Text(
          item.skinCharacter ?? item.name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: skinColor,
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
  }
  
  Widget _buildConvertedItemContainer(item) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.amber.withAlphaPercent(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withAlphaPercent(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 20, color: item.color.withOpacity(0.7)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Icon(Icons.verified, size: 20, color: Colors.blue),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '+${item.badgeValue}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}