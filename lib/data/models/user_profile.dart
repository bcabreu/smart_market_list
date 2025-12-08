class UserProfile {
  final String uid;
  final String email;
  final String? name;
  final String? familyId;
  final String? role; // 'owner' or 'guest'
  final bool isPremium;

  UserProfile({
    required this.uid,
    required this.email,
    this.name,
    this.familyId,
    this.role,
    this.isPremium = false,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'],
      familyId: data['familyId'],
      role: data['role'],
      isPremium: data['isPremium'] ?? false, // Or derived from logic
    );
  }
}
