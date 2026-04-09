class CollectionWithCategoryModel {
  final String id;
  final String categoryId;
  final String name;
  final String normalizedName;
  final String categoryName;
  final String? logoPath;
  final DateTime createdAt;

  const CollectionWithCategoryModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.normalizedName,
    required this.categoryName,
    required this.logoPath,
    required this.createdAt,
  });

  factory CollectionWithCategoryModel.fromMap(Map<String, dynamic> map) {
    return CollectionWithCategoryModel(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      name: map['name'] as String,
      normalizedName: map['normalized_name'] as String,
      categoryName: map['category_name'] as String,
      logoPath: map['logo_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
