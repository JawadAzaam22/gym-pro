import 'package:flutter_test/flutter_test.dart';
import 'package:gym_pro/core/constants/enums.dart';
import 'package:gym_pro/data/models/membership_model.dart';

void main() {
  Map<String, dynamic> jsonWith({required String status, required String endDate}) => {
        'id': 1,
        'trainee_id': 'trainee-1',
        'start_date': '2026-01-01',
        'end_date': endDate,
        'status': status,
        'recorded_by': 'reception-1',
        'created_at': '2026-01-01T00:00:00+00:00',
      };

  String dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  final now = DateTime.now();
  final yesterday = dateOnly(now.subtract(const Duration(days: 1)));
  final tomorrow = dateOnly(now.add(const Duration(days: 1)));

  group('MembershipModel.fromJson - تطبيع حالة العضوية', () {
    test('active وتاريخ انتهاء مستقبلي تبقى active', () {
      final m = MembershipModel.fromJson(jsonWith(status: 'active', endDate: tomorrow));
      expect(m.status, MembershipStatus.active);
    });

    test('active وتاريخ انتهاء منتهٍ تتحول إلى expired', () {
      final m = MembershipModel.fromJson(jsonWith(status: 'active', endDate: yesterday));
      expect(m.status, MembershipStatus.expired);
      expect(m.isExpired, isTrue);
      expect(m.isActive, isFalse);
    });

    test('expired صريحة تبقى expired', () {
      final m = MembershipModel.fromJson(jsonWith(status: 'expired', endDate: tomorrow));
      expect(m.status, MembershipStatus.expired);
    });

    test('suspended منتهية التاريخ تبقى suspended (لا تتحول إلى expired)', () {
      final m = MembershipModel.fromJson(jsonWith(status: 'suspended', endDate: yesterday));
      expect(m.status, MembershipStatus.suspended);
    });

    test('active تنتهي اليوم تكون نشطة (لم يمر يوم الانتهاء بعد)', () {
      final m = MembershipModel.fromJson(jsonWith(status: 'active', endDate: dateOnly(now)));
      expect(m.status, MembershipStatus.active);
    });
  });
}
