import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/core/services/firestore_service.dart';
import 'package:smart_market_list/core/services/auth_service.dart';
import 'package:smart_market_list/providers/auth_provider.dart';
import 'package:rxdart/rxdart.dart';

final familyInvitationServiceProvider = Provider<FamilyInvitationService>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final authService = ref.watch(authServiceProvider);
  return FamilyInvitationService(firestoreService, authService);
});

class FamilyInvitationService {
  final FirestoreService _firestoreService;
  final AuthService _authService;

  FamilyInvitationService(this._firestoreService, this._authService);

  // Send an invitation to a guest email
  Future<void> inviteMember(String guestEmail) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) throw Exception('User not logged in');
    
    // Check if current user is already in a family (and is guest)
    // Ideally user role checks happen here. For now, we assume UI protects this.
    
    await _firestoreService.sendInvitation(currentUser.uid, guestEmail);
  }

  // Check if the currently logged-in user has any pending invitations
  Future<void> checkAndAcceptPendingInvites() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final email = currentUser.email;
    if (email == null) return;

    // 1. Get Invitations
    final snapshot = await _firestoreService.checkPendingInvitations(email);
    
    if (snapshot.docs.isNotEmpty) {
      // Auto-accept the first one for MVP simplicity
      // In a real app, we might show a dialog "You have been invited by..."
      final inviteDoc = snapshot.docs.first;
      final inviteData = inviteDoc.data() as Map<String, dynamic>;
      final ownerUid = inviteData['fromUid'];
      
      await _firestoreService.acceptInvitation(inviteDoc.id, currentUser.uid, ownerUid);
    }
  }

  // Remove a member from the family
  Future<void> removeMember(String memberUid) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;
    
    // We need to know the family ID. 
    // Ideally this service should have access to UserProfile or fetch it.
    // For now, let's fetch it via FirestoreService using current UID
    final userData = await _firestoreService.getUserData(currentUser.uid);
    final familyId = userData?['familyId'];
    
    if (familyId != null) {
      await _firestoreService.removeFamilyMember(familyId, memberUid);
    }
  }

  Stream<List<Map<String, dynamic>>> getFamilyMembers() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return Stream.value([]);
    
    // This is tricky because we need the familyId first.
    // Better to lean on UserProfileProvider in the UI for family ID 
    // and then call FirestoreService directly or via a specific stream here.
    // But let's try to keep it simple: Service assumes active user context.
    
    return _firestoreService.getUserStream(currentUser.uid).switchMap((userData) {
      final familyId = userData?['familyId'];
      if (familyId == null) return Stream.value([]);
      return _firestoreService.getFamilyMembers(familyId);
    });
  }

  Stream<List<Map<String, dynamic>>> getSentInvitations() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return Stream.value([]);
    
    return _firestoreService.getSentInvitations(currentUser.uid).map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add doc ID for cancellation
        return data;
      }).toList();
    });
  }

  Future<void> cancelInvitation(String inviteId) async {
    await _firestoreService.cancelInvitation(inviteId);
  }
}
