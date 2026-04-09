import 'package:flutter/material.dart';

import '../../../core/localization/local_text.dart';
import '../../home/presentation/homepage.dart';
import '../data/auth_service.dart';

class LoginPage extends StatefulWidget {
  final bool allowCreateUser;

  const LoginPage({
    super.key,
    required this.allowCreateUser,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService.instance;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _canUseBiometrics = false;
  bool _enableBiometricsOnCreate = true;
  bool _loading = true;
  bool _busy = false;
  bool _obscure = true;

  bool get _isCreateMode => widget.allowCreateUser;

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
    final canBiometrics = await _authService.canUseBiometrics();

    if (!mounted) return;

    setState(() {
      _canUseBiometrics = canBiometrics;
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
      if (_isCreateMode) {
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

  Future<void> _loginBiometric() async {
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
            es: 'No fue posible validar la huella.',
            en: 'Could not validate biometrics.',
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

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isCreateMode
        ? tr(context, es: 'Crear acceso', en: 'Create access')
        : tr(context, es: 'Iniciar sesión', en: 'Sign in');

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(title),
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
                          Text(
                            _isCreateMode
                                ? tr(
                                    context,
                                    es: 'Crea el usuario local de la app.',
                                    en: 'Create the local app user.',
                                  )
                                : tr(
                                    context,
                                    es: 'Ingresa con tu usuario y clave locales.',
                                    en: 'Sign in with your local username and password.',
                                  ),
                            style: const TextStyle(fontSize: 16),
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
                          if (_isCreateMode && _canUseBiometrics) ...[
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
                                  es: 'Activar huella al crear usuario',
                                  en: 'Enable biometrics on setup',
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
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      _isCreateMode
                                          ? Icons.person_add
                                          : Icons.lock_open,
                                    ),
                              label: Text(
                                _isCreateMode
                                    ? tr(
                                        context,
                                        es: 'Crear usuario',
                                        en: 'Create user',
                                      )
                                    : tr(
                                        context,
                                        es: 'Entrar',
                                        en: 'Sign in',
                                      ),
                              ),
                            ),
                          ),
                          if (!_isCreateMode && _canUseBiometrics) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _busy ? null : _loginBiometric,
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
                ],
              ),
            ),
    );
  }
}
