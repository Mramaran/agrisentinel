import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/scan_screen.dart';
import 'state/demo_state.dart';

const kGreen = Color(0xFF2C5F2D);
const kMoss = Color(0xFF97BC62);
const kOrange = Color(0xFFE97132);
const kRed = Color(0xFFC0392B);
const kYellow = Color(0xFFE9C46A);
const kNavy = Color(0xFF0E2841);

final shellKey = GlobalKey<HomeShellState>();

void main() => runApp(const AgriSentinelApp());

class AgriSentinelApp extends StatelessWidget {
  const AgriSentinelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DemoState(),
      child: MaterialApp(
        title: 'AgriSentinel',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: kGreen)),
        home: HomeShell(key: shellKey),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _index = 0;
  static const _titles = ['Home', 'Scan', 'Map', 'Alerts', 'Expert'];

  void goToTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(onScan: (fieldId) {
        context.read<DemoState>().selectField(fieldId);
        goToTab(1);
      }),
      const ScanScreen(),
      const Center(child: Text('Map coming soon')),
      const Center(child: Text('Alerts coming soon')),
      const Center(child: Text('Expert coming soon')),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('AgriSentinel  ·  ${_titles[_index]}'),
        actions: [
          IconButton(
            tooltip: 'Reset demo',
            icon: const Icon(Icons.restart_alt),
            onPressed: () => context.read<DemoState>().reset(),
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: goToTab,
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
