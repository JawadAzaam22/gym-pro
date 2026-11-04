import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../controllers/qr_controller.dart';

class MyQrScreen extends ConsumerWidget {
  const MyQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qrState = ref.watch(traineeQrProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('الكود الخاص بي')),
      body: Center(
        child: AppCard(
          child: qrState.when(
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text('تعذر إنشاء الكود: $error'),
            data: (qrData) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 180,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'الكود صالح لمدة 90 ثانية',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Text(
                  'اعرض الكود عند الدخول',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
