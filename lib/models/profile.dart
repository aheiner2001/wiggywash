enum UserRole { employee, manager }

extension UserRoleLabel on UserRole {
  String get label =>
      this == UserRole.manager ? 'Manager' : 'Employee';
  String get storageValue => name;
}

class Profile {
  const Profile({required this.name, required this.role});

  final String name;
  final UserRole role;

  Map<String, dynamic> toJson() => {'name': name, 'role': role.name};

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        name: json['name'] as String? ?? '',
        role: UserRole.values.firstWhere(
          (r) => r.name == json['role'],
          orElse: () => UserRole.employee,
        ),
      );
}
