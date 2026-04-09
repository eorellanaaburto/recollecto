class AppUserModel {
  final String id;
  final String username;
  final String normalizedUsername;
  final String passwordHash;
  final String passwordSalt;
  final bool biometricEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppUserModel({
    required this.id,
    required this.username,
    required this.normalizedUsername,
    required this.passwordHash,
    required this.passwordSalt,
    required this.biometricEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'normalized_username': normalizedUsername,
      'password_hash': passwordHash,
      'password_salt': passwordSalt,
      'biometric_enabled': biometricEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AppUserModel.fromMap(Map<String, dynamic> map) {
    return AppUserModel(
      id: map['id'] as String,
      username: map['username'] as String,
      normalizedUsername: map['normalized_username'] as String,
      passwordHash: map['password_hash'] as String,
      passwordSalt: map['password_salt'] as String,
      biometricEnabled: (map['biometric_enabled'] as num).toInt() == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
