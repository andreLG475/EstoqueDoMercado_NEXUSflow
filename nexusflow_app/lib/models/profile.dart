import 'role.dart';

class Profile {
  Profile({required this.id, required this.name, required this.email, required this.role});

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: Role.fromString(json['role'] as String),
      );

  final String id;
  final String name;
  final String email;
  final Role role;
}
