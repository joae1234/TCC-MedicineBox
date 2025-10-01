class Profile {
  final String id;
  final String email;
  final String fullName;
  final String role; // 'patient' | 'caregiver' | 'both'
  final String phoneNumber;
  final String? caregiverId;

  Profile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.phoneNumber,
    required this.caregiverId,
  });

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
    id: m['id'] as String,
    email: m['email'] as String,
    fullName: m['full_name'] as String,
    role: m['role'] as String,
    phoneNumber: m['phone_number'] as String,
    caregiverId: m['caregiver_id'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'role': role,
    'phone_number': phoneNumber,
    'caregiver_id': caregiverId,  
  };
}
