import 'package:flutter/material.dart';

import '../../../core/localization/local_text.dart';
import '../../../core/logging/app_logger.dart';
import '../data/local_backup_service.dart';
import '../data/postgres_remote_service.dart';
import '../data/server_sync_service.dart';
import '../domain/models/local_backup_file_model.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final LocalBackupService _backupService = LocalBackupService();
  final ServerSyncService _serverSyncService = ServerSyncService.instance;
  final PostgresRemoteService _postgresRemoteService = PostgresRemoteService();

  final List<LocalBackupFileModel> _backups = [];

  bool _isLoading = true;
  bool _isWorking = false;
  double _progress = 0;
  String _progressMessage = 'Sin actividad';

  @override
  void initState() {
    super.initState();
    _serverSyncService.start();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    AppLogger.instance
        .info('BackupPage', 'Cargando lista de respaldos locales');

    setState(() {
      _isLoading = true;
    });

    try {
      final backups = await _backupService.listBackups();

      if (!mounted) return;

      setState(() {
        _backups
          ..clear()
          ..addAll(backups);
        _isLoading = false;
      });
    } catch (e, st) {
      AppLogger.instance.error('BackupPage', 'Error cargando respaldos', e, st);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        tr(
          context,
          es: 'No se pudieron cargar los respaldos: $e',
          en: 'Could not load backups: $e',
        ),
      );
    }
  }

  Future<void> _createBackup() async {
    AppLogger.instance.info('BackupPage', 'Usuario pulsó crear respaldo local');

    setState(() {
      _isWorking = true;
      _progress = 0;
      _progressMessage =
          tr(context, es: 'Iniciando respaldo', en: 'Starting backup');
    });

    try {
      final created = await _backupService.createBackup(
        onProgress: (progress, message) {
          if (!mounted) return;
          setState(() {
            _progress = progress;
            _progressMessage = message;
          });
        },
      );

      if (!mounted) return;

      setState(() {
        _progress = 0.95;
        _progressMessage = 'Exportando ZIP a Descargas';
      });

      await _backupService.exportBackupToDownloads(created);

      if (!mounted) return;

      setState(() {
        _progress = 1.0;
        _progressMessage = 'Respaldo exportado a Descargas';
      });

      _showMessage(tr(
        context,
        es: 'Respaldo creado y guardado en Descargas: ${created.name}',
        en: 'Backup created and saved to Downloads: ${created.name}',
      ));

      await _loadBackups();
    } catch (e, st) {
      AppLogger.instance
          .error('BackupPage', 'Error creando respaldo local', e, st);

      if (!mounted) return;

      _showMessage(
        tr(context, es: 'Error de respaldo: $e', en: 'Backup error: $e'),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isWorking = false;
      });
    }
  }

  Future<void> _importBackupFromDevice() async {
    setState(() {
      _isWorking = true;
      _progress = 0.1;
      _progressMessage = 'Seleccionando ZIP del teléfono';
    });

    try {
      final imported = await _backupService.importBackupFromDevice();

      if (!mounted) return;

      if (imported == null) {
        setState(() {
          _progress = 0;
          _progressMessage = 'Importación cancelada';
        });
        return;
      }

      setState(() {
        _progress = 1.0;
        _progressMessage = 'ZIP importado correctamente';
      });

      _showMessage(
        tr(
          context,
          es: 'ZIP importado: ${imported.name}',
          en: 'ZIP imported: ${imported.name}',
        ),
      );

      await _loadBackups();
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        tr(
          context,
          es: 'Error importando ZIP: $e',
          en: 'Error importing ZIP: $e',
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isWorking = false;
      });
    }
  }

  Future<void> _testRemotePostgres() async {
    setState(() {
      _isWorking = true;
      _progress = 0.2;
      _progressMessage = 'Probando conexión remota';
    });

    try {
      final message = await _postgresRemoteService.testConnection();

      if (!mounted) return;

      setState(() {
        _progress = 1.0;
        _progressMessage = 'Conexión remota completada';
      });

      _showMessage(message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error de conexión remota: $e');
    } finally {
      if (!mounted) return;

      setState(() {
        _isWorking = false;
      });
    }
  }

  Future<void> _writeRemoteTestRow() async {
    setState(() {
      _isWorking = true;
      _progress = 0.2;
      _progressMessage = 'Probando escritura remota';
    });

    try {
      final message = await _postgresRemoteService.writeTestRow();

      if (!mounted) return;

      setState(() {
        _progress = 1.0;
        _progressMessage = 'Escritura remota completada';
      });

      _showMessage(message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error de escritura remota: $e');
    } finally {
      if (!mounted) return;

      setState(() {
        _isWorking = false;
      });
    }
  }

  Future<void> _syncNow() async {
    setState(() {
      _isWorking = true;
      _progress = 0.1;
      _progressMessage = 'Iniciando sincronización remota';
    });

    try {
      await _serverSyncService.requestSync(force: true);

      if (!mounted) return;

      setState(() {
        _progress = 1.0;
        _progressMessage = 'Sincronización remota completada';
      });

      _showMessage(
        tr(
          context,
          es: 'Sincronización remota solicitada.',
          en: 'Remote sync requested.',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error sincronizando: $e');
    } finally {
      if (!mounted) return;

      setState(() {
        _isWorking = false;
      });
    }
  }

  Future<void> _restoreBackup(LocalBackupFileModel backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(
            tr(context, es: 'Restaurar respaldo', en: 'Restore backup'),
          ),
          content: Text(
            '${tr(context, es: '¿Seguro que quieres restaurar', en: 'Are you sure you want to restore')} "${backup.name}"?\n\n'
            '${tr(
              context,
              es: 'Esto reemplazará la base de datos local y las imágenes actuales.',
              en: 'This will replace the local database and current images.',
            )}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr(context, es: 'Cancelar', en: 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr(context, es: 'Restaurar', en: 'Restore')),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isWorking = true;
      _progress = 0;
      _progressMessage =
          tr(context, es: 'Iniciando restauración', en: 'Starting restore');
    });

    try {
      await _backupService.restoreBackup(
        backup: backup,
        onProgress: (progress, message) {
          if (!mounted) return;
          setState(() {
            _progress = progress;
            _progressMessage = message;
          });
        },
      );

      if (!mounted) return;

      _showMessage(
        tr(
          context,
          es: 'Restauración completada.',
          en: 'Restore completed.',
        ),
      );
    } catch (e, st) {
      AppLogger.instance
          .error('BackupPage', 'Error restaurando respaldo local', e, st);

      if (!mounted) return;

      _showMessage(
        tr(context, es: 'Error al restaurar: $e', en: 'Restore error: $e'),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isWorking = false;
      });
    }
  }

  Future<void> _deleteBackup(LocalBackupFileModel backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title:
              Text(tr(context, es: 'Eliminar respaldo', en: 'Delete backup')),
          content: Text(
            tr(
              context,
              es: '¿Seguro que quieres eliminar "${backup.name}"?',
              en: 'Are you sure you want to delete "${backup.name}"?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr(context, es: 'Cancelar', en: 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr(context, es: 'Eliminar', en: 'Delete')),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _backupService.deleteBackup(backup.path);

    if (!mounted) return;

    _showMessage(
      tr(context, es: 'Respaldo eliminado.', en: 'Backup deleted.'),
    );

    await _loadBackups();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';

    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';

    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';

    final gb = mb / 1024;
    return '${gb.toStringAsFixed(2)} GB';
  }

  Color _syncColor() {
    switch (_serverSyncService.state) {
      case ServerSyncState.synced:
        return Colors.green;
      case ServerSyncState.syncing:
      case ServerSyncState.checking:
        return Colors.orange;
      case ServerSyncState.disconnected:
      case ServerSyncState.error:
        return Colors.red;
      case ServerSyncState.idle:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, es: 'Respaldo local', en: 'Local backup')),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadBackups,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
            children: [
              AnimatedBuilder(
                animation: _serverSyncService,
                builder: (context, _) {
                  final color = _syncColor();
                  final lastSyncAt = _serverSyncService.lastSyncAt;

                  final lastSyncText = lastSyncAt == null
                      ? tr(
                          context,
                          es: 'Sin respaldo remoto todavía',
                          en: 'No remote backup yet',
                        )
                      : tr(
                          context,
                          es: 'Último respaldo: ${_formatDate(lastSyncAt)}',
                          en: 'Last backup: ${_formatDate(lastSyncAt)}',
                        );

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.cloud_done_outlined, color: color),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _serverSyncService.statusText,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(lastSyncText),
                          ),
                          if (_serverSyncService.lastError != null) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _serverSyncService.lastError!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed:
                                  (_isWorking || _serverSyncService.isBusy)
                                      ? null
                                      : _syncNow,
                              icon: const Icon(Icons.sync),
                              label: Text(
                                tr(
                                  context,
                                  es: 'Sincronizar ahora',
                                  en: 'Sync now',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          tr(
                            context,
                            es: 'Respaldos ZIP',
                            en: 'ZIP backups',
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          tr(
                            context,
                            es: 'Al crear el respaldo, la app abrirá el selector del sistema para que guardes una copia visible del ZIP en tu teléfono.',
                            en: 'When creating a backup, the app will open the system picker so you can save a visible ZIP copy on your device.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isWorking ? null : _createBackup,
                          icon: const Icon(Icons.archive_outlined),
                          label: Text(
                            tr(
                              context,
                              es: 'Crear y guardar en Descargas',
                              en: 'Create and save to Downloads',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed:
                              _isWorking ? null : _importBackupFromDevice,
                          icon: const Icon(Icons.folder_open_outlined),
                          label: Text(
                            tr(
                              context,
                              es: 'Importar ZIP del teléfono',
                              en: 'Import ZIP from device',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isWorking ? null : _loadBackups,
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            tr(
                              context,
                              es: 'Actualizar lista',
                              en: 'Refresh list',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isWorking ? null : _testRemotePostgres,
                  icon: const Icon(Icons.cloud_done_outlined),
                  label: const Text('Probar PostgreSQL remoto'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isWorking ? null : _writeRemoteTestRow,
                  icon: const Icon(Icons.upload_outlined),
                  label: const Text('Probar escritura remota'),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _progressMessage,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: _isWorking ? _progress.clamp(0, 1) : 0,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${(_progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_backups.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      tr(
                        context,
                        es: 'No se encontraron respaldos locales importados o creados.',
                        en: 'No local imported or created backups were found.',
                      ),
                    ),
                  ),
                )
              else ...[
                Text(
                  tr(
                    context,
                    es: 'Respaldos disponibles',
                    en: 'Available backups',
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._backups.map(
                  (backup) => Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.folder_zip_outlined),
                      ),
                      title: Text(backup.name),
                      subtitle: Text(
                        '${tr(context, es: 'Fecha', en: 'Date')}: ${_formatDate(backup.modifiedAt)}\n'
                        '${tr(context, es: 'Tamaño', en: 'Size')}: ${_formatBytes(backup.size)}',
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'restore') {
                            _restoreBackup(backup);
                          } else if (value == 'delete') {
                            _deleteBackup(backup);
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'restore',
                            child: Text(
                              tr(context, es: 'Restaurar', en: 'Restore'),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              tr(context, es: 'Eliminar', en: 'Delete'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
