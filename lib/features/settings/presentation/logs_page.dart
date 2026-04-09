import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/local_text.dart';
import '../../../core/logging/app_logger.dart';

class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logger = AppLogger.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, es: 'Logs de la app', en: 'App logs')),
        actions: [
          IconButton(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: logger.exportAsText()),
              );

              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tr(context, es: 'Logs copiados al portapapeles', en: 'Logs copied to clipboard')),
                ),
              );
            },
            icon: const Icon(Icons.copy_outlined),
          ),
          IconButton(
            onPressed: () {
              logger.clear();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tr(context, es: 'Logs eliminados', en: 'Logs cleared')),
                ),
              );
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: logger,
        builder: (context, _) {
          final entries = logger.entries;

          if (entries.isEmpty) {
            return Center(
              child: Text(tr(context, es: 'Todavía no hay logs.', en: 'There are no logs yet.')),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isError = entry.level == 'ERROR';

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.level} • ${entry.tag}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isError ? Colors.red : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.timestamp.toIso8601String(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      SelectableText(entry.message),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
