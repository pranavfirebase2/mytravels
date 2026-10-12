class Agency {
  final String id;
  final String name;
  final double comparisonDeduction;
  final bool isStarred;
  final String whatsappNumber;

  Agency({
    required this.id,
    required this.name,
    required this.comparisonDeduction,
    required this.isStarred,
    this.whatsappNumber = '',
  });

  Agency copyWith({
    String? id,
    String? name,
    double? comparisonDeduction,
    bool? isStarred,
    String? whatsappNumber,
  }) {
    return Agency(
      id: id ?? this.id,
      name: name ?? this.name,
      comparisonDeduction: comparisonDeduction ?? this.comparisonDeduction,
      isStarred: isStarred ?? this.isStarred,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
    );
  }
}
