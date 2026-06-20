/// A team member the manager adds to the roster. Employees pick their name
/// from this list when signing in.
class Worker {
  const Worker({required this.id, required this.name});

  final String id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory Worker.fromJson(Map<String, dynamic> json) => Worker(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
      );
}
