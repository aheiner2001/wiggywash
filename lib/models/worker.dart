/// A team member the manager adds to the roster. Employees pick their name
/// from this list when signing in. An optional [pin] requires a short code.
class Worker {
  const Worker({required this.id, required this.name, this.pin});

  final String id;
  final String name;

  /// Optional entry code. When set, the employee must type it to sign in.
  final String? pin;

  bool get requiresPin => pin != null && pin!.trim().isNotEmpty;

  bool verifyPin(String input) =>
      pin!.trim().toLowerCase() == input.trim().toLowerCase();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (pin != null && pin!.isNotEmpty) 'pin': pin,
      };

  factory Worker.fromJson(Map<String, dynamic> json) {
    final rawPin = json['pin'] as String?;
    return Worker(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      pin: rawPin != null && rawPin.trim().isNotEmpty ? rawPin.trim() : null,
    );
  }

  Worker copyWith({String? name, String? pin, bool clearPin = false}) => Worker(
        id: id,
        name: name ?? this.name,
        pin: clearPin ? null : (pin ?? this.pin),
      );
}
