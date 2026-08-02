import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/core/services/backend_service.dart';
import 'package:smart_market_list/core/services/sharing_service.dart';

final sharingServiceProvider = Provider<SharingService>((ref) {
  final backendService = ref.watch(backendServiceProvider);
  return SharingService(backendService);
});
