import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum ReceptionSection {
  dashboard('لوحة التحكم', 'dashboard', 'لوحة الاستقبال'),
  checkin('تسجيل الحضور', 'checkin', 'الحضور'),
  qrScan('مسح QR', 'qr', 'مسح'),
  memberships('العضويات', 'memberships', 'عضويات'),
  bookings('الحجوزات الجماعية', 'bookings/group', 'جماعية'),
  privateBookings('الجلسات الخاصة', 'bookings/private', 'خاصة'),
  assignment('تعيين مدرب', 'trainer-assignment', 'المدرب'),
  payments('المدفوعات', 'payments/record', 'المدفوعات'),
  schedule('الجدول اليومي', 'schedule', 'الجدول'),
  newTrainee('متدرب جديد', 'trainees/new', 'متدرب');

  const ReceptionSection(this.label, this.routeSegment, this.shortLabel);
  final String label;
  final String routeSegment;
  final String shortLabel;
}

final receptionNavProvider = StateProvider<ReceptionSection>((ref) => ReceptionSection.dashboard);

ReceptionSection sectionFromLocation(String location) {
  if (location.contains('/checkin/qr')) return ReceptionSection.qrScan;
  if (location.contains('/checkin')) return ReceptionSection.checkin;
  if (location.contains('/memberships')) return ReceptionSection.memberships;
  if (location.contains('/bookings/private')) return ReceptionSection.privateBookings;
  if (location.contains('/bookings')) return ReceptionSection.bookings;
  if (location.contains('/trainer-assignment')) return ReceptionSection.assignment;
  if (location.contains('/payments')) return ReceptionSection.payments;
  if (location.contains('/trainees/new')) return ReceptionSection.newTrainee;
  if (location.contains('/schedule')) return ReceptionSection.schedule;
  if (location.contains('/dashboard')) return ReceptionSection.dashboard;
  return ReceptionSection.dashboard;
}

void navigateToSection(BuildContext context, ReceptionSection section) {
  final path = '/reception/${section.routeSegment}';
  context.go(path);
}
