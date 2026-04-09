class ItemDetailModel {
  final String itemId;
  final String title;
  final String? description;
  final String categoryId;
  final String categoryName;
  final String collectionId;
  final String collectionName;
  final DateTime createdAt;

  const ItemDetailModel({
    required this.itemId,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.collectionId,
    required this.collectionName,
    required this.createdAt,
  });

  factory ItemDetailModel.fromMap(Map<String, dynamic> map) {
    return ItemDetailModel(
      itemId: map['item_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      categoryId: map['category_id'] as String,
      categoryName: map['category_name'] as String,
      collectionId: map['collection_id'] as String,
      collectionName: map['collection_name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
