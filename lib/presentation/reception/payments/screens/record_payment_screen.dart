import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/enums.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../controllers/payment_controller.dart';

class RecordPaymentScreen extends ConsumerStatefulWidget {
  const RecordPaymentScreen({super.key});
  @override
  ConsumerState<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends ConsumerState<RecordPaymentScreen> {
  final _amount = TextEditingController();
  final _desc = TextEditingController();
  PaymentType _type = PaymentType.income;
  PaymentCategory _cat = PaymentCategory.membership;
  bool _loading = false;

  List<PaymentCategory> get _availableCategories {
    switch (_type) {
      case PaymentType.income:
        return [PaymentCategory.membership, PaymentCategory.privateSession, PaymentCategory.other];
      case PaymentType.expense:
        return [PaymentCategory.salary, PaymentCategory.purchase, PaymentCategory.maintenance, PaymentCategory.other];
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AppCard(
        child: Column(
          children: [
            TextField(controller: _amount, decoration: const InputDecoration(labelText: 'المبلغ', prefixIcon: Icon(Icons.payments), suffixText: '\$'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            DropdownButtonFormField<PaymentType>(value: _type, decoration: const InputDecoration(labelText: 'النوع'), items: const [DropdownMenuItem(value: PaymentType.income, child: Text('إيراد')), DropdownMenuItem(value: PaymentType.expense, child: Text('مصروف'))], onChanged: (v) {
              if (v != null) {
                setState(() {
                  _type = v;
                  if (!_availableCategories.contains(_cat)) {
                    _cat = _availableCategories.first;
                  }
                });
              }
            }),
            const SizedBox(height: 12),
            DropdownButtonFormField<PaymentCategory>(value: _cat, decoration: const InputDecoration(labelText: 'الفئة'), items: _availableCategories.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(), onChanged: (v) => setState(() => _cat = v!)),
            const SizedBox(height: 12),
            TextField(controller: _desc, decoration: const InputDecoration(labelText: 'الوصف', prefixIcon: Icon(Icons.description_outlined)), maxLines: 2),
            const SizedBox(height: 16),
            AppButton(
              label: 'حفظ الدفعة',
              icon: Icons.save,
              isLoading: _loading,
              onPressed: () async {
                if (_amount.text.isEmpty) return;
                setState(() => _loading = true);
                final ok = await ref.read(paymentControllerProvider.notifier).record(
                      amount: double.parse(_amount.text),
                      type: _type,
                      category: _cat,
                      description: _desc.text.isEmpty ? null : _desc.text,
                    );
                setState(() => _loading = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ok ? 'تم الحفظ' : 'فشل'), backgroundColor: ok ? AppColors.success : AppColors.error),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
