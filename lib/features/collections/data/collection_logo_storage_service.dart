import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CollectionLogoStorageService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickAndSaveLogo({
    required String collectionId,
  }) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );

    if (picked == null) return null;

    return saveLogoFromFile(
      collectionId: collectionId,
      sourceFile: File(picked.path),
    );
  }

  Future<String> saveLogoFromFile({
    required String collectionId,
    required File sourceFile,
  }) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final logosDir = Directory(
      p.join(documentsDir.path, 'recollecto', 'collection_logos'),
    );

    if (!await logosDir.exists()) {
      await logosDir.create(recursive: true);
    }

    final extension = _safeExtension(sourceFile.path);
    final destination = File(
      p.join(logosDir.path, '$collectionId$extension'),
    );

    await _deleteExistingLogos(collectionId, logosDir);
    final saved = await sourceFile.copy(destination.path);

    return saved.path;
  }

  Future<void> deleteLogoByPath(String? logoPath) async {
    if (logoPath == null || logoPath.trim().isEmpty) return;

    final file = File(logoPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> deleteLogoByCollectionId(String collectionId) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final logosDir = Directory(
      p.join(documentsDir.path, 'recollecto', 'collection_logos'),
    );

    if (!await logosDir.exists()) return;
    await _deleteExistingLogos(collectionId, logosDir);
  }

  Future<void> _deleteExistingLogos(
    String collectionId,
    Directory logosDir,
  ) async {
    final entities = logosDir.listSync();

    for (final entity in entities) {
      if (entity is! File) continue;

      final name = p.basenameWithoutExtension(entity.path);
      if (name == collectionId) {
        await entity.delete();
      }
    }
  }

  String _safeExtension(String path) {
    final ext = p.extension(path).trim().toLowerCase();
    if (ext.isEmpty) return '.jpg';
    return ext;
  }
}
