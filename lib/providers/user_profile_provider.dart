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

        // If Guest, check Owner's status
        // We need the ownerId. It's stored in 'connectedTo' or we can fetch family doc.
        // Assuming 'connectedTo' is the owner UID as per accepting logic.
        final ownerId = userData['connectedTo'] as String?;
        
        if (ownerId == null) return Stream.value(profile);

        // Stream Owner's data to check for premium
        return firestoreService.getUserStream(ownerId).map((ownerData) {
           final ownerIsPremium = ownerData?['isPremium'] == true;
           
           // If owner is premium, guest is premium.
           if (ownerIsPremium) {
             return UserProfile(
               uid: profile.uid,
               email: profile.email,
               name: profile.name,
               familyId: profile.familyId,
               role: profile.role,
               isPremium: true, // Inherited
               planType: profile.planType, // Keep plan type (e.g. premium_family_guest)
             );
           } else {
             // If Owner lost premium, Guest MUST lose it too.
             // Force override to false, regardless of what's in Firestore for the guest.
             return UserProfile(
               uid: profile.uid,
               email: profile.email,
               name: profile.name,
               familyId: profile.familyId,
               role: profile.role,
               isPremium: false, // Enforce False
               planType: 'free', // Enforce Free
             );
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
