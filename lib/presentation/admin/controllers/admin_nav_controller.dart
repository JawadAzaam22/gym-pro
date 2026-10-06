import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum AdminSection {
  dashboard('لوحة التحكم', 'dashboard', 'لوحة التحكم'),
  users('المستخدمين', 'users', 'الأعضاء'),
  halls('القاعات', 'halls', 'القاعات'),
  sessions('الحصص', 'sessions', 'الحصص'),
  finance('التقارير المالية', 'finance', 'المالية'),
  schedule('الجدول الأسبوعي', 'schedule', 'الجدول');

  const AdminSection(this.label, this.routeSegment, this.shortLabel);
  final String label;
  final String routeSegment;
  final String shortLabel;
}

final adminNavProvider =
    StateProvider<AdminSection>((ref) => AdminSection.dashboard);

AdminSection adminSectionFromLocation(String location) {
  if (location.contains('/users')) return AdminSection.users;
  if (location.contains('/halls')) return AdminSection.halls;
  if (location.contains('/sessions')) return AdminSection.sessions;
  if (location.contains('/finance')) return AdminSection.finance;
  if (location.contains('/schedule')) return AdminSection.schedule;
  if (location.contains('/dashboard')) return AdminSection.dashboard;
  return AdminSection.dashboard;
}

void navigateToAdminSection(
    BuildContext context, StatefulNavigationShell shell, AdminSection section) {
  final path = section == AdminSection.finance
      ? '/admin/finance/reports'
      : '/admin/${section.routeSegment}';
  final branchIndex = AdminSection.values.indexOf(section);
  shell.goBranch(
    branchIndex,
    initialLocation: shell.currentIndex == branchIndex,
  );
  context.go(path);
}
