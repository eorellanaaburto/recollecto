import 'package:flutter/material.dart';

import '../../../core/localization/local_text.dart';
import '../../home/presentation/homepage.dart';
import '../data/auth_service.dart';

class AuthGatePage extends StatefulWidget {
  const AuthGatePage({super.key});

  @override
  State<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends State<AuthGatePage> {
  final AuthService _authService = AuthService.instance;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = true;
  bool _busy = false;
  bool _obscure = true;
  bool _createMode = false;
  bool _canUseBiometrics = false;
  bool _enableBiometricsOnCreate = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final canUseBiometrics = await _authService.canUseBiometrics();

    if (!mounted) return;

    setState(() {
      _canUseBiometrics = canUseBiometrics;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showMessage(
        tr(
          context,
          es: 'Debes ingresar usuario y clave.',
          en: 'You must enter username and password.',
        ),
      );
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      if (_createMode) {
        final result = await _authService.createUser(
          username: username,
          password: password,
          biometricEnabled: _canUseBiometrics && _enableBiometricsOnCreate,
        );

        if (!mounted) return;

        if (!result.success) {
          _showMessage(result.message);
          return;
        }
      } else {
        final result = await _authService.loginUser(
          username: username,
          password: password,
        );

        if (!mounted) return;

        if (!result.success) {
          _showMessage(result.message);
          return;
        }
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _loginWithBiometrics() async {
    setState(() {
      _busy = true;
    });

    try {
      final ok = await _authService.loginWithBiometrics();

      if (!mounted) return;

      if (!ok) {
        _showMessage(
          tr(
            context,
            es: 'No fue posible autenticar con huella.',
            en: 'Could not authenticate with biometrics.',
          ),
        );
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _enterLocal() async {
    setState(() {
      _busy = true;
    });

    try {
      await _authService.enterLocalMode();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _busy = false;
      });
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _createMode
        ? tr(context, es: 'Crear usuario web', en: 'Create web user')
        : tr(context, es: 'Iniciar sesión web', en: 'Web sign in');

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(tr(context, es: 'Acceso', en: 'Access')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SegmentedButton<bool>(
                            segments: [
                              ButtonSegment<bool>(
                                value: false,
                                label: Text(
                                  tr(context,
                                      es: 'Iniciar sesión', en: 'Sign in'),
                                ),
                                icon: const Icon(Icons.lock_open),
                              ),
                              ButtonSegment<bool>(
                                value: true,
                                label: Text(
                                  tr(context,
                                      es: 'Crear usuario', en: 'Create user'),
                                ),
                                icon: const Icon(Icons.person_add),
                              ),
                            ],
                            selected: {_createMode},
                            onSelectionChanged: (values) {
                              setState(() {
                                _createMode = values.first;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _createMode
                                ? tr(
                                    context,
                                    es: 'Crea un usuario en el sistema web. Si ya existe, te avisaremos.',
                                    en: 'Create a user in the web system. If it already exists, we will warn you.',
                                  )
                                : tr(
                                    context,
                                    es: 'Inicia sesión con un usuario del sistema web.',
                                    en: 'Sign in with a web system user.',
                                  ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText:
                                  tr(context, es: 'Usuario', en: 'Username'),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText:
                                  tr(context, es: 'Clave', en: 'Password'),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscure = !_obscure;
                                  });
                                },
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                          ),
                          if (_createMode && _canUseBiometrics) ...[
                            const SizedBox(height: 12),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _enableBiometricsOnCreate,
                              onChanged: (value) {
                                setState(() {
                                  _enableBiometricsOnCreate = value;
                                });
                              },
                              title: Text(
                                tr(
                                  context,
                                  es: 'Activar huella para este usuario',
                                  en: 'Enable biometrics for this user',
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _busy ? null : _submit,
                              icon: _busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : Icon(_createMode
                                      ? Icons.person_add
                                      : Icons.lock_open),
                              label: Text(
                                _createMode
                                    ? tr(context,
                                        es: 'Crear usuario web',
                                        en: 'Create web user')
                                    : tr(context,
                                        es: 'Entrar al sistema web',
                                        en: 'Sign in to web'),
                              ),
                            ),
                          ),
                          if (!_createMode && _canUseBiometrics) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _busy ? null : _loginWithBiometrics,
                                icon: const Icon(Icons.fingerprint),
                                label: Text(
                                  tr(
                                    context,
                                    es: 'Entrar con huella',
                                    en: 'Sign in with biometrics',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr(context,
                                es: 'Ingreso local', en: 'Local access'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tr(
                              context,
                              es: 'Entra de forma local, sin clave y sin usar servicios web.',
                              en: 'Enter locally, without password and without using web services.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _busy ? null : _enterLocal,
                              icon: const Icon(Icons.offline_bolt_outlined),
                              label: Text(
                                tr(
                                  context,
                                  es: 'Ingresar local',
                                  en: 'Enter locally',
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
            ),
    );
  }
}
