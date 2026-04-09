import 'package:flutter/material.dart';

import '../../../core/localization/local_text.dart';
import '../../../main.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, es: 'Ajustes', en: 'Settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, es: 'Idioma', en: 'Language'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: appState.locale.languageCode,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'es',
                        child: Text('Español'),
                      ),
                      DropdownMenuItem(
                        value: 'en',
                        child: Text('English'),
                      ),
                    ],
                    onChanged: (value) async {
                      if (value == null) return;
                      await appState.setLocale(Locale(value));
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, es: 'Tema', en: 'Theme'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    groupValue: appState.themeMode,
                    onChanged: (value) async {
                      if (value != null) {
                        await appState.setThemeMode(value);
                      }
                    },
                    title: Text(
                      tr(context, es: 'Sistema', en: 'System'),
                    ),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    groupValue: appState.themeMode,
                    onChanged: (value) async {
                      if (value != null) {
                        await appState.setThemeMode(value);
                      }
                    },
                    title: Text(
                      tr(context, es: 'Claro', en: 'Light'),
                    ),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    groupValue: appState.themeMode,
                    onChanged: (value) async {
                      if (value != null) {
                        await appState.setThemeMode(value);
                      }
                    },
                    title: Text(
                      tr(context, es: 'Oscuro', en: 'Dark'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
