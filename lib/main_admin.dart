import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/bootstrap/bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'presentation/admin/router/admin_router.dart';

void main() async {
  await bootstrap();
  runApp(const ProviderScope(child: AdminApp()));
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gym Pro - Admin',
      theme: AppTheme.darkTheme,
      routerConfig: adminRouter,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    );
  }
}
