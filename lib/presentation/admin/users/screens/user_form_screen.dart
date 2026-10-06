import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/utils/validators.dart';
import '../../../../domain/entities/user.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_card.dart';
import '../controllers/users_controller.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/app_toast.dart';

/// شاشة إنشاء/تعديل عضو.
/// - `user` (من extra): تحسين اختياري لتفادي التحميل عند التنقل الداخلي.
/// - `userId`: عند غياب extra (تحديث صفحة F5 أو رابط مباشر) يُجلب المستخدم
///   من الخادم عبر userDetailProvider مع حالات loading / error / retry.
class UserFormScreen extends ConsumerWidget {
  final String? userId;
  final User? user; // null = create (عند غياب userId أيضًا)
  /// عند التمرير من سياق الاستقبال يُقفل الدور على `trainee` ويُخفى حقل
  /// اختيار الدور بالكامل — لا يجوز لموظف الاستقبال إنشاء أدمن/استقبال/مدرب.
  final UserRole? lockedRole;
  const UserFormScreen({super.key, this.userId, this.user, this.lockedRole});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = user;
    if (initial != null) return _UserFormBody(user: initial);
    final id = userId;
    if (id == null) return _UserFormBody(user: null, lockedRole: lockedRole);
    final detailAsync = ref.watch(userDetailProvider(id));
    return detailAsync.when(
      loading: () => const Scaffold(backgroundColor: AppColors.background, body: LoadingIndicator(message: 'جاري تحميل بيانات العضو...')),
      error: (e, _) => Scaffold(backgroundColor: AppColors.background, appBar: AppBar(title: const Text('تعديل عضو')), body: AsyncErrorView(error: e, onRetry: () => ref.invalidate(userDetailProvider(id)))),
      data: (loaded) {
        if (loaded == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('تعديل عضو')),
            body: AsyncErrorView(error: 'المستخدم غير موجود', onRetry: () => ref.invalidate(userDetailProvider(id))),
          );
        }
        return _UserFormBody(user: loaded);
      },
    );
  }
}

class _UserFormBody extends ConsumerStatefulWidget {
  final User? user; // null = create, not null = edit
  final UserRole? lockedRole; // يُستخدم في الإنشاء فقط (سياق الاستقبال)
  const _UserFormBody({this.user, this.lockedRole});
  @override
  ConsumerState<_UserFormBody> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<_UserFormBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _pass;
  late UserRole _role;
  late Gender _gender;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user?.name ?? '');
    _phone = TextEditingController(text: widget.user?.phone ?? '');
    _email = TextEditingController(text: widget.user?.email ?? '');
    _pass = TextEditingController();
    _role = widget.lockedRole ?? widget.user?.role ?? UserRole.trainee;
    _gender = widget.user?.gender ?? Gender.male;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  bool get isEdit => widget.user != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: Text(isEdit
              ? 'تعديل عضو'
              : widget.lockedRole != null
                  ? 'إضافة متدرب جديد'
                  : 'إضافة عضو جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AppCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(isEdit ? Icons.edit : Icons.person_add, color: AppColors.primary, size: 18)), const SizedBox(width: 10), Text(isEdit ? 'تعديل بيانات ${widget.user!.name}' : 'بيانات العضو الجديد', style: Theme.of(context).textTheme.titleMedium)]),
                const SizedBox(height: 16),
                AppTextField(label: 'الاسم الكامل', controller: _name, prefixIcon: Icons.person_outline, validator: (v) => Validators.required(v, 'الاسم')),
                const SizedBox(height: 12),
                AppTextField(label: 'رقم الهاتف', controller: _phone, prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone, validator: Validators.phone),
                const SizedBox(height: 12),
                AppTextField(label: 'البريد الإلكتروني', controller: _email, prefixIcon: Icons.mail_outline, keyboardType: TextInputType.emailAddress, validator: Validators.email),
                const SizedBox(height: 12),
                if (!isEdit) AppTextField(label: 'كلمة المرور', controller: _pass, prefixIcon: Icons.lock_outline, obscure: true, validator: Validators.password),
                if (isEdit) const SizedBox(height: 4),
                if (isEdit) const Text('اترك كلمة المرور فارغة لعدم التغيير', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                const SizedBox(height: 12),
                if (widget.lockedRole != null)
                  const InputDecorator(
                      decoration: InputDecoration(
                          labelText: 'الدور', prefixIcon: Icon(Icons.badge_outlined)),
                      child: Row(children: [
                        Text('متدرب',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        Spacer(),
                        Icon(Icons.lock_outline, size: 16),
                      ])),
                if (widget.lockedRole != null) const SizedBox(height: 12),
                Row(children: [
                  if (widget.lockedRole == null)
                    Expanded(child: DropdownButtonFormField<UserRole>(value: _role, decoration: const InputDecoration(labelText: 'الدور'), items: UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.name))).toList(), onChanged: (v) => setState(() => _role = v!))),
                  if (widget.lockedRole == null) const SizedBox(width: 12),
                  Expanded(child: DropdownButtonFormField<Gender>(value: _gender, decoration: const InputDecoration(labelText: 'الجنس'), items: const [DropdownMenuItem(value: Gender.male, child: Text('ذكر')), DropdownMenuItem(value: Gender.female, child: Text('أنثى'))], onChanged: (v) => setState(() => _gender = v!))),
                ]),
                const SizedBox(height: 20),
                AppButton(label: isEdit ? 'حفظ التعديلات' : 'إنشاء العضو', icon: isEdit ? Icons.save_outlined : Icons.person_add, isLoading: _isLoading, onPressed: _save),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء'))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    bool ok;
    if (isEdit) {
      final updated = User(id: widget.user!.id, name: _name.text.trim(), phone: _phone.text.trim(), email: _email.text.trim(), role: _role, gender: _gender, isActive: widget.user!.isActive, createdAt: widget.user!.createdAt);
      ok = await ref.read(usersControllerProvider.notifier).updateUser(updated);
    } else {
      final user = User(id: '', name: _name.text.trim(), phone: _phone.text.trim(), email: _email.text.trim(), role: _role, gender: _gender, isActive: true, createdAt: DateTime.now());
      ok = await ref.read(usersControllerProvider.notifier).createUser(user, _pass.text);
    }
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (ok) {
      AppToast.success(context, isEdit ? 'تم التحديث بنجاح' : 'تم الإنشاء بنجاح');
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('تعذّر حفظ البيانات، حاول مجددًا'), backgroundColor: AppColors.error));
    }
  }
}
