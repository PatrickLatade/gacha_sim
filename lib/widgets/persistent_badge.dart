import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/history_manager.dart';

class PersistentBadge extends StatelessWidget {
  const PersistentBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final badgeTotal = context.watch<HistoryManager>().badgeTotal;

    return Positioned(
      top: 30,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified, color: Colors.white, size: 25), // moderately sized icon
            const SizedBox(width: 5),
            Text(
              '$badgeTotal',
              style: const TextStyle(
                fontSize: 20, // moderate font size
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
