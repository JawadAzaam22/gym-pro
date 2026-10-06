import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/role_guard.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final AppEntry entry;
  const LoginScreen({super.key, this.entry = AppEntry.mobile});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  late final TextEditingController _pass;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController();
    _pass = TextEditingController();
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.entry) {
      case AppEntry.admin:
        return 'بوابة الإدارة';
      case AppEntry.reception:
        return 'بوابة الاستقبال';
      case AppEntry.mobile:
        return 'بوابة المدرب / المتدرب';
    }
  }

  String get _subtitle {
    switch (widget.entry) {
      case AppEntry.admin:
        return 'Admin فقط - للتحكم الكامل';
      case AppEntry.reception:
        return 'Reception فقط - للعمليات اليومية';
      case AppEntry.mobile:
        return 'Trainer / Trainee - للتطبيق المحمول';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset('assets/images/hall_a.png', height: 140, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 140, color: AppColors.surfaceCard, child: const Icon(Icons.fitness_center, color: AppColors.primary, size: 40))),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: AppColors.primaryGlow, blurRadius: 24, offset: Offset(0, 8))]),
                  child: const Icon(Icons.fitness_center, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 12),
                Text('ATHLETIC PULSE', style: Theme.of(context).textTheme.headlineMedium?.copyWith(letterSpacing: 2, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(_title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                Text(_subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border)), child: Text('مخصص لـ ${RoleGuard.allowedRolesLabel(widget.entry)}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11))),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تسجيل الدخول', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text('مرحباً بعودتك — أدخل بياناتك للمتابعة', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 20),
                        AppTextField(label: 'البريد الإلكتروني', hint: 'name@gym.com', controller: _email, keyboardType: TextInputType.emailAddress, prefixIcon: Icons.mail_outline, validator: Validators.email),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'كلمة المرور',
                          hint: '••••••••',
                          controller: _pass,
                          obscure: _obscure,
                          prefixIcon: Icons.lock_outline,
                          suffix: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 18), onPressed: () => setState(() => _obscure = !_obscure)),
                          validator: Validators.password,
                        ),
                        const SizedBox(height: 8),
                        Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: () {}, child: const Text('نسيت كلمة المرور؟', style: TextStyle(color: AppColors.primary, fontSize: 12)))),
                        const SizedBox(height: 8),
                        if (auth.hasError)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.error.withOpacity(0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error.withOpacity(0.25))),
                            child: Row(children: [const Icon(Icons.error_outline, color: AppColors.error, size: 16), const SizedBox(width: 8), Expanded(child: Text(auth.error is String ? auth.error as String : 'بيانات الدخول غير صحيحة', style: const TextStyle(color: AppColors.error, fontSize: 12)))]),
                          ),
                        if (auth.hasError) const SizedBox(height: 12),
                        AppButton(label: 'دخول المنصة', icon: Icons.login, isLoading: auth.isLoading, onPressed: _handleLogin),
                        const SizedBox(height: 12),
                        Center(child: Text('4 أدوار • Admin / Reception / Trainer / Trainee', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('© 2026 Athletic Pulse • ${RoleGuard.allowedRolesLabel(widget.entry)}', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 10)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authControllerProvider.notifier).login(_email.text.trim(), _pass.text, entry: widget.entry);
    if (!mounted) return;
    if (!ok) {
      final err = ref.read(authControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err is String ? err : 'بيانات الدخول غير صحيحة'), backgroundColor: AppColors.error, duration: const Duration(seconds: 4)));
    }
  }
}
