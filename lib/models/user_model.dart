class AuthUser {
  final int id;
  final String username;
  final String name;

  const AuthUser({
    required this.id,
    required this.username,
    required this.name,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] ?? 0,
    username: json['username'] ?? '',
    name: json['name'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'name': name,
  };
}

class AuthResult {
  final String token;
  final AuthUser user;

  const AuthResult({required this.token, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
    token: json['token'] ?? '',
    user: AuthUser.fromJson(json['user'] ?? {}),
  );
}
