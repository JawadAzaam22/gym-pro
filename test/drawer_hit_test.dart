import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_pro/presentation/reception/checkin/screens/checkin_screen.dart';

void main() {
  testWidgets('reception checkin drawer hover/open/close does not crash hit test', (tester) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            key: scaffoldKey,
            drawer: const Drawer(),
            body: const CheckinScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // hover across the screen (mouse move triggers MouseTracker hit tests)
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.moveTo(const Offset(10, 300));
    await tester.pump();
    await gesture.moveTo(const Offset(400, 300));
    await tester.pump();
    await gesture.moveTo(const Offset(790, 500));
    await tester.pumpAndSettle();

    // open drawer via scaffold
    final scaffoldState = scaffoldKey.currentState!;
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();
    await gesture.moveTo(const Offset(200, 300));
    await tester.pumpAndSettle();

    // close drawer
    Navigator.of(scaffoldState.context).pop();
    await tester.pumpAndSettle();
    await gesture.moveTo(const Offset(400, 300));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
