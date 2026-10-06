import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/diet.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/user_search_field.dart';
import '../../../admin/users/controllers/users_controller.dart';
import '../../../../core/constants/enums.dart';
import '../controllers/diet_builder_controller.dart';

class CreateDietScreen extends ConsumerStatefulWidget {
  final dynamic diet;
  final String? initialTraineeId;
  const CreateDietScreen({super.key, this.diet, this.initialTraineeId});
  @override
  ConsumerState<CreateDietScreen> createState() => _CreateDietScreenState();
}

class _CreateDietScreenState extends ConsumerState<CreateDietScreen> {
  final _name = TextEditingController();
  final _trainee = TextEditingController();
  final _desc = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.diet is Diet) {
      final d = widget.diet as Diet;
      _name.text = d.name;
      _trainee.text = d.traineeId;
      _desc.text = d.description ?? '';
    } else if (widget.initialTraineeId != null &&
        widget.initialTraineeId!.isNotEmpty) {
      _trainee.text = widget.initialTraineeId!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.diet is Diet;
    final hasPreselectedTrainee = !isEdit &&
        widget.initialTraineeId != null &&
        widget.initialTraineeId!.isNotEmpty;
    final usersAsync = ref.watch(usersControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(isEdit ? 'تعديل الخطة' : 'خطة غذائية جديدة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AppCard(
          child: Column(
            children: [
              AppTextField(
                  label: 'اسم الخطة',
                  hint: 'تنشيف - 2200 سعرة',
                  controller: _name,
                  prefixIcon: Icons.restaurant),
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
                label: isEdit ? 'حفظ التعديلات' : 'حفظ الخطة',
                isLoading: _loading,
                onPressed: () async {
                  setState(() => _loading = true);
                  bool ok;
                  if (isEdit) {
                    final updated = (widget.diet as Diet).copyWith(
                        name: _name.text.trim(),
                        traineeId: _trainee.text.trim(),
                        description: _desc.text.isEmpty ? null : _desc.text);
                    ok = await ref
                        .read(dietBuilderProvider.notifier)
                        .editDiet(updated);
                  } else {
                    ok = await ref.read(dietBuilderProvider.notifier).create(
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
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
