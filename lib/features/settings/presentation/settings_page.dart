import 'package:flutter/material.dart';

import '../../../core/localization/local_text.dart';
import '../../../main.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/presentation/auth_gate_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _authService = AuthService.instance;

  bool _isBusy = false;
  String _sessionModeLabel = '';

  @override
  void initState() {
    super.initState();
    _loadSessionMode();
  }

  Future<void> _loadSessionMode() async {
    final isLocal = await _authService.isLocalSession();

    if (!mounted) return;

    setState(() {
      _sessionModeLabel = isLocal
          ? tr(context, es: 'Sesión local', en: 'Local session')
          : tr(context, es: 'Sesión web', en: 'Web session');
    });
  }

  Future<void> _openAccessGate() async {
    setState(() {
      _isBusy = true;
    });

    try {
      await _authService.logout();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGatePage()),
        (route) => false,
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
      });
    }
  }

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
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, es: 'Acceso', en: 'Access'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _sessionModeLabel.isEmpty
                        ? tr(
                            context,
                            es: 'Cargando modo de sesión...',
                            en: 'Loading session mode...',
                          )
                        : _sessionModeLabel,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr(
                      context,
                      es: 'Desde aquí puedes volver a la pantalla de acceso para iniciar sesión web, crear usuario web o ingresar en modo local.',
                      en: 'From here you can return to the access screen to sign in on the web, create a web user, or enter in local mode.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isBusy ? null : _openAccessGate,
                      icon: _isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: Text(
                        tr(
                          context,
                          es: 'Ir a inicio de sesión',
                          en: 'Go to sign in',
                        ),
                      ),
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
