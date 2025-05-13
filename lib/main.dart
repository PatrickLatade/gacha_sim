import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/history_manager.dart';
import 'pages/gacha_page.dart';
import 'pages/history_page.dart';
import 'pages/shop_page.dart';
import 'pages/collection_page.dart';
import 'widgets/persistent_badge.dart'; // ✅ <-- ADD THIS IMPORT

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => HistoryManager(),
      child: const GachaApp(),
    ),
  );
}

class GachaApp extends StatelessWidget {
  const GachaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gacha Simulator',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    GachaPage(),
    HistoryPage(),
    ShopPage(),
    CollectionPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: _pages[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.blue,
            onTap: (index) {
              setState(() => _currentIndex = index);
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.casino), label: 'Gacha'),
              BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
              BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Shop'),
              BottomNavigationBarItem(icon: Icon(Icons.collections), label: 'Collection'),
            ],
          ),
        ),
        const PersistentBadge(), // ✅ Always displayed on top-right
      ],
    );
  }
}
