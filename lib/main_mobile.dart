import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_pro/presentation/mobile/router/mobile_router.dart';
import 'core/bootstrap/bootstrap.dart';
import 'core/theme/app_theme.dart';


void main() async {
  await bootstrap();
  runApp(const ProviderScope(child: MobileApp()));
}

class MobileApp extends ConsumerWidget {
  const MobileApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Gym Pro Mobile',
      theme: AppTheme.darkTheme,
      routerConfig: mobileRouter,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    );
  }
}
