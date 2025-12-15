import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/core/services/firestore_service.dart';
import 'package:smart_market_list/data/models/user_profile.dart';
import 'package:smart_market_list/providers/auth_provider.dart';

import 'package:rxdart/rxdart.dart';

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      
      return firestoreService.getUserStream(user.uid).switchMap((userData) {
        if (userData == null) return Stream.value(null);
        
        final profile = UserProfile.fromMap(user.uid, userData);
        
        // If user is Owner or Standalone, return as is
        if (profile.role != 'guest' || profile.familyId == null) {
          return Stream.value(profile);
        }

        // PRIORITY: If I am already premium (Individual purchase or otherwise), 
        // I have access regardless of the owner.
        if (profile.isPremium) {
          return Stream.value(profile);
        }

        // If Guest AND not premium, check Owner's status (Family Inheritance)
        // We need the ownerId. It's stored in 'connectedTo' or we can fetch family doc.
        // Assuming 'connectedTo' is the owner UID as per accepting logic.
        final ownerId = userData['connectedTo'] as String?;
        
        if (ownerId == null) return Stream.value(profile);

        // Stream Owner's data to check for premium inheritance
        return firestoreService.getUserStream(ownerId).map((ownerData) {
           final ownerIsPremium = ownerData?['isPremium'] == true;
           
             if (ownerIsPremium) {
               // Inherit Premium from Owner
               return UserProfile(
                 uid: profile.uid,
                 email: profile.email,
                 name: profile.name,
                 photoUrl: profile.photoUrl, // Keep original photo
                 familyId: profile.familyId,
                 role: profile.role,
                 isPremium: true, // Inherited
                 planType: profile.planType, // Keep original plan type
               );
           } else {
             // Owner is not premium, and I am not premium (checked above).
             // So I am Free.
             return profile;
           }
        });
      });
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

final isFamilyGuestProvider = Provider<bool>((ref) {
  final userProfile = ref.watch(userProfileProvider).asData?.value;
  return userProfile?.role == 'guest';
});


