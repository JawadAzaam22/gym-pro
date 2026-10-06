import "../../domain/entities/report.dart";

class ReportModel extends Report {
  const ReportModel({
    required super.id,
    required super.type,
    required super.title,
    super.description,
    required super.generatedBy,
    required super.createdAt,
    super.data,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) => ReportModel(
        id: json['id'] as int,
        type: json['type'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        generatedBy: json['generated_by'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        data: json['data'] != null
            ? Map<String, dynamic>.from(json['data'] as Map)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'description': description,
        'generated_by': generatedBy,
        'created_at': createdAt.toIso8601String(),
        'data': data,
      };

  Map<String, dynamic> toInsertJson() {
    final j = toJson();
    j.remove('id');
    j.remove('created_at');
    return j;
  }

  factory ReportModel.fromEntity(Report e) => ReportModel(
        id: e.id,
        type: e.type,
        title: e.title,
        description: e.description,
        generatedBy: e.generatedBy,
        createdAt: e.createdAt,
        data: e.data,
      );

  Report toEntity() => Report(
        id: id,
        type: type,
        title: title,
        description: description,
        generatedBy: generatedBy,
        createdAt: createdAt,
        data: data,
      );
}
