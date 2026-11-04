import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/membership_expired_dialog.dart';
import '../../../../core/errors/failures.dart';
import '../controllers/checkin_controller.dart';
import '../../../shared/widgets/app_toast.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});
  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  String? _last;
  bool _processing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('مسح QR'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/reception/checkin');
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: MobileScanner(
                controller: _controller,
                onDetect: (capture) async {
                  final code = capture.barcodes.first.rawValue;
                  if (code == null || code == _last || _processing) return;
                  setState(() {
                    _last = code;
                    _processing = true;
                  });
                  final raw = code.trim();
                  try {
                    final res = await ref
                        .read(checkinControllerProvider.notifier)
                        .checkinByQr(raw);
                    if (!context.mounted) return;
                    res.fold(
                      (f) {
                        if (f is MembershipExpiredFailure) {
                          showMembershipExpiredDialog(context,
                              endDate: f.endDate);
                        } else {
                          AppToast.error(context, 'فشل: ${f.message}');
                        }
                      },
                      (r) => AppToast.success(
                          context, 'تم تسجيل حضور ${r.traineeName}'),
                    );
                  } catch (e) {
                    if (context.mounted) {
                      AppToast.error(context, 'فشل: $e');
                    }
                  } finally {
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) setState(() => _processing = false);
                    });
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AppCard(
                child: Column(
                  children: [
                    Row(children: [
                      const Icon(Icons.qr_code, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('وجّه الكاميرا نحو كود المتدرب',
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                        _last == null
                            ? 'بانتظار المسح...'
                            : 'تم مسح رمز المتدرب',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                    const Spacer(),
                    if (_processing)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
