class LocalBackupFileModel {
  final String path;
  final String name;
  final DateTime modifiedAt;
  final int size;

  const LocalBackupFileModel({
    required this.path,
    required this.name,
    required this.modifiedAt,
    required this.size,
  });
}
