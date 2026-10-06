import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/bootstrap/bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'presentation/reception/router/reception_router.dart';

void main() async {
  await bootstrap();
  runApp(const ProviderScope(child: ReceptionApp()));
}

class ReceptionApp extends StatelessWidget {
  const ReceptionApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gym Pro - Reception',
      theme: AppTheme.darkTheme,
      routerConfig: receptionRouter,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
