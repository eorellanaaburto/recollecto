class PotentialDuplicateModel {
  final String itemId;
  final String title;
  final String normalizedTitle;
  final String categoryName;
  final String collectionName;
  final String? primaryPhotoPath;
  final int matchingHashCount;

  const PotentialDuplicateModel({
    required this.itemId,
    required this.title,
    required this.normalizedTitle,
    required this.categoryName,
    required this.collectionName,
    required this.primaryPhotoPath,
    required this.matchingHashCount,
  });

  bool matchesName(String normalizedInput) {
    return normalizedTitle == normalizedInput;
  }

  bool get matchesImage => matchingHashCount > 0;

  factory PotentialDuplicateModel.fromMap(Map<String, dynamic> map) {
    return PotentialDuplicateModel(
      itemId: map['item_id'] as String,
      title: map['title'] as String,
      normalizedTitle: map['normalized_title'] as String,
      categoryName: map['category_name'] as String,
      collectionName: map['collection_name'] as String,
      primaryPhotoPath: map['primary_photo_path'] as String?,
      matchingHashCount: (map['matching_hash_count'] as int?) ?? 0,
    );
  }
}
