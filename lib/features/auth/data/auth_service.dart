import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/utils/text_normalizer.dart';
import '../../backup/data/postgres_remote_service.dart';
import '../domain/models/app_user_model.dart';
import 'auth_repository.dart';

class AuthActionResult {
  final bool success;
  final String message;

  const AuthActionResult({
    required this.success,
    required this.message,
  });
}

class AuthService {
  AuthService._internal();

  static final AuthService instance = AuthService._internal();

  static const String _sessionKey = 'auth_is_logged_in';
  static const String _sessionUserKey = 'auth_user_id';
  static const String _setupCompletedKey = 'auth_setup_completed';

  final AuthRepository _repository = AuthRepository();
  final PostgresRemoteService _remoteService = PostgresRemoteService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final Uuid _uuid = const Uuid();

  Future<bool> hasAnyUser() {
    return _repository.countUsers().then((value) => value > 0);
  }

  Future<bool> isSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_setupCompletedKey) ?? false;
  }

  Future<void> markSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_setupCompletedKey, true);
  }

  Future<AppUserModel?> getCurrentUser() async {
    return _repository.getFirstUser();
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sessionKey) ?? false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_sessionUserKey);
  }

  Future<AuthActionResult> createUser({
    required String username,
    required String password,
    required bool biometricEnabled,
  }) async {
    const tag = 'AuthService';

    final cleanUsername = username.trim();
    final normalizedUsername = TextNormalizer.normalize(cleanUsername);

    final localUser = await _repository.findByUsername(normalizedUsername);
    if (localUser != null) {
      return const AuthActionResult(
        success: false,
        message: 'Ese usuario ya existe localmente. Inicia sesión.',
      );
    }

    final existsRemote = await _remoteService.userExistsByUsername(
      normalizedUsername,
    );

    if (existsRemote) {
      return const AuthActionResult(
        success: false,
        message: 'Ese usuario ya existe en el servidor. Debes iniciar sesión.',
      );
    }

    final now = DateTime.now();
    final salt = _generateSalt();
    final passwordHash = _hashPassword(password, salt);

    final user = AppUserModel(
      id: _uuid.v4(),
      username: cleanUsername,
      normalizedUsername: normalizedUsername,
      passwordHash: passwordHash,
      passwordSalt: salt,
      biometricEnabled: biometricEnabled,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.insertUser(user);
    await _remoteService.upsertRemoteUser(user);
    await markSetupCompleted();
    await _saveSession(user.id);

    AppLogger.instance.info(tag, 'Usuario creado: ${user.username}');

    return const AuthActionResult(
      success: true,
      message: 'Usuario creado correctamente.',
    );
  }

  Future<AuthActionResult> loginUser({
    required String username,
    required String password,
  }) async {
    const tag = 'AuthService';

    final cleanUsername = username.trim();
    final normalizedUsername = TextNormalizer.normalize(cleanUsername);

    final localUser = await _repository.findByUsername(normalizedUsername);
    if (localUser != null) {
      final expectedHash = _hashPassword(password, localUser.passwordSalt);
      if (expectedHash == localUser.passwordHash) {
        await markSetupCompleted();
        await _saveSession(localUser.id);
        AppLogger.instance
            .info(tag, 'Login local correcto: ${localUser.username}');
        return const AuthActionResult(
          success: true,
          message: 'Inicio de sesión correcto.',
        );
      }

      return const AuthActionResult(
        success: false,
        message: 'Clave incorrecta.',
      );
    }

    final remoteUser = await _remoteService.findRemoteUserByUsername(
      normalizedUsername,
    );

    if (remoteUser == null) {
      return const AuthActionResult(
        success: false,
        message: 'Usuario no encontrado.',
      );
    }

    final remoteSalt = remoteUser['password_salt'] as String;
    final remoteHash = remoteUser['password_hash'] as String;
    final expectedRemoteHash = _hashPassword(password, remoteSalt);

    if (expectedRemoteHash != remoteHash) {
      return const AuthActionResult(
        success: false,
        message: 'Clave incorrecta.',
      );
    }

    final importedUser = AppUserModel(
      id: remoteUser['id'] as String,
      username: remoteUser['username'] as String,
      normalizedUsername: remoteUser['normalized_username'] as String,
      passwordHash: remoteHash,
      passwordSalt: remoteSalt,
      biometricEnabled:
          ((remoteUser['biometric_enabled'] as num?) ?? 0).toInt() == 1,
      createdAt: DateTime.parse(remoteUser['created_at'] as String),
      updatedAt: DateTime.parse(remoteUser['updated_at'] as String),
    );

    await _repository.insertOrReplaceUser(importedUser);
    await markSetupCompleted();
    await _saveSession(importedUser.id);

    AppLogger.instance
        .info(tag, 'Login remoto correcto: ${importedUser.username}');

    return const AuthActionResult(
      success: true,
      message: 'Inicio de sesión correcto.',
    );
  }

  Future<bool> canUseBiometrics() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return supported || canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<bool> loginWithBiometrics() async {
    const tag = 'AuthService';

    final user = await _repository.getFirstUser();
    if (user == null || !user.biometricEnabled) {
      AppLogger.instance.error(tag, 'Biometría no habilitada para el usuario');
      return false;
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Confirma tu identidad para entrar a Recollecto',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (authenticated) {
        await markSetupCompleted();
        await _saveSession(user.id);
        AppLogger.instance.info(tag, 'Login biométrico correcto');
      }

      return authenticated;
    } catch (e, st) {
      AppLogger.instance.error(tag, 'Error autenticando con biometría', e, st);
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final user = await _repository.getFirstUser();
    if (user == null) return;

    await _repository.updateBiometricEnabled(
      userId: user.id,
      enabled: enabled,
    );
  }

  Future<void> _saveSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, true);
    await prefs.setString(_sessionUserKey, userId);
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    return sha256.convert(bytes).toString();
  }
}
