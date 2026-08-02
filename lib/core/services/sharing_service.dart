import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_market_list/core/services/backend_service.dart';
import 'package:smart_market_list/data/models/shopping_list.dart';

class SharingService {
  SharingService(this._backendService);

  final BackendService _backendService;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  static String? pendingAction;
  static String? pendingListId;
  static String? pendingFamilyId;
  static String? pendingInviteId;
  static String? pendingToken;

  static void clearPendingInvite() {
    pendingAction = null;
    pendingListId = null;
    pendingFamilyId = null;
    pendingInviteId = null;
    pendingToken = null;
  }

  void initDeepLinks({
    required void Function(
      String listId,
      String familyId,
      String inviteId,
      String token,
    )
    onJoinList,
    required void Function(String inviteId, String token) onJoinFamily,
    required void Function(String recipeId) onOpenRecipe,
  }) async {
    _linkSubscription?.cancel();
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _handleDeepLink(uri, onJoinList, onJoinFamily, onOpenRecipe),
      onError: (Object error) {
        print('Deep link error: $error');
      },
    );

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri, onJoinList, onJoinFamily, onOpenRecipe);
      }
    } catch (error) {
      print('Initial deep link error: $error');
    }
  }

  void _handleDeepLink(
    Uri uri,
    void Function(String, String, String, String) onJoinList,
    void Function(String, String) onJoinFamily,
    void Function(String) onOpenRecipe,
  ) {
    if (uri.scheme != 'smartmarketlist' && uri.scheme != 'https') return;

    final recipeId = uri.queryParameters['recipeId'];
    if (recipeId != null && recipeId.isNotEmpty) {
      onOpenRecipe(recipeId);
      return;
    }

    final action = uri.queryParameters['action'];
    final inviteId = uri.queryParameters['inviteId'];
    final token = uri.queryParameters['token'];
    if (inviteId == null || token == null) {
      // Legacy links intentionally no longer grant access.
      return;
    }

    if (action == 'join_family') {
      onJoinFamily(inviteId, token);
      return;
    }

    final listId = uri.queryParameters['listId'];
    final familyId = uri.queryParameters['familyId'];
    if (action == 'join_list' && listId != null && familyId != null) {
      onJoinList(listId, familyId, inviteId, token);
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }

  Future<void> shareRecipe({
    required String recipeId,
    required String recipeName,
    required String shareMessage,
    required String viewRecipeLabel,
  }) async {
    final deepLink = Uri.https('smart-market-list-82bf7.web.app', '/share', {
      'recipeId': recipeId,
    });
    const androidUrl =
        'https://play.google.com/store/apps/details?id=com.kepoweb.smartmarketlist';
    const iosUrl = 'https://apps.apple.com/app/id6756240280';

    await SharePlus.instance.share(
      ShareParams(
        text:
            '$shareMessage\n\n'
            '$viewRecipeLabel: $deepLink\n\n'
            'Ou baixe o app / Or get the app:\n'
            '🤖 Android: $androidUrl\n'
            '🍎 iOS: $iosUrl',
      ),
    );
  }

  Future<void> shareList({
    required ShoppingList list,
    required String familyId,
    required String title,
    required String messageBody,
    required String accessLinkLabel,
  }) async {
    final invite = await _backendService.createListInvite(
      familyId: familyId,
      listId: list.id,
    );
    final deepLink = Uri.https('smart-market-list-82bf7.web.app', '/share', {
      'action': 'join_list',
      'listId': list.id,
      'familyId': familyId,
      'inviteId': invite['inviteId'] as String,
      'token': invite['token'] as String,
    });

    await SharePlus.instance.share(
      ShareParams(
        text: '$title\n\n$messageBody\n\n$accessLinkLabel\n$deepLink',
      ),
    );
  }

  Future<void> shareFamilyAccess({
    required String familyId,
    required String title,
    required String messageBody,
    required String accessLinkLabel,
    required String installAppAdvice,
    required String androidLabel,
    required String iosLabel,
  }) async {
    final invite = await _backendService.createFamilyInvite();
    final deepLink = Uri.https('smart-market-list-82bf7.web.app', '/share', {
      'action': 'join_family',
      'familyId': invite['familyId'] as String,
      'inviteId': invite['inviteId'] as String,
      'token': invite['token'] as String,
    });
    const androidUrl =
        'https://play.google.com/store/apps/details?id=com.kepoweb.smartmarketlist';
    const iosUrl = 'https://apps.apple.com/app/id6756240280';

    await SharePlus.instance.share(
      ShareParams(
        text:
            '$title\n\n$messageBody\n\n$accessLinkLabel\n$deepLink\n'
            '$installAppAdvice\n\n'
            '$androidLabel $androidUrl\n'
            '$iosLabel $iosUrl',
      ),
    );
  }

  Future<void> joinList({required String inviteId, required String token}) {
    return _backendService.joinSharedList(inviteId: inviteId, token: token);
  }

  Future<void> joinFamily({required String inviteId, required String token}) {
    return _backendService.joinFamily(inviteId: inviteId, token: token);
  }
}
