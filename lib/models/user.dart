import 'json_utils.dart';

class User {
  const User({required this.email, required this.fullName});

  final String email;
  final String fullName;

  /// Primer nombre para saludos ("Ana Quispe" -> "Ana").
  String get firstName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? '' : parts.first;
  }

  /// Iniciales para el avatar ("Ana Quispe" -> "AQ").
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return email.isNotEmpty ? email[0].toUpperCase() : '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  factory User.fromJson(Map<String, dynamic> json) =>
      User(email: readString(json['email'] ?? json['user_email']), fullName: readString(json['full_name']));

  Map<String, dynamic> toJson() => {'email': email, 'full_name': fullName};
}

/// Sesión autenticada: token JWT + su vencimiento + usuario.
class AuthSession {
  const AuthSession({required this.token, required this.user, this.expiresAt});

  final String token;
  final User user;
  final DateTime? expiresAt;

  bool isExpired([DateTime? now]) {
    final exp = expiresAt;
    if (exp == null) return false;
    return !(now ?? DateTime.now()).isBefore(exp);
  }

  AuthSession copyWith({User? user}) => AuthSession(token: token, user: user ?? this.user, expiresAt: expiresAt);

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    token: readString(json['token']),
    user: User.fromJson(asMap(json['user'])),
    expiresAt: readDate(json['expires_at']),
  );

  Map<String, dynamic> toJson() => {
    'token': token,
    'user': user.toJson(),
    'expires_at': expiresAt?.toUtc().toIso8601String(),
  };
}
