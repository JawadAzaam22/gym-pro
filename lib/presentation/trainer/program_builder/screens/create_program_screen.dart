import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/training_program.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/user_search_field.dart';
import '../../../admin/users/controllers/users_controller.dart';
import '../../../../core/constants/enums.dart';
import '../controllers/program_builder_controller.dart';

class CreateProgramScreen extends ConsumerStatefulWidget {
  final TrainingProgram? program;
  final String? initialTraineeId;
  const CreateProgramScreen({super.key, this.program, this.initialTraineeId});
  @override
  ConsumerState<CreateProgramScreen> createState() =>
      _CreateProgramScreenState();
}

class _CreateProgramScreenState extends ConsumerState<CreateProgramScreen> {
  final _name = TextEditingController();
  final _trainee = TextEditingController();
  final _desc = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.program != null) {
      final p = widget.program!;
      _name.text = p.name;
      _trainee.text = p.traineeId;
      _desc.text = p.description ?? '';
    } else if (widget.initialTraineeId != null &&
        widget.initialTraineeId!.isNotEmpty) {
      _trainee.text = widget.initialTraineeId!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.program != null;
    final hasPreselectedTrainee = !isEdit &&
        widget.initialTraineeId != null &&
        widget.initialTraineeId!.isNotEmpty;
    final usersAsync = ref.watch(usersControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: Text(isEdit ? 'تعديل البرنامج' : 'انشاء برنامج تدريبي')),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: AppCard(
              child: Column(children: [
            AppTextField(
                label: 'اسم البرنامج',
                hint: 'Push/Pull/Legs',
                controller: _name,
                prefixIcon: Icons.assignment),
            const SizedBox(height: 12),
            usersAsync.when(
              loading: () => const InputDecorator(
                  decoration: InputDecoration(labelText: 'المتدرب'),
                  child: Text('جاري تحميل المتدربين...')),
              error: (error, _) => InputDecorator(
                  decoration: const InputDecoration(labelText: 'المتدرب'),
                  child: Text('تعذر تحميل المتدربين: $error')),
              data: (users) {
                final trainees = users
                    .where((user) =>
                        user.role == UserRole.trainee && user.isActive)
                    .toList();
                return UserSearchField(
                  users: trainees,
                  labelText: 'المتدرب',
                  prefixIcon: Icons.person,
                  selectedId: _trainee.text.isNotEmpty
                      ? _trainee.text
                      : null,
                  enabled: !hasPreselectedTrainee,
                  onSelected: (user) =>
                      setState(() => _trainee.text = user?.id ?? ''),
                  validator: (user) =>
                      user == null ? 'اختر المتدرب' : null,
                );
              },
            ),
            const SizedBox(height: 12),
            AppTextField(
                label: 'الوصف',
                controller: _desc,
                prefixIcon: Icons.description),
            const SizedBox(height: 16),
            AppButton(
                label: isEdit ? 'حفظ التعديلات' : 'حفظ البرنامج',
                isLoading: _loading,
                onPressed: () async {
                  setState(() => _loading = true);
                  bool ok;
                  if (isEdit) {
                    final updated = widget.program!.copyWith(
                        name: _name.text.trim(),
                        traineeId: _trainee.text.trim(),
                        description: _desc.text.isEmpty ? null : _desc.text);
                    ok = await ref
                        .read(programBuilderProvider.notifier)
                        .editProgram(updated);
                  } else {
                    ok = await ref.read(programBuilderProvider.notifier).create(
                        _name.text,
                        _trainee.text.trim(),
                        _desc.text.isEmpty ? null : _desc.text);
                  }
                  if (!context.mounted) return;
                  setState(() => _loading = false);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok ? 'تم الحفظ' : 'فشل'),
                      backgroundColor:
                          ok ? AppColors.success : AppColors.error));
                  if (ok && context.mounted) Navigator.pop(context);
                }),
          ]))),
    );
  }
}
