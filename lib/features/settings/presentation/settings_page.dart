import 'package:flutter/material.dart';
import 'package:recollecto/features/settings/presentation/logs_page.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../l10n/generated/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.instance;
    final localeController = LocaleController.instance;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          themeController,
          localeController,
        ]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.translate_outlined),
                  title: Text(l10n.language),
                  subtitle: Text(
                      _languageLabel(context, localeController.currentCode)),
                  trailing: DropdownButton<String>(
                    value: localeController.currentCode,
                    underline: const SizedBox.shrink(),
                    items: [
                      DropdownMenuItem(
                        value: 'system',
                        child: Text(l10n.languageSystem),
                      ),
                      DropdownMenuItem(
                        value: 'es',
                        child: Text(l10n.languageSpanish),
                      ),
                      DropdownMenuItem(
                        value: 'en',
                        child: Text(l10n.languageEnglish),
                      ),
                    ],
                    onChanged: (value) async {
                      if (value == null) return;

                      if (value == 'system') {
                        await localeController.setSystemLocale();
                      } else {
                        await localeController.setLocale(Locale(value));
                      }
                    },
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: Text(l10n.viewLogs),
                  subtitle: Text(l10n.viewLogsSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LogsPage()),
                    );
                  },
                ),
              ),
              Card(
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.light,
                      groupValue: themeController.themeMode,
                      title: Text(l10n.themeLight),
                      subtitle: Text(l10n.themeLightSubtitle),
                      onChanged: (value) {
                        if (value != null) {
                          themeController.setThemeMode(value);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.dark,
                      groupValue: themeController.themeMode,
                      title: Text(l10n.themeDark),
                      subtitle: Text(l10n.themeDarkSubtitle),
                      onChanged: (value) {
                        if (value != null) {
                          themeController.setThemeMode(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _languageLabel(BuildContext context, String code) {
    final l10n = AppLocalizations.of(context)!;

    switch (code) {
      case 'es':
        return l10n.languageSpanish;
      case 'en':
        return l10n.languageEnglish;
      default:
        return l10n.languageSystem;
    }
  }
}
