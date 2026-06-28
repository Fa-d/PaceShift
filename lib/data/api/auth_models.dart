/// Authenticated user as returned by the backend.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.proEntitled = false,
  });

  final String id;
  final String email;
  final String? displayName;
  final bool proEntitled;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String?,
        proEntitled: json['proEntitled'] as bool? ?? false,
      );
}
