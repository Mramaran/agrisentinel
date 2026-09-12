import 'package:flutter/material.dart';

const kGreen = Color(0xFF2C5F2D);
const kMoss = Color(0xFF97BC62);
const kOrange = Color(0xFFE97132);
const kRed = Color(0xFFC0392B);
const kYellow = Color(0xFFE9C46A);
const kNavy = Color(0xFF0E2841);

void main() => runApp(const AgriSentinelApp());

class AgriSentinelApp extends StatelessWidget {
  const AgriSentinelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriSentinel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kGreen),
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _titles = ['Home', 'Scan', 'Map', 'Alerts', 'Expert'];

  @override
  Widget build(BuildContext context) {
    final pages = [
      for (final t in _titles) Center(child: Text('$t coming soon')),
    ];
    return Scaffold(
      appBar: AppBar(title: Text('AgriSentinel  ·  ${_titles[_index]}')),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.camera_alt_outlined), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.verified_outlined), label: 'Expert'),
        ],
      ),
    );
  }
}
