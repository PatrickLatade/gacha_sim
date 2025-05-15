import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/history_manager.dart';
import '../models/gacha_items.dart';
import '../utils/color_extension.dart';

class CollectionPage extends StatelessWidget {
  const CollectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final historyManager = Provider.of<HistoryManager>(context);

    // Gather all items from draw sessions
    final allItems = historyManager.drawSessions
        .expand((session) => session.items)
        .where((item) => item.badgeValue == 0) // Assuming we want to exclude badges here
        .toList();

    // Filter out duplicates by name and skinCharacter
    final seenItems = <String>{};
    final uniqueItems = allItems.where((item) {
      final uniqueKey = item.skinCharacter ?? item.name;
      return seenItems.add(uniqueKey);  // Ensure unique items based on character
    }).toList();

    // Split items into categories
    final collabSkins = uniqueItems.where((item) => item.skinCharacter != null).toList();
    final emotes = uniqueItems.where((item) => item.emotes != null && item.emotes!.isNotEmpty).toList();
    final collectibles = uniqueItems.where((item) => item.skinCharacter == null && item.emotes == null).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Your Collection')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (collabSkins.isNotEmpty) ...[
            _buildSectionHeader('Collab Skins'),
            _buildItemGrid(collabSkins),
          ],
          if (emotes.isNotEmpty) ...[
            _buildSectionHeader('Emotes'),
            _buildItemGrid(emotes),
          ],
          if (collectibles.isNotEmpty) ...[
            _buildSectionHeader('Collectibles'),
            _buildItemGrid(collectibles),
          ],
          if (uniqueItems.isEmpty)
            const Center(child: Text('You haven’t pulled any items yet.')),
        ],
      ),
    );
  }

  // Builds a header for each section (Collab Skins, Emotes, Collectibles)
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Builds a grid of items for each section
  Widget _buildItemGrid(List<GachaItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),  // Prevent scrolling within the grid
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        final item = items[index];

        // Get the color for this specific skin (collab skin)
        final skinColor = item.skinCharacter != null
            ? getSkinColor(item.skinCharacter!)
            : item.color;

        return Container(
          decoration: BoxDecoration(
            color: skinColor.withAlphaPercent(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: skinColor, width: 2),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: skinColor, size: 48),
              const SizedBox(height: 8),
              Text(
                item.skinCharacter ?? item.name,  // Display character if available
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: skinColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
