import "package:equatable/equatable.dart";
import "../../core/constants/enums.dart";

class PaymentCost extends Equatable {
  final int id;
  final String? userId;
  final PaymentType type;
  final PaymentCategory category;
  final double amount;
  final DateTime paymentDate;
  final String? description;
  final String? recordedBy;
  final DateTime createdAt;

  const PaymentCost({
    required this.id,
    this.userId,
    required this.type,
    required this.category,
    required this.amount,
    required this.paymentDate,
    this.description,
    this.recordedBy,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, userId, type, category, amount, paymentDate, description, recordedBy, createdAt];
}
