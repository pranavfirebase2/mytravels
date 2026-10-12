import '../../domain/entities/agency.dart';

class AgencyModel extends Agency {
  AgencyModel({
    required super.id,
    required super.name,
    required super.comparisonDeduction,
    required super.isStarred,
    super.whatsappNumber = '',
  });

  factory AgencyModel.fromJson(Map<String, dynamic> json) {
    return AgencyModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      comparisonDeduction: (json['comparisonDeduction'] ?? 0.0).toDouble(),
      isStarred: json['isStarred'] ?? false,
      whatsappNumber: (json['whatsappNumber'] ?? json['whatsapp_number'] ?? json['phone'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'comparisonDeduction': comparisonDeduction,
      'isStarred': isStarred,
      'whatsappNumber': whatsappNumber,
    };
  }

  factory AgencyModel.fromEntity(Agency entity) {
    return AgencyModel(
      id: entity.id,
      name: entity.name,
      comparisonDeduction: entity.comparisonDeduction,
      isStarred: entity.isStarred,
      whatsappNumber: entity.whatsappNumber,
    );
  }
}
