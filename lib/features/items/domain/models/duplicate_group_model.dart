class DuplicateGroupModel {
  final String displayValue;
  final int duplicateCount;
  final String type;

  const DuplicateGroupModel({
    required this.displayValue,
    required this.duplicateCount,
    required this.type,
  });

  factory DuplicateGroupModel.fromMap(Map<String, dynamic> map) {
    return DuplicateGroupModel(
      displayValue: map['display_value'] as String,
      duplicateCount: map['duplicate_count'] as int,
      type: map['type'] as String,
    );
  }
}
