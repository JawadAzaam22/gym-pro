import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/finance_charts.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/stat_card.dart';
import '../controllers/finance_controller.dart';
import '../../../../data/providers.dart';
import '../../../../core/utils/pdf_report_generator.dart';
import '../../../../domain/entities/report.dart';
import '../../../shared/auth/controllers/auth_controller.dart';
import '../../../shared/widgets/app_toast.dart';

enum _DatePreset { week, month, quarter, custom }

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _type = 'financial';
  bool _loading = false;
  _DatePreset _preset = _DatePreset.month;
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();

  void _applyPreset(_DatePreset p) {
    final now = DateTime.now();
    setState(() {
      _preset = p;
      switch (p) {
        case _DatePreset.week:
          _from = now.subtract(const Duration(days: 7));
          _to = now;
          break;
        case _DatePreset.month:
          _from = now.subtract(const Duration(days: 30));
          _to = now;
          break;
        case _DatePreset.quarter:
          _from = now.subtract(const Duration(days: 90));
          _to = now;
          break;
        case _DatePreset.custom:
          _pickCustomRange();
          break;
      }
    });
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (picked != null) {
      setState(() {
        _from = picked.start;
        _to = picked.end;
      });
    }
  }

  String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> _generateReport() async {
    setState(() => _loading = true);
    final repo = ref.read(reportRepositoryProvider);
    final generatedBy =
        ref.read(authControllerProvider).value?.id ?? '';
    final generatedByName =
        ref.read(authControllerProvider).value?.name ?? generatedBy;
    final title =
        'تقرير $_type - ${_fmt(_from)} إلى ${_fmt(_to)}';

    // 1. جلب البيانات أولاً
    Map<String, dynamic> reportData = {
      'from': _fmt(_from),
      'to': _fmt(_to),
      'generated_at': _fmt(DateTime.now()),
      'generated_by_name': generatedByName,
    };

    switch (_type) {
      case 'financial':
        final res = await repo.getFinancialSummary(_from, _to);
        res.fold((l) {}, (r) => reportData.addAll(r));
        break;
      case 'attendance':
        final res = await repo.getAttendanceSummary(_from, _to);
        res.fold((l) {}, (r) => reportData.addAll(r));
        break;
      case 'operational':
        final res = await repo.getOperationalSummary(_from, _to);
        res.fold((l) {}, (r) => reportData.addAll(r));
        break;
    }

    // 2. إنشاء التقرير مع البيانات
    final res = await repo.generateReport(
      _type,
      title,
      null,
      generatedBy,
      reportData,
    );

    if (!mounted) return;
    setState(() => _loading = false);
    res.fold(
      (l) => AppToast.error(context, l.message),
      (report) async {
        ref.invalidate(reportsProvider);
        // عرض PDF مباشرة بالبيانات التي تم حفظها
        final pdfBytes = await PdfReportGenerator.generate(report, reportData);
        await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: report.title,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(reportsProvider);
    final summaryAsync = ref.watch(financeSummaryProvider);
    final attendanceAsync = ref.watch(attendanceSummaryProvider);
    final weeklyAsync = ref.watch(weeklyAttendanceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('التقارير')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('نظرة بيانية (30 يوم)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            summaryAsync.when(
              loading: () => const LoadingIndicator(),
              error: (e, _) => AsyncErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(financeSummaryProvider)),
              data: (s) {
                final income = (s['income'] as num).toDouble();
                final expense = (s['expense'] as num).toDouble();
                final rawCat = s['by_category'];
                final byCat = <String, double>{};
                if (rawCat is Map) {
                  rawCat.forEach(
                      (k, v) => byCat[k.toString()] = (v as num).toDouble());
                }
                return Column(children: [
                  IncomeExpensePie(income: income, expense: expense),
                  const SizedBox(height: 12),
                  CategoryBarChart(byCategory: byCat),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('إجمالي الإيرادات: \$${income.toStringAsFixed(2)}',
                            style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('إجمالي المصروفات: \$${expense.toStringAsFixed(2)}',
                            style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('الصافي: \$${(income - expense).toStringAsFixed(2)}',
                            style: TextStyle(
                                color: (income - expense) >= 0 ? AppColors.success : AppColors.error,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                ]);
              },
            ),
            const SizedBox(height: 12),
            attendanceAsync.when(
              loading: () => const LoadingIndicator(),
              error: (e, _) => AsyncErrorView(
                  error: e,
                  onRetry: () =>
                      ref.invalidate(attendanceSummaryProvider)),
              data: (a) => Row(children: [
                Expanded(
                    child: StatCard(
                        label: 'تسجيلات الحضور',
                        value: '${a['total_checkins']}',
                        delta: '30 يوم',
                        icon: Icons.how_to_reg,
                        deltaColor: AppColors.info)),
                const SizedBox(width: 12),
                Expanded(
                    child: StatCard(
                        label: 'متدربون مميزون',
                        value: '${a['unique_trainees']}',
                        delta: '30 يوم',
                        icon: Icons.group,
                        deltaColor: AppColors.success)),
              ]),
            ),
            const SizedBox(height: 12),
            weeklyAsync.when(
              loading: () => const LoadingIndicator(),
              error: (e, _) => AsyncErrorView(
                  error: e,
                  onRetry: () =>
                      ref.invalidate(weeklyAttendanceProvider)),
              data: (counts) => WeeklyAttendanceChart(counts: counts),
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('إنشاء تقرير',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                      value: _type,
                      decoration:
                          const InputDecoration(labelText: 'نوع التقرير'),
                      items: const [
                        DropdownMenuItem(
                            value: 'financial', child: Text('مالي')),
                        DropdownMenuItem(
                            value: 'attendance', child: Text('حضور')),
                        DropdownMenuItem(
                            value: 'operational', child: Text('تشغيلي')),
                      ],
                      onChanged: (v) => setState(() => _type = v!)),
                  const SizedBox(height: 12),
                  Text('المدة الزمنية',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('أسبوعي'),
                        selected: _preset == _DatePreset.week,
                        onSelected: (_) => _applyPreset(_DatePreset.week),
                      ),
                      ChoiceChip(
                        label: const Text('شهري'),
                        selected: _preset == _DatePreset.month,
                        onSelected: (_) => _applyPreset(_DatePreset.month),
                      ),
                      ChoiceChip(
                        label: const Text('3 أشهر'),
                        selected: _preset == _DatePreset.quarter,
                        onSelected: (_) => _applyPreset(_DatePreset.quarter),
                      ),
                      ChoiceChip(
                        label: const Text('مخصص'),
                        selected: _preset == _DatePreset.custom,
                        onSelected: (_) => _applyPreset(_DatePreset.custom),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'من: ${_fmt(_from)}   إلى: ${_fmt(_to)}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'توليد التقرير',
                    icon: Icons.picture_as_pdf,
                    isLoading: _loading,
                    onPressed: _loading ? null : _generateReport,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('التقارير السابقة',
                    style: Theme.of(context).textTheme.titleMedium),
                reportsAsync.maybeWhen(
                  data: (list) => list.isEmpty
                      ? const SizedBox.shrink()
                      : TextButton.icon(
                          onPressed: _confirmClearAllReports,
                          icon: const Icon(Icons.delete_sweep_outlined,
                              color: AppColors.error, size: 18),
                          label: const Text('مسح كل التقارير',
                              style: TextStyle(color: AppColors.error)),
                        ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            reportsAsync.when(
              loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => AsyncErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(reportsProvider)),
              data: (list) {
                if (list.isEmpty) {
                  return const AppCard(
                      child: Center(
                          child: Text('لا توجد تقارير بعد',
                              style:
                                  TextStyle(color: AppColors.textMuted))));
                }
                return Column(
                  children: list
                      .map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: AppCard(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _openSavedReport(r),
                                onLongPress: () => _showReportOptions(r),
                                child: Row(children: [
                                  Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: const Icon(
                                          Icons.description,
                                          color: AppColors.primary,
                                          size: 18)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(r.title,
                                            style: const TextStyle(
                                                color:
                                                    AppColors.textPrimary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13)),
                                        Text(
                                            '${r.type} • ${r.createdAt.toIso8601String().split('T').first}',
                                            style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 11)),
                                      ])),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'delete') {
                                        _confirmDeleteReport(r);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline,
                                                color: AppColors.error,
                                                size: 18),
                                            SizedBox(width: 8),
                                            Text('حذف',
                                                style: TextStyle(
                                                    color: AppColors.error)),
                                          ],
                                        ),
                                      ),
                                    ],
                                    icon: const Icon(Icons.more_vert,
                                        size: 18, color: AppColors.textMuted),
                                  ),
                                ]),
                              ),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSavedReport(Report report) async {
    final data = report.data;
    if (data == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('لا توجد بيانات محفوظة لهذا التقرير'),
            backgroundColor: AppColors.warning),
      );
      return;
    }
    setState(() => _loading = true);
    final pdfBytes = await PdfReportGenerator.generate(report, data);
    if (!mounted) return;
    setState(() => _loading = false);
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: report.title,
    );
  }

  void _showReportOptions(Report report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
            title: const Text('فتح التقرير'),
            onTap: () {
              Navigator.pop(ctx);
              _openSavedReport(report);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: const Text('حذف التقرير',
                style: TextStyle(color: AppColors.error)),
            onTap: () {
              Navigator.pop(ctx);
              _confirmDeleteReport(report);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteReport(Report report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('حذف التقرير؟',
            style: TextStyle(color: AppColors.error)),
        content: Text(
            'هل أنت متأكد من حذف "${report.title}"؟ لا يمكن التراجع.',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      setState(() => _loading = true);
      final res = await ref.read(reportRepositoryProvider).deleteReport(report.id);
      setState(() => _loading = false);
      if (context.mounted) {
        res.fold(
          (f) => AppToast.error(context, f.message),
          (_) {
            ref.invalidate(reportsProvider);
            AppToast.success(context, 'تم حذف التقرير');
          },
        );
      }
    }
  }

  Future<void> _confirmClearAllReports() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('مسح كل التقارير؟',
            style: TextStyle(color: AppColors.error)),
        content: const Text(
            'سيتم حذف جميع التقارير المحفوظة نهائيًا. لا يمكن التراجع عن هذا الإجراء.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('تراجع')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('مسح الكل'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      setState(() => _loading = true);
      final res = await ref.read(reportRepositoryProvider).deleteAllReports();
      if (!mounted) return;
      setState(() => _loading = false);
      res.fold(
        (f) => AppToast.error(context, f.message),
        (_) {
          ref.invalidate(reportsProvider);
          AppToast.success(context, 'تم مسح كل التقارير');
        },
      );
    }
  }
}
