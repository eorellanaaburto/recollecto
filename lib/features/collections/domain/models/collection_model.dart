class CollectionModel {
  final String id;
  final String categoryId;
  final String name;
  final String normalizedName;
  final DateTime createdAt;

  const CollectionModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.normalizedName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'normalized_name': normalizedName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CollectionModel.fromMap(Map<String, dynamic> map) {
    return CollectionModel(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      name: map['name'] as String,
      normalizedName: map['normalized_name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
