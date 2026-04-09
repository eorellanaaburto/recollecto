class CategoryModel {
  final String id;
  final String name;
  final String normalizedName;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'normalized_name': normalizedName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      normalizedName: map['normalized_name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
