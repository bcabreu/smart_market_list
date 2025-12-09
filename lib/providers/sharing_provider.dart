import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/core/services/firestore_service.dart';
import 'package:smart_market_list/core/services/sharing_service.dart';

final sharingServiceProvider = Provider<SharingService>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return SharingService(firestoreService);
});
