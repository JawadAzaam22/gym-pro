import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AthleticScaffold extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Widget? drawer;

  const AthleticScaffold({super.key, required this.title, this.actions, required this.body, this.bottomNavigationBar, this.floatingActionButton, this.drawer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: drawer,
      appBar: AppBar(
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        actions: actions,
      ),
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
