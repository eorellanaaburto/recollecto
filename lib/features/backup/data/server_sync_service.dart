import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../../core/logging/app_logger.dart';
import 'postgres_remote_service.dart';

enum ServerSyncState {
  idle,
  checking,
  disconnected,
  syncing,
  synced,
  error,
}

class ServerSyncService extends ChangeNotifier {
  ServerSyncService._internal();

  static final ServerSyncService instance = ServerSyncService._internal();

  final PostgresRemoteService _postgresRemoteService = PostgresRemoteService();

  Timer? _timer;
  bool _started = false;
  bool _busy = false;

  ServerSyncState _state = ServerSyncState.idle;
  String _statusText = 'Sin verificar';
  String? _lastError;
  DateTime? _lastSyncAt;
  String? _lastSyncedFingerprint;

  ServerSyncState get state => _state;
  String get statusText => _statusText;
  String? get lastError => _lastError;
  DateTime? get lastSyncAt => _lastSyncAt;
  bool get isBusy => _busy;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    AppLogger.instance
        .info('ServerSyncService', 'Iniciando monitor de servidor');

    await _checkAndSync(reason: 'start');

    _timer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _checkAndSync(reason: 'poll'),
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _started = false;
  }

  Future<void> requestSync({bool force = true}) async {
    await _checkAndSync(reason: 'manual', forceSync: force);
  }

  Future<void> _checkAndSync({
    required String reason,
    bool forceSync = false,
  }) async {
    if (_busy) return;
    _busy = true;
    _setState(ServerSyncState.checking, 'Buscando servidor...');

    try {
      final available = await _postgresRemoteService.isServerAvailable();

      if (!available) {
        _setState(ServerSyncState.disconnected, 'Servidor desconectado');
        return;
      }

      final fingerprint = await _buildLocalFingerprint();

      if (!forceSync &&
          _lastSyncedFingerprint != null &&
          _lastSyncedFingerprint == fingerprint) {
        _setState(
          ServerSyncState.synced,
          _lastSyncAt == null
              ? 'Servidor conectado'
              : 'Servidor conectado • respaldo al día',
        );
        return;
      }

      _setState(
        ServerSyncState.syncing,
        'Servidor conectado • respaldando SQL...',
      );

      final result = await _postgresRemoteService.backupLocalSqlToServer();
      _lastSyncedFingerprint = fingerprint;
      _lastSyncAt = DateTime.now();

      _setState(
        ServerSyncState.synced,
        'Servidor conectado • respaldo SQL actualizado '
        '(${result.totalRows} registros)',
      );

      AppLogger.instance.info(
        'ServerSyncService',
        'Sincronización completada por $reason',
      );
    } catch (e, st) {
      AppLogger.instance.error(
        'ServerSyncService',
        'Error sincronizando con el servidor',
        e,
        st,
      );

      _lastError = '$e';
      _setState(ServerSyncState.error, 'Error de sincronización');
    } finally {
      _busy = false;
    }
  }

  Future<String> _buildLocalFingerprint() async {
    final dbPath = p.join(await getDatabasesPath(), 'recollecto.db');
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      return 'missing-db';
    }

    final stat = await dbFile.stat();
    return '${stat.size}:${stat.modified.millisecondsSinceEpoch}';
  }

  void _setState(ServerSyncState newState, String text) {
    _state = newState;
    _statusText = text;
    notifyListeners();
  }
}
