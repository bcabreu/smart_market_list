import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final backendServiceProvider = Provider<BackendService>((ref) {
  return BackendService();
});

class BackendService {
  BackendService({FirebaseFunctions? functions})
    : _functions =
          functions ??
          FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> _call(
    String name, [
    Map<String, dynamic>? parameters,
  ]) async {
    final result = await _functions.httpsCallable(name).call(parameters);
    final data = result.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return const {};
  }

  Future<void> ensureUserWorkspace() async {
    await _call('ensureUserWorkspace');
  }

  Future<Map<String, dynamic>> syncRevenueCatStatus() {
    return _call('syncRevenueCatStatus');
  }

  Future<Map<String, dynamic>> createFamilyInvite() {
    return _call('createFamilyInvite');
  }

  Future<void> joinFamily({
    required String inviteId,
    required String token,
  }) async {
    await _call('joinFamily', {'inviteId': inviteId, 'token': token});
  }

  Future<void> leaveFamily() async {
    await _call('leaveFamily');
  }

  Future<void> removeFamilyMember(String memberUid) async {
    await _call('removeFamilyMember', {'memberUid': memberUid});
  }

  Future<Map<String, dynamic>> createListInvite({
    required String familyId,
    required String listId,
  }) {
    return _call('createListInvite', {'familyId': familyId, 'listId': listId});
  }

  Future<void> joinSharedList({
    required String inviteId,
    required String token,
  }) async {
    await _call('joinSharedList', {'inviteId': inviteId, 'token': token});
  }

  Future<void> removeListMember({
    required String familyId,
    required String listId,
    String? memberUid,
  }) async {
    await _call('removeListMember', {
      'familyId': familyId,
      'listId': listId,
      if (memberUid != null) 'memberUid': memberUid,
    });
  }

  Future<void> deleteAccount() async {
    await _call('deleteAccount');
  }
}
