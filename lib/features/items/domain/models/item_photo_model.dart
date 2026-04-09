class ItemPhotoModel {
  final String id;
  final String itemId;
  final String filePath;
  final String fileName;
  final String? imageHash;
  final bool isPrimary;
  final DateTime createdAt;

  const ItemPhotoModel({
    required this.id,
    required this.itemId,
    required this.filePath,
    required this.fileName,
    required this.imageHash,
    required this.isPrimary,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'file_path': filePath,
      'file_name': fileName,
      'image_hash': imageHash,
      'is_primary': isPrimary ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ItemPhotoModel.fromMap(Map<String, dynamic> map) {
    return ItemPhotoModel(
      id: map['id'] as String,
      itemId: map['item_id'] as String,
      filePath: map['file_path'] as String,
      fileName: map['file_name'] as String,
      imageHash: map['image_hash'] as String?,
      isPrimary: (map['is_primary'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
