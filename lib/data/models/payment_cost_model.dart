import "../../core/constants/enums.dart";
import "../../domain/entities/payment_cost.dart";

class PaymentCostModel extends PaymentCost {
  const PaymentCostModel({required super.id, super.userId, required super.type, required super.category, required super.amount, required super.paymentDate, super.description, required super.recordedBy, required super.createdAt});

  factory PaymentCostModel.fromJson(Map<String, dynamic> json) => PaymentCostModel(
        id: json['id'] as int,
        userId: json['user_id'] as String?,
        type: json['type'] == 'expense' ? PaymentType.expense : PaymentType.income,
        category: PaymentCategoryX.fromString(json['category'] as String),
        amount: (json['amount'] as num).toDouble(),
        paymentDate: DateTime.parse(json['payment_date'] as String),
        description: json['description'] as String?,
        recordedBy: json['recorded_by'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {'id': id, 'user_id': userId, 'type': type.name, 'category': category.toDbString(), 'amount': amount, 'payment_date': paymentDate.toIso8601String().split('T').first, 'description': description, 'recorded_by': recordedBy, 'created_at': createdAt.toIso8601String()};
  Map<String, dynamic> toInsertJson() {
    final j = toJson();
    j.remove('id');
    j.remove('created_at');
    return j;
  }

  factory PaymentCostModel.fromEntity(PaymentCost e) => PaymentCostModel(id: e.id, userId: e.userId, type: e.type, category: e.category, amount: e.amount, paymentDate: e.paymentDate, description: e.description, recordedBy: e.recordedBy, createdAt: e.createdAt);
  PaymentCost toEntity() => PaymentCost(id: id, userId: userId, type: type, category: category, amount: amount, paymentDate: paymentDate, description: description, recordedBy: recordedBy, createdAt: createdAt);
}
