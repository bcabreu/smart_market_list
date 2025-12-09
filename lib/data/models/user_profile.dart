enum PlanType {
  free,
  premium_individual,
  premium_family,
}

class UserProfile {
  final String uid;
  final String email;
  final String? name;
  final String? familyId;
  final String? role; // 'owner' or 'guest'
  final bool isPremium;
  final String planType; // 'free', 'individual', 'family'

  UserProfile({
    required this.uid,
    required this.email,
    this.name,
    this.familyId,
    this.role,
    this.isPremium = false,
    this.planType = 'free',
  });

  bool get isFamilyPlan => planType == 'family';
  
  int get maxFamilyMembers {
    if (planType == 'family') return 1; // 1 guest
    return 0;
  }

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'],
      familyId: data['familyId'],
      role: data['role'],
      isPremium: data['isPremium'] ?? false,
      planType: data['planType'] ?? 'free',
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'familyId': familyId,
      'role': role,
      'isPremium': isPremium,
      'planType': planType,
    };
  }
  
  UserProfile copyWith({
    String? name,
    String? familyId,
    String? role,
    bool? isPremium,
    String? planType,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      name: name ?? this.name,
      familyId: familyId ?? this.familyId,
      role: role ?? this.role,
      isPremium: isPremium ?? this.isPremium,
      planType: planType ?? this.planType,
    );
  }
}
