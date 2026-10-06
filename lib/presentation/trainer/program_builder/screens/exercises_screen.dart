import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../../data/models/program_exercise_model.dart';
import '../../../../data/providers.dart';
import '../controllers/program_builder_controller.dart';
import '../../../shared/widgets/app_toast.dart';

class ExercisesScreen extends ConsumerStatefulWidget {
  final int dayId;
  const ExercisesScreen({super.key, required this.dayId});
  @override
  ConsumerState<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends ConsumerState<ExercisesScreen> {
  int _refresh = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('تمارين يوم #${widget.dayId}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addExercise(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('تمرين جديد', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder(
        key: ValueKey(_refresh),
        future: ref.read(programDatasourceProvider).getExercises(widget.dayId),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          if (snap.hasError) return Center(child: Text('خطأ: ${snap.error}', style: const TextStyle(color: AppColors.error)));
          final exs = snap.data!;
          if (exs.isEmpty) return const Center(child: Text('لا توجد تمارين — أضف الأول', style: TextStyle(color: AppColors.textMuted)));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: exs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final e = exs[i];
              return AppCard(
                child: Row(children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.fitness_center, size: 16, color: AppColors.primary)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.exerciseName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)), Text('${e.sets ?? '-'} مجموعات × ${e.reps ?? '-'}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)), if (e.notes != null) Text(e.notes!, style: const TextStyle(color: AppColors.textMuted, fontSize: 10))])),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                    onPressed: () => _editExercise(context, e),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    onPressed: () async {
                      try {
                        await ref.read(programDatasourceProvider).deleteExercise(e.id);
                        ref.invalidate(programExercisesProvider(widget.dayId));
                        if (mounted) setState(() => _refresh++);
                      } catch (err) {
                        if (mounted) AppToast.error(context, 'فشل الحذف: $err');
                      }
                    },
                  ),
                ]),
              );
            },
          );
        },
      ),
    );
  }

  void _addExercise(BuildContext context) {
    final nameCtrl = TextEditingController();
    final setsCtrl = TextEditingController();
    final repsCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('تمرين جديد', style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم التمرين')),
              TextField(controller: setsCtrl, decoration: const InputDecoration(labelText: 'المجموعات (اختياري)'), keyboardType: TextInputType.number),
              TextField(controller: repsCtrl, decoration: const InputDecoration(labelText: 'التكرارات (اختياري)')),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ref.read(programDatasourceProvider).addExercise(ProgramExerciseModel(
                      id: 0,
                      dayId: widget.dayId,
                      exerciseName: nameCtrl.text.trim(),
                      sets: int.tryParse(setsCtrl.text.trim()),
                      reps: repsCtrl.text.trim().isEmpty ? null : repsCtrl.text.trim(),
                      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                      orderIndex: 0,
                    ));
                ref.invalidate(programExercisesProvider(widget.dayId));
                if (mounted) {
                  setState(() => _refresh++);
                  AppToast.success(context, 'تمت الإضافة');
                }
              } catch (e) {
                if (mounted) AppToast.error(context, 'فشل: $e');
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _editExercise(BuildContext context, ProgramExerciseModel e) {
    final nameCtrl = TextEditingController(text: e.exerciseName);
    final setsCtrl = TextEditingController(text: e.sets?.toString() ?? '');
    final repsCtrl = TextEditingController(text: e.reps ?? '');
    final notesCtrl = TextEditingController(text: e.notes ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('تعديل التمرين', style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم التمرين')),
              TextField(controller: setsCtrl, decoration: const InputDecoration(labelText: 'المجموعات (اختياري)'), keyboardType: TextInputType.number),
              TextField(controller: repsCtrl, decoration: const InputDecoration(labelText: 'التكرارات (اختياري)')),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ref.read(programDatasourceProvider).updateExercise(ProgramExerciseModel(
                      id: e.id,
                      dayId: e.dayId,
                      exerciseName: nameCtrl.text.trim(),
                      sets: int.tryParse(setsCtrl.text.trim()),
                      reps: repsCtrl.text.trim().isEmpty ? null : repsCtrl.text.trim(),
                      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                      orderIndex: e.orderIndex,
                    ));
                ref.invalidate(programExercisesProvider(widget.dayId));
                if (mounted) {
                  setState(() => _refresh++);
                  AppToast.success(context, 'تم التحديث');
                }
              } catch (err) {
                if (mounted) AppToast.error(context, 'فشل: $err');
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
