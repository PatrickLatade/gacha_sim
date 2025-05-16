import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gacha_service.dart';
import '../models/gacha_items.dart';
import '../models/history_manager.dart';
import '../utils/color_extension.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final GachaService gachaService = GachaService();
    final List<GachaItem> items = gachaService.items;
    final historyManager = Provider.of<HistoryManager>(context);

    final List<GachaItem> processedItems = _processItems(items, gachaService);

    final collabSkins = processedItems
        .where((item) =>
            item.name == 'Collaboration Skin' && item.skinCharacter != null)
        .toList();

    // Flatten the emotes from all GachaItems that have emotes into a single list of EmoteWidgets
    final List<_EmoteDisplayData> allEmotes = [];
    
    // First, get all emotes from owned items
    final Set<String> ownedEmoteNames = {};
    for (final session in historyManager.drawSessions) {
      for (final item in session.items) {
        if (item.emotes != null && item.emotes!.isNotEmpty && !item.isConverted) {
          for (final emote in item.emotes!) {
            ownedEmoteNames.add(emote.name);
          }
        }
      }
    }
    
    // Now create display data for all emotes
    for (var item in processedItems) {
      if (item.emotes != null && item.emotes!.isNotEmpty) {
        for (var emote in item.emotes!) {
          allEmotes.add(_EmoteDisplayData(
            name: emote.name,
            description: emote.description,
            color: emote.color,
            price: item.price,
            isOwned: ownedEmoteNames.contains(emote.name),
          ));
        }
      }
    }

    final collectibles = processedItems.where((item) =>
        item.name != 'Collaboration Skin' &&
        item.name != 'Badge' &&
        (item.emotes == null || item.emotes!.isEmpty)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gacha Shop'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (collabSkins.isNotEmpty) ...[
                  _buildSectionHeader('✨ Collab Skins'),
                  const SizedBox(height: 8),
                  _buildPortraitGrid(context, collabSkins, historyManager),
                  const SizedBox(height: 20),
                ],
                if (allEmotes.isNotEmpty) ...[
                  _buildSectionHeader('🎭 Emotes'),
                  const SizedBox(height: 8),
                  ..._buildEmoteList(context, allEmotes, historyManager),
                  const SizedBox(height: 20),
                ],
                if (collectibles.isNotEmpty) ...[
                  _buildSectionHeader('🎁 Collectibles'),
                  const SizedBox(height: 8),
                  ..._buildItemList(context, collectibles, historyManager),
                  const SizedBox(height: 20),
                ],
                if (processedItems.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
                        const SizedBox(height: 10),
                        const Text(
                          'No items available in the shop.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<GachaItem> _processItems(List<GachaItem> items, GachaService gachaService) {
    final List<GachaItem> processedItems = [];

    for (var item in items) {
      if (item.name == 'Collaboration Skin') {
        for (var character in gachaService.skinCharacters) {
          final Color characterColor = getSkinColor(character);
          final collabSkin = GachaItem(
            'Collaboration Skin',
            item.rate,
            item.icon,
            characterColor,
            price: item.price,
            skinCharacter: character,
          );
          processedItems.add(collabSkin);
        }
      } else {
        processedItems.add(item);
      }
    }

    return processedItems;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  // Handle item purchase
  void _purchaseItem(BuildContext context, GachaItem item, HistoryManager historyManager) {
    if (historyManager.badgeTotal < item.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough badges to purchase ${item.skinCharacter ?? item.name}'),
          backgroundColor: Colors.red.shade400,
        ),
      );
      return;
    }

    // Confirm purchase
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Purchase'),
        content: Text('Purchase ${item.skinCharacter ?? item.name} for ${item.price.toInt()} badges?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              historyManager.purchaseItem(item);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Successfully purchased ${item.skinCharacter ?? item.name}!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.black,
              disabledForegroundColor: Colors.black, 
            ),
            child: const Text('Purchase'),
          ),
        ],
      ),
    );
  }
  
  // Handle emote purchase - UPDATED to pass color and description
  void _purchaseEmote(BuildContext context, _EmoteDisplayData emote, HistoryManager historyManager) {
    if (historyManager.badgeTotal < emote.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough badges to purchase ${emote.name}'),
          backgroundColor: Colors.red.shade400,
        ),
      );
      return;
    }

    // Confirm purchase
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Purchase'),
        content: Text('Purchase ${emote.name} for ${emote.price.toInt()} badges?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Pass the emote's color and description to correctly record it
              historyManager.purchaseEmote(
                emote.name, 
                emote.price,
                emote.color,
                emote.description,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Successfully purchased ${emote.name}!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.black,
              disabledForegroundColor: Colors.black, 
            ),
            child: const Text('Purchase'),
          ),
        ],
      ),
    );
  }

  // Updated to add purchase functionality
  List<Widget> _buildItemList(BuildContext context, List<GachaItem> items, HistoryManager historyManager) {
    return items.map((item) {
      final bool isOwned = historyManager.isItemOwned(item);
      final bool canPurchase = historyManager.badgeTotal >= item.price;
      
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  backgroundColor: item.color.withAlphaPercent(0.2),
                  child: Icon(item.icon, color: item.color, size: 30),
                ),
                if (isOwned)
                  const CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.check, color: Colors.white, size: 12),
                  ),
              ],
            ),
            title: Text(
              item.skinCharacter ?? item.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isOwned ? Colors.grey : Colors.black,
              ),
            ),
            subtitle: Row(
              children: [
                Text('${item.price.toInt()}'),
                const SizedBox(width: 6),
                const Icon(Icons.verified, color: Colors.blue, size: 16),
                if (isOwned) ...[
                  const Spacer(),
                  const Text(
                    'Owned',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            trailing: isOwned 
              ? null
              : ElevatedButton(
                  onPressed: canPurchase 
                    ? () => _purchaseItem(context, item, historyManager) 
                    : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    disabledBackgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black, 
                  ),
                  child: const Text('Buy'),
                ),
          ),
        ),
      );
    }).toList();
  }

  // Updated to add purchase functionality
  List<Widget> _buildEmoteList(BuildContext context, List<_EmoteDisplayData> emotes, HistoryManager historyManager) {
    return emotes.map((emote) {
      final bool canPurchase = historyManager.badgeTotal >= emote.price;
      
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  backgroundColor: emote.color.withAlphaPercent(0.2),
                  child: Icon(Icons.emoji_emotions, color: emote.color, size: 30),
                ),
                if (emote.isOwned)
                  const CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.check, color: Colors.white, size: 12),
                  ),
              ],
            ),
            title: Text(
              emote.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: emote.isOwned ? Colors.grey : Colors.black,
              ),
            ),
            subtitle: Row(
              children: [
                Text('${emote.price.toInt()}'),
                const SizedBox(width: 6),
                const Icon(Icons.verified, color: Colors.blue, size: 16),
                if (emote.isOwned) ...[
                  const Spacer(),
                  const Text(
                    'Owned',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            trailing: emote.isOwned 
              ? null
              : ElevatedButton(
                  onPressed: canPurchase 
                    ? () => _purchaseEmote(context, emote, historyManager) 
                    : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    disabledBackgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black, 
                  ),
                  child: const Text('Buy'),
                ),
          ),
        ),
      );
    }).toList();
  }

  // Updated grid to show owned items and purchase option
  Widget _buildPortraitGrid(BuildContext context, List<GachaItem> items, HistoryManager historyManager) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;
    final crossAxisCount = isWide ? 3 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3 / 5,  // Adjusted to fit purchase button
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isOwned = historyManager.isItemOwned(item);
        final bool canPurchase = historyManager.badgeTotal >= item.price;
        
        return AnimatedSwitcher(
          duration: Duration(milliseconds: 400 + (index * 100)),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: Card(
            key: ValueKey(item.skinCharacter),
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: isOwned 
                  ? const BorderSide(color: Colors.green, width: 2) 
                  : BorderSide.none,
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon, 
                        color: isOwned ? item.color.withAlphaPercent(0.6) : item.color, 
                        size: 50,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.skinCharacter ?? 'Unknown',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isOwned ? Colors.grey : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${item.price.toInt()}'),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Colors.blue, size: 16),
                        ],
                      ),
                      if (isOwned) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Owned',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: canPurchase 
                            ? () => _purchaseItem(context, item, historyManager)
                            : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            disabledBackgroundColor: Colors.grey.shade300,
                            minimumSize: const Size.fromHeight(36),
                            foregroundColor: Colors.black, 
                          ),
                          child: const Text('Buy'),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isOwned)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.green,
                      child: Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Updated helper class with isOwned property
class _EmoteDisplayData {
  final String name;
  final String description;
  final Color color;
  final double price;
  final bool isOwned;

  _EmoteDisplayData({
    required this.name,
    required this.description,
    required this.color,
    required this.price,
    required this.isOwned,
  });
}