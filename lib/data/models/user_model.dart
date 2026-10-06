import "../../core/constants/enums.dart";
import "../../domain/entities/user.dart";

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.email,
    required super.role,
    required super.gender,
    required super.isActive,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      role: UserRoleX.fromString(json['role'] as String),
      gender: GenderX.fromString(json['gender'] as String),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'role': role.name,
        'gender': gender.name,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };

  // ملاحظة: إنشاء المستخدمين يتم حصرًا عبر Edge Function (create-user)
  // التي تنشئ حساب Auth حقيقي وصف profiles مطابق — لا تخزين محلي لأي كلمة مرور.

  factory UserModel.fromEntity(User e) => UserModel(
        id: e.id,
        name: e.name,
        phone: e.phone,
        email: e.email,
        role: e.role,
        gender: e.gender,
        isActive: e.isActive,
        createdAt: e.createdAt,
      );

  User toEntity() => User(
        id: id,
        name: name,
        phone: phone,
        email: email,
        role: role,
        gender: gender,
        isActive: isActive,
        createdAt: createdAt,
      );

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    UserRole? role,
    Gender? gender,
    bool? isActive,
    DateTime? createdAt,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        role: role ?? this.role,
        gender: gender ?? this.gender,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
      );
}
