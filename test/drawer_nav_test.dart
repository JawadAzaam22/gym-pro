import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gym_pro/presentation/reception/router/reception_router.dart';

void main() {
  testWidgets('drawer item navigation while drawer open does not break hit test', (tester) async {
    await Supabase.initialize(url: 'https://example.supabase.co', anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiJ9.test');
    await tester.pumpWidget(ProviderScope(child: MaterialApp.router(routerConfig: receptionRouter)));
    await tester.pumpAndSettle();

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.moveTo(const Offset(400, 300));
    await tester.pumpAndSettle();

    // open drawer
    Scaffold.of(tester.element(find.text('الاستقبال — تسجيل الحضور'))).openDrawer();
    await tester.pumpAndSettle();
    await gesture.moveTo(const Offset(200, 300));
    await tester.pump();

    // tap a drawer item WITHOUT closing drawer first (as the app code does)
    await tester.tap(find.text('اشتراك جديد'));
    await tester.pumpAndSettle();
    await gesture.moveTo(const Offset(400, 300));
    await tester.pumpAndSettle();
    await gesture.moveTo(const Offset(100, 100));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
