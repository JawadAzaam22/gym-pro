/// مرجع موحّد لتحويل رقم اليوم (0-6) إلى اسم معروض.
/// 0 = السبت ... 6 = الجمعة (متوافق مع منطق access_periods.day_of_week الجديد).
/// ملاحظة: شاشة access_periods القديمة كانت تستخدم 1-7؛ القيم الجديدة 0-6.
/// ندعم كليهما عند العرض لتفادي كسر البيانات القديمة.
class DayOfWeekHelper {
  static const List<String> _names = [
    'السبت', // 0
    'الأحد', // 1
    'الاثنين', // 2
    'الثلاثاء', // 3
    'الأربعاء', // 4
    'الخميس', // 5
    'الجمعة', // 6
  ];

  static String name(int dayOfWeek) {
    if (dayOfWeek >= 0 && dayOfWeek <= 6) return _names[dayOfWeek];
    // توافق خلفي: 1-7 (1=الأحد سابقًا) -> نعيد تطبيعه
    if (dayOfWeek >= 1 && dayOfWeek <= 7) return _names[dayOfWeek % 7];
    return 'يوم $dayOfWeek';
  }

  static List<MapEntry<int, String>> get entries =>
      List.generate(7, (i) => MapEntry(i, _names[i]));
}
