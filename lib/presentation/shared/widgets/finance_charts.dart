import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'app_card.dart';

/// رسم دائري: الإيرادات مقابل المصروفات.
class IncomeExpensePie extends StatelessWidget {
  final double income;
  final double expense;
  const IncomeExpensePie({super.key, required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final total = income + expense;
    if (total <= 0) {
      return const AppCard(child: Center(child: Text('لا توجد بيانات مالية بعد', style: TextStyle(color: AppColors.textMuted))));
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الإيرادات مقابل المصروفات', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 40,
                sectionsSpace: 2,
                sections: [
                  PieChartSectionData(value: income, color: AppColors.success, title: '${(income / total * 100).toStringAsFixed(0)}%', radius: 55, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                  PieChartSectionData(value: expense, color: AppColors.error, title: '${(expense / total * 100).toStringAsFixed(0)}%', radius: 55, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _legend(AppColors.success, 'إيرادات \$${income.toStringAsFixed(0)}'),
            const SizedBox(width: 16),
            _legend(AppColors.error, 'مصروفات \$${expense.toStringAsFixed(0)}'),
          ]),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) => Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))), const SizedBox(width: 6), Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))]);
}

/// رسم أعمدة: المبالغ حسب الفئة (by_category من الملخص المالي).
class CategoryBarChart extends StatelessWidget {
  final Map<String, double> byCategory;
  const CategoryBarChart({super.key, required this.byCategory});

  @override
  Widget build(BuildContext context) {
    if (byCategory.isEmpty) {
      return const AppCard(child: Center(child: Text('لا توجد بيانات حسب الفئة', style: TextStyle(color: AppColors.textMuted))));
    }
    final entries = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final shown = entries.take(6).toList();
    final maxY = shown.first.value * 1.2;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('حسب الفئة', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxY <= 0 ? 10 : maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= shown.length) return const SizedBox.shrink();
                        return Padding(padding: const EdgeInsets.only(top: 4), child: Text(shown[i].key, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)));
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(
                  shown.length,
                  (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: shown[i].value, color: AppColors.primary, width: 22, borderRadius: BorderRadius.circular(6))]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// رسم أعمدة: تسجيلات الحضور لآخر 7 أيام.
class WeeklyAttendanceChart extends StatelessWidget {
  final List<int> counts;
  const WeeklyAttendanceChart({super.key, required this.counts});

  static const _days = ['سبت', 'أحد', 'اثنين', 'ثلا', 'أرب', 'خمي', 'جمع'];

  @override
  Widget build(BuildContext context) {
    final data = counts.length == 7 ? counts : List<int>.filled(7, 0);
    // تسميات الأيام السبعة الأخيرة بالترتيب
    final now = DateTime.now();
    final labels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return _days[(d.weekday + 1) % 7];
    });
    final maxY = (data.reduce((a, b) => a > b ? a : b) + 1).toDouble();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('حضور آخر 7 أيام', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i > 6) return const SizedBox.shrink();
                        return Padding(padding: const EdgeInsets.only(top: 4), child: Text(labels[i], style: const TextStyle(color: AppColors.textMuted, fontSize: 10)));
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(
                  7,
                  (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: data[i].toDouble(), color: i == 6 ? AppColors.primary : AppColors.info, width: 20, borderRadius: BorderRadius.circular(6))]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
