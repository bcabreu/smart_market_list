import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/auth_service.dart';
import '../core/services/firestore_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return AuthService(firestoreService);
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider); // Rebuild when auth state changes
  return ref.watch(authServiceProvider).currentUser;
});
