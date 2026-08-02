import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:smart_market_list/core/services/firestore_service.dart';
import 'package:smart_market_list/data/models/user_profile.dart';
import 'package:smart_market_list/providers/auth_provider.dart';

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);

      return firestoreService.getUserStream(user.uid).switchMap((userData) {
        if (userData == null) return Stream<UserProfile?>.value(null);
        final profile = UserProfile.fromMap(user.uid, userData);
        final now = DateTime.now();
        final expirations = {
          profile.effectiveExpiresAt,
          profile.purchaseExpiresAt,
          profile.familyAccessExpiresAt,
        }.whereType<DateTime>().where((date) => date.isAfter(now));
        return Rx.merge<UserProfile?>([
          Stream.value(profile),
          for (final expiration in expirations)
            TimerStream(
              profile.copyWith(),
              expiration.difference(now) + const Duration(milliseconds: 50),
            ),
        ]);
      });
    },
    loading: () => Stream.value(null),
    error: (_, _) => Stream.value(null),
  );
});

final isFamilyGuestProvider = Provider<bool>((ref) {
  final userProfile = ref.watch(userProfileProvider).asData?.value;
  return userProfile?.role == 'guest';
});
