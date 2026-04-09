import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_save_directory/file_save_directory.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/models/local_backup_file_model.dart';

typedef BackupProgressCallback = void Function(double progress, String message);

class LocalBackupService {
  Future<Directory> _getBackupDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(
      p.join(documentsDir.path, 'recollecto', 'backups'),
    );

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    return backupDir;
  }

  Future<LocalBackupFileModel> createBackup({
    required BackupProgressCallback onProgress,
  }) async {
    const tag = 'LocalBackupService';
    AppLogger.instance.info(tag, 'Inicio de respaldo local');

    onProgress(0.05, 'Preparando respaldo');

    final backupDir = await _getBackupDirectory();
    final tempDir = await getTemporaryDirectory();

    final dbPath = p.join(await getDatabasesPath(), 'recollecto.db');
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      AppLogger.instance.error(tag, 'No existe la base de datos local');
      throw Exception('No existe la base de datos local.');
    }

    final documentsDir = await getApplicationDocumentsDirectory();
    final itemsRoot = Directory(
      p.join(documentsDir.path, 'recollecto', 'items'),
    );
    final logosRoot = Directory(
      p.join(documentsDir.path, 'recollecto', 'collection_logos'),
    );

    final backupId = DateTime.now().millisecondsSinceEpoch.toString();
    final workDir = Directory(
      p.join(tempDir.path, 'recollecto_local_backup_$backupId'),
    );

    if (await workDir.exists()) {
      await workDir.delete(recursive: true);
    }
    await workDir.create(recursive: true);

    final manifestFile = File(p.join(workDir.path, 'manifest.json'));
    final assetFiles = <File>[];

    if (await itemsRoot.exists()) {
      for (final entity in itemsRoot.listSync(recursive: true)) {
        if (entity is File) {
          assetFiles.add(entity);
        }
      }
    }

    if (await logosRoot.exists()) {
      for (final entity in logosRoot.listSync(recursive: true)) {
        if (entity is File) {
          assetFiles.add(entity);
        }
      }
    }

    await manifestFile.writeAsString(
      jsonEncode({
        'app': 'Recollecto',
        'version': 2,
        'createdAt': DateTime.now().toIso8601String(),
        'databaseName': 'recollecto.db',
        'assetCount': assetFiles.length,
      }),
    );

    final allFiles = <File>[
      dbFile,
      manifestFile,
      ...assetFiles,
    ];

    final archive = Archive();

    for (int i = 0; i < allFiles.length; i++) {
      final file = allFiles[i];
      late final String archivePath;

      if (file.path == dbFile.path) {
        archivePath = 'database/recollecto.db';
      } else if (file.path == manifestFile.path) {
        archivePath = 'manifest.json';
      } else if (p.isWithin(itemsRoot.path, file.path)) {
        final relative = p.relative(file.path, from: itemsRoot.path);
        archivePath = p.join('items', relative);
      } else if (p.isWithin(logosRoot.path, file.path)) {
        final relative = p.relative(file.path, from: logosRoot.path);
        archivePath = p.join('collection_logos', relative);
      } else {
        continue;
      }

      final bytes = await file.readAsBytes();
      archive.addFile(ArchiveFile(archivePath, bytes.length, bytes));

      final progress = 0.10 + ((i + 1) / allFiles.length) * 0.45;
      onProgress(progress, 'Empaquetando archivos');
    }

    final zipBytes = ZipEncoder().encode(archive);

    if (zipBytes == null) {
      AppLogger.instance.error(tag, 'No se pudo generar el ZIP');
      throw Exception('No se pudo crear el archivo ZIP.');
    }

    final zipPath = p.join(
      backupDir.path,
      'recollecto_backup_$backupId.zip',
    );

    final zipFile = File(zipPath);
    await zipFile.writeAsBytes(zipBytes, flush: true);

    onProgress(1.0, 'Respaldo completado');

    final stat = await zipFile.stat();

    AppLogger.instance.info(tag, 'Respaldo creado: ${zipFile.path}');
    debugPrint('ZIP PATH INTERNO: $zipPath');

    if (await workDir.exists()) {
      await workDir.delete(recursive: true);
    }

    return LocalBackupFileModel(
      path: zipFile.path,
      name: p.basename(zipFile.path),
      modifiedAt: stat.modified,
      size: stat.size,
    );
  }

  Future<void> exportBackupToDownloads(LocalBackupFileModel backup) async {
    const tag = 'LocalBackupService';

    final sourceFile = File(backup.path);
    if (!await sourceFile.exists()) {
      throw Exception('El respaldo local no existe.');
    }

    final bytes = await sourceFile.readAsBytes();

    AppLogger.instance.info(tag, 'Exportando ZIP a Descargas: ${backup.name}');

    await FileSaveDirectory.instance.saveFile(
      fileName: backup.name,
      fileBytes: bytes,
      location: SaveLocation.downloads,
      openAfterSave: false,
    );

    AppLogger.instance.info(tag, 'ZIP exportado a Descargas');
  }

  Future<List<LocalBackupFileModel>> listBackups() async {
    const tag = 'LocalBackupService';
    AppLogger.instance.info(tag, 'Listando respaldos locales');

    final backupDir = await _getBackupDirectory();

    if (!await backupDir.exists()) {
      return [];
    }

    final files = backupDir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.zip'))
        .toList();

    final result = <LocalBackupFileModel>[];

    for (final file in files) {
      final stat = await file.stat();
      result.add(
        LocalBackupFileModel(
          path: file.path,
          name: p.basename(file.path),
          modifiedAt: stat.modified,
          size: stat.size,
        ),
      );
    }

    result.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));

    AppLogger.instance.info(tag, 'Respaldos encontrados: ${result.length}');
    return result;
  }

  Future<bool> hasAnyBackup() async {
    final backups = await listBackups();
    return backups.isNotEmpty;
  }

  Future<LocalBackupFileModel?> getLatestBackup() async {
    final backups = await listBackups();
    if (backups.isEmpty) return null;
    return backups.first;
  }

  Future<LocalBackupFileModel?> importBackupFromDevice() async {
    const tag = 'LocalBackupService';
    AppLogger.instance.info(tag, 'Abriendo selector para importar ZIP');

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      AppLogger.instance.info(tag, 'Importación cancelada por el usuario');
      return null;
    }

    final selectedPath = result.files.single.path;
    if (selectedPath == null || selectedPath.trim().isEmpty) {
      throw Exception('No se pudo obtener la ruta del archivo seleccionado.');
    }

    return importBackupFile(File(selectedPath));
  }

  Future<LocalBackupFileModel> importBackupFile(File sourceFile) async {
    const tag = 'LocalBackupService';

    if (!await sourceFile.exists()) {
      throw Exception('El archivo seleccionado no existe.');
    }

    if (!sourceFile.path.toLowerCase().endsWith('.zip')) {
      throw Exception('Selecciona un archivo ZIP válido.');
    }

    final backupDir = await _getBackupDirectory();
    final sourceDir = p.normalize(p.dirname(sourceFile.path));
    final targetDir = p.normalize(backupDir.path);

    if (sourceDir == targetDir) {
      final stat = await sourceFile.stat();
      return LocalBackupFileModel(
        path: sourceFile.path,
        name: p.basename(sourceFile.path),
        modifiedAt: stat.modified,
        size: stat.size,
      );
    }

    final baseName = p.basenameWithoutExtension(sourceFile.path);
    final importedName =
        '${baseName}_imported_${DateTime.now().millisecondsSinceEpoch}.zip';
    final importedPath = p.join(backupDir.path, importedName);

    final copied = await sourceFile.copy(importedPath);
    final stat = await copied.stat();

    AppLogger.instance.info(tag, 'ZIP importado: ${copied.path}');

    return LocalBackupFileModel(
      path: copied.path,
      name: p.basename(copied.path),
      modifiedAt: stat.modified,
      size: stat.size,
    );
  }

  Future<void> restoreLatestBackup({
    required BackupProgressCallback onProgress,
  }) async {
    final latest = await getLatestBackup();

    if (latest == null) {
      throw Exception('No hay respaldos disponibles para restaurar.');
    }

    await restoreBackup(
      backup: latest,
      onProgress: onProgress,
    );
  }

  Future<void> restoreBackup({
    required LocalBackupFileModel backup,
    required BackupProgressCallback onProgress,
  }) async {
    const tag = 'LocalBackupService';
    AppLogger.instance.info(tag, 'Restaurando respaldo: ${backup.name}');

    final zipFile = File(backup.path);

    if (!await zipFile.exists()) {
      throw Exception('El archivo de respaldo no existe.');
    }

    final tempDir = await getTemporaryDirectory();
    final extractRoot = Directory(
      p.join(
        tempDir.path,
        'restore_extract_${DateTime.now().millisecondsSinceEpoch}',
      ),
    );

    if (await extractRoot.exists()) {
      await extractRoot.delete(recursive: true);
    }
    await extractRoot.create(recursive: true);

    onProgress(0.10, 'Leyendo archivo ZIP');

    final archiveBytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(archiveBytes);

    final archiveFiles = archive.files.where((f) => f.isFile).toList();

    for (int i = 0; i < archiveFiles.length; i++) {
      final archiveFile = archiveFiles[i];
      final outputFile = File(p.join(extractRoot.path, archiveFile.name));

      await outputFile.parent.create(recursive: true);

      final data = archiveFile.content as List<int>;
      await outputFile.writeAsBytes(data, flush: true);

      final progress = 0.10 + ((i + 1) / archiveFiles.length) * 0.40;
      onProgress(progress, 'Extrayendo respaldo');
    }

    final extractedDb = File(
      p.join(extractRoot.path, 'database', 'recollecto.db'),
    );

    if (!await extractedDb.exists()) {
      throw Exception('El respaldo no contiene la base de datos.');
    }

    onProgress(0.60, 'Restaurando base de datos');

    await AppDatabase.instance.close();

    final dbPath = p.join(await getDatabasesPath(), 'recollecto.db');
    final currentDb = File(dbPath);

    if (await currentDb.exists()) {
      await currentDb.delete();
    }

    await extractedDb.copy(dbPath);

    final documentsDir = await getApplicationDocumentsDirectory();

    final currentItemsRoot = Directory(
      p.join(documentsDir.path, 'recollecto', 'items'),
    );
    final extractedItemsRoot = Directory(
      p.join(extractRoot.path, 'items'),
    );

    final currentLogosRoot = Directory(
      p.join(documentsDir.path, 'recollecto', 'collection_logos'),
    );
    final extractedLogosRoot = Directory(
      p.join(extractRoot.path, 'collection_logos'),
    );

    if (await currentItemsRoot.exists()) {
      await currentItemsRoot.delete(recursive: true);
    }

    if (await currentLogosRoot.exists()) {
      await currentLogosRoot.delete(recursive: true);
    }

    if (await extractedItemsRoot.exists()) {
      await _copyDirectoryWithProgress(
        source: extractedItemsRoot,
        destination: currentItemsRoot,
        onProgress: onProgress,
        start: 0.70,
        end: 0.90,
      );
    }

    if (await extractedLogosRoot.exists()) {
      await _copyDirectoryWithProgress(
        source: extractedLogosRoot,
        destination: currentLogosRoot,
        onProgress: onProgress,
        start: 0.90,
        end: 0.98,
      );
    }

    onProgress(1.0, 'Restauración completada');

    if (await extractRoot.exists()) {
      await extractRoot.delete(recursive: true);
    }

    AppLogger.instance.info(tag, 'Restauración finalizada');
  }

  Future<void> deleteBackup(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> _copyDirectoryWithProgress({
    required Directory source,
    required Directory destination,
    required BackupProgressCallback onProgress,
    required double start,
    required double end,
  }) async {
    final files = source.listSync(recursive: true).whereType<File>().toList();

    if (files.isEmpty) {
      await destination.create(recursive: true);
      return;
    }

    for (int i = 0; i < files.length; i++) {
      final sourceFile = files[i];
      final relative = p.relative(sourceFile.path, from: source.path);
      final destFile = File(p.join(destination.path, relative));

      await destFile.parent.create(recursive: true);
      await sourceFile.copy(destFile.path);

      final progress = start + ((i + 1) / files.length) * (end - start);
      onProgress(progress, 'Restaurando archivos');
    }
  }
}
