import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:agrisentinel_demo/screens/map_screen.dart';
import 'package:agrisentinel_demo/state/demo_state.dart';

void main() {
  testWidgets('map shows 20 zones and a scout route summary when toggled', (tester) async {
    // The map is a full-height screen; the 800x600 default surface cuts off the
    // legend and the route summary, so give it a device-sized viewport.
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ChangeNotifierProvider(create: (_) => DemoState(), child: const MaterialApp(home: Scaffold(body: MapScreen()))));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('zone-C')), findsOneWidget);
    expect(find.byKey(const ValueKey('zone-T')), findsOneWidget);
    await tester.tap(find.text('AI Scout route'));
    await tester.pumpAndSettle();
    expect(find.textContaining('of 20 zones'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('zone-C')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Zone C'), findsWidgets);
    expect(find.textContaining('IMMEDIATE'), findsOneWidget);
  });
}
