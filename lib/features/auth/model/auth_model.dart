// ── Login Request ─────────────────────────────────────────────────────────────
// POST /auth/login
// Body: { "email": "user@example.com", "password": "secret" }
class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

// ── Register Request ──────────────────────────────────────────────────────────
// POST /auth/register
// Body: { "name": "John", "email": "user@example.com", "password": "secret" }
class RegisterRequest {
  final String name;
  final String email;
  final String password;

  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
      };
}

// ── Auth Response ─────────────────────────────────────────────────────────────
// Response: { "token": "jwt...", "refreshToken": "rt..." }
class AuthResponse {
  final String token;
  final String? refreshToken;

  const AuthResponse({required this.token, this.refreshToken});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        token: json['token'] as String,
        refreshToken: json['refreshToken'] as String?,
      );
}