class UserModel {
  final String id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String rol;
  final bool emailVerified;
  final int? edad;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.rol,
    required this.emailVerified,
    this.edad,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    username: json['username'],
    email: json['email'],
    firstName: json['first_name'] ?? '',
    lastName: json['last_name'] ?? '',
    rol: json['rol'] ?? 'visualizador',
    emailVerified: json['email_verified'] ?? false,
    edad: json['edad'],
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'])
        : null,
  );

  bool get esAdmin => rol == 'admin' || rol == 'superadmin';
  bool get esAlmacenista =>
      rol == 'almacenista' || rol == 'admin' || rol == 'superadmin';
  bool get esAuditor =>
      rol == 'auditor' || rol == 'admin' || rol == 'superadmin';
  bool get esSuperAdmin => rol == 'superadmin';
}
