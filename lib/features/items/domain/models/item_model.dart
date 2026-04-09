class ItemModel {
  final String id;
  final String categoryId;
  final String collectionId;
  final String title;
  final String normalizedTitle;
  final String? description;
  final DateTime createdAt;

  const ItemModel({
    required this.id,
    required this.categoryId,
    required this.collectionId,
    required this.title,
    required this.normalizedTitle,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'collection_id': collectionId,
      'title': title,
      'normalized_title': normalizedTitle,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      collectionId: map['collection_id'] as String,
      title: map['title'] as String,
      normalizedTitle: map['normalized_title'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
