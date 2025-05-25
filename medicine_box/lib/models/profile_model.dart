class Profile {
  final String id;
  final String email;
  final String fullName;
  final String role; // 'patient' | 'caregiver' | 'both'

  Profile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
    id: m['id'] as String,
    email: m['email'] as String,
    fullName: m['full_name'] as String,
    role: m['role'] as String,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'role': role,
  };
}
