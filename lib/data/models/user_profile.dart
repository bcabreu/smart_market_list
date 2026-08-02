import 'package:cloud_firestore/cloud_firestore.dart';

enum PlanType { free, premium_individual, premium_family }

class UserProfile {
  final String uid;
  final String email;
  final String? name;
  final String? photoUrl; // Added
  final String? familyId;
  final String? role; // 'owner' or 'guest'
  final bool _isPremium;
  final bool _purchasePremium;
  final String planType; // 'free', 'individual', 'family'
  final String? subscriptionManagementUrl;
  final DateTime? effectiveExpiresAt;
  final DateTime? purchaseExpiresAt;
  final DateTime? familyAccessExpiresAt;

  UserProfile({
    required this.uid,
    required this.email,
    this.name,
    this.photoUrl,
    this.familyId,
    this.role,
    bool isPremium = false,
    bool purchasePremium = false,
    this.planType = 'free',
    this.subscriptionManagementUrl,
    this.effectiveExpiresAt,
    this.purchaseExpiresAt,
    this.familyAccessExpiresAt,
  }) : _isPremium = isPremium,
       _purchasePremium = purchasePremium;

  bool get isPremium {
    return _isPremium &&
        (effectiveExpiresAt == null ||
            effectiveExpiresAt!.isAfter(DateTime.now()));
  }

  bool get hasDirectPremium {
    return _purchasePremium &&
        (purchaseExpiresAt == null ||
            purchaseExpiresAt!.isAfter(DateTime.now()));
  }

  bool get hasActiveFamilyWorkspace {
    return role == 'guest' &&
        (familyAccessExpiresAt == null ||
            familyAccessExpiresAt!.isAfter(DateTime.now()));
  }

  bool get canSyncCurrentWorkspace {
    return role == 'guest' ? hasActiveFamilyWorkspace : hasDirectPremium;
  }

  bool get isFamilyPlan => planType.contains('family');

  int get maxFamilyMembers {
    if (planType.contains('family')) return 1; // 1 guest
    return 0;
  }

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'],
      photoUrl: data['photoUrl'],
      familyId: data['familyId'],
      role: data['role'],
      isPremium: data['isPremium'] ?? false,
      purchasePremium: data['purchasePremium'] ?? false,
      planType: data['planType'] ?? 'free',
      subscriptionManagementUrl: data['subscriptionManagementUrl'],
      effectiveExpiresAt: _readDate(data['effectiveExpiresAt']),
      purchaseExpiresAt: _readDate(data['purchaseExpiresAt']),
      familyAccessExpiresAt: _readDate(data['familyAccessExpiresAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'familyId': familyId,
      'role': role,
      'isPremium': _isPremium,
      'purchasePremium': _purchasePremium,
      'planType': planType,
      'subscriptionManagementUrl': subscriptionManagementUrl,
      'effectiveExpiresAt': effectiveExpiresAt,
      'purchaseExpiresAt': purchaseExpiresAt,
      'familyAccessExpiresAt': familyAccessExpiresAt,
    };
  }

  UserProfile copyWith({
    String? name,
    String? photoUrl,
    String? familyId,
    String? role,
    bool? isPremium,
    bool? purchasePremium,
    String? planType,
    String? subscriptionManagementUrl,
    DateTime? effectiveExpiresAt,
    DateTime? purchaseExpiresAt,
    DateTime? familyAccessExpiresAt,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      familyId: familyId ?? this.familyId,
      role: role ?? this.role,
      isPremium: isPremium ?? _isPremium,
      purchasePremium: purchasePremium ?? _purchasePremium,
      planType: planType ?? this.planType,
      subscriptionManagementUrl:
          subscriptionManagementUrl ?? this.subscriptionManagementUrl,
      effectiveExpiresAt: effectiveExpiresAt ?? this.effectiveExpiresAt,
      purchaseExpiresAt: purchaseExpiresAt ?? this.purchaseExpiresAt,
      familyAccessExpiresAt:
          familyAccessExpiresAt ?? this.familyAccessExpiresAt,
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
