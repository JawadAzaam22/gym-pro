import "package:flutter/material.dart";
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile; final Widget tablet; final Widget desktop;
  const ResponsiveLayout({super.key, required this.mobile, required this.tablet, required this.desktop});
  @override Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 600) return mobile;
    if (w < 1100) return tablet;
    return desktop;
  }
}
