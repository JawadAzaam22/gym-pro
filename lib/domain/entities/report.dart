import "package:equatable/equatable.dart";

class Report extends Equatable {
  final int id;
  final String type;
  final String title;
  final String? description;
  final String? generatedBy;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  const Report({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.generatedBy,
    required this.createdAt,
    this.data,
  });

  @override
  List<Object?> get props =>
      [id, type, title, description, generatedBy, createdAt, data];
}
