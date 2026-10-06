import "package:equatable/equatable.dart";
import "../../core/constants/enums.dart";

class User extends Equatable {
  /// مطابق لمعرف حساب الدخول (uuid كنص).
  final String id;
  final String name;
  final String phone;
  final String email;
  final UserRole role;
  final Gender gender;
  final bool isActive;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    required this.gender,
    required this.isActive,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, phone, email, role, gender, isActive, createdAt];
}
