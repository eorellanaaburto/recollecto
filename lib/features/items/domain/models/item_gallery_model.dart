class ItemGalleryModel {
  final String itemId;
  final String title;
  final String? description;
  final String categoryId;
  final String categoryName;
  final String collectionId;
  final String collectionName;
  final String? primaryPhotoPath;
  final int photoCount;

  const ItemGalleryModel({
    required this.itemId,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.collectionId,
    required this.collectionName,
    required this.primaryPhotoPath,
    required this.photoCount,
  });

  factory ItemGalleryModel.fromMap(Map<String, dynamic> map) {
    final rawPhotoCount = map['photo_count'];
    final photoCount =
        rawPhotoCount is int ? rawPhotoCount : (rawPhotoCount as num).toInt();

    return ItemGalleryModel(
      itemId: map['item_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      categoryId: map['category_id'] as String,
      categoryName: map['category_name'] as String,
      collectionId: map['collection_id'] as String,
      collectionName: map['collection_name'] as String,
      primaryPhotoPath: map['primary_photo_path'] as String?,
      photoCount: photoCount,
    );
  }
}
