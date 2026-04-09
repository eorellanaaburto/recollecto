import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../domain/models/item_photo_model.dart';

class PhotoStorageService {
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  Future<List<XFile>> pickFromGallery() async {
    return _imagePicker.pickMultiImage(
      imageQuality: 90,
    );
  }

  Future<XFile?> pickFromCamera() async {
    return _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
  }

  Future<List<String>> computeHashesFromPickedFiles(
    List<XFile> pickedFiles,
  ) async {
    final hashes = <String>[];

    for (final pickedFile in pickedFiles) {
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      final hash = _computePerceptualHash(bytes);
      hashes.add(hash);
    }

    return hashes;
  }

  Future<String?> computeHashFromFilePath(String path) async {
    final file = File(path);

    if (!await file.exists()) return null;

    final bytes = await file.readAsBytes();
    return _computePerceptualHash(bytes);
  }

  Future<List<ItemPhotoModel>> persistPhotos({
    required String itemId,
    required List<XFile> pickedFiles,
  }) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final itemDir = Directory(
      join(documentsDir.path, 'recollecto', 'items', itemId),
    );

    if (!await itemDir.exists()) {
      await itemDir.create(recursive: true);
    }

    final now = DateTime.now();
    final photos = <ItemPhotoModel>[];

    for (int i = 0; i < pickedFiles.length; i++) {
      final pickedFile = pickedFiles[i];
      final extension = _safeExtension(pickedFile.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i$extension';
      final destinationPath = join(itemDir.path, fileName);

      final sourceFile = File(pickedFile.path);
      final savedFile = await sourceFile.copy(destinationPath);
      final bytes = await savedFile.readAsBytes();

      final imageHash = _computePerceptualHash(bytes);

      photos.add(
        ItemPhotoModel(
          id: _uuid.v4(),
          itemId: itemId,
          filePath: savedFile.path,
          fileName: fileName,
          imageHash: imageHash,
          isPrimary: i == 0,
          createdAt: now,
        ),
      );
    }

    return photos;
  }

  Future<void> deleteStoredPhotos(List<ItemPhotoModel> photos) async {
    for (final photo in photos) {
      final file = File(photo.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> deleteItemDirectory(String itemId) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final itemDir = Directory(
      join(documentsDir.path, 'recollecto', 'items', itemId),
    );

    if (await itemDir.exists()) {
      await itemDir.delete(recursive: true);
    }
  }

  String _safeExtension(String path) {
    final ext = extension(path).trim();
    if (ext.isEmpty) return '.jpg';
    return ext;
  }

  String _computePerceptualHash(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      return sha256.convert(bytes).toString();
    }

    final oriented = img.bakeOrientation(decoded);

    final square = img.copyResizeCropSquare(
      oriented,
      size: 8,
      interpolation: img.Interpolation.average,
    );

    final gray = img.grayscale(square);

    final values = <int>[];
    for (final pixel in gray) {
      final luminance = ((pixel.r + pixel.g + pixel.b) / 3).round();
      values.add(luminance);
    }

    final average =
        values.fold<int>(0, (sum, value) => sum + value) / values.length;

    final bits = StringBuffer();
    for (final value in values) {
      bits.write(value >= average ? '1' : '0');
    }

    return _binaryToHex(bits.toString());
  }

  String _binaryToHex(String bits) {
    final buffer = StringBuffer();

    for (int i = 0; i < bits.length; i += 4) {
      final chunk = bits.substring(i, i + 4);
      final value = int.parse(chunk, radix: 2);
      buffer.write(value.toRadixString(16));
    }

    return buffer.toString();
  }
}
