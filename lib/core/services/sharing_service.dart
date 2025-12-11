import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_market_list/core/services/firestore_service.dart';
import 'package:smart_market_list/data/models/shopping_list.dart';

class SharingService {
  final FirestoreService _firestoreService;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription? _linkSubscription;
  
  // Store pending invite data for when user logs in
  static String? pendingListId;
  static String? pendingFamilyId;
  static String? pendingInviteCode;


  SharingService(this._firestoreService);

  // Initialize Deep Link Listener
  void initDeepLinks({
    required Function(String listId, String familyId) onJoinList,
    required Function(String familyId, String? inviteCode) onJoinFamily,
    required Function(String recipeId) onOpenRecipe, // New Callback
  }) {
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      print('🔗 Deep Link Received: $uri');
      
      if (uri.scheme == 'smartmarketlist' || uri.scheme == 'https') {
        final listId = uri.queryParameters['listId'];
        final familyId = uri.queryParameters['familyId'];
        final action = uri.queryParameters['action'];
        final inviteCode = uri.queryParameters['inviteCode'];
        final recipeId = uri.queryParameters['recipeId']; // New Parameter
        
        // Case 0: Open Recipe (Viral Share)
        if (recipeId != null) {
          onOpenRecipe(recipeId);
          return;
        }

        // Case 1: Join Family
        if (action == 'join_family' && familyId != null) {
          onJoinFamily(familyId, inviteCode);
          return;
        }

        // Case 2: Join List (Legacy/Standard)
        if (listId != null && familyId != null) {
          if (listId == 'invite' || action == 'join_family') {
             onJoinFamily(familyId, inviteCode);
          } else {
             onJoinList(listId, familyId);
          }
        }
      }
    }, onError: (err) {
      print('❌ Deep Link Error: $err');
    });
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
  
  // Share Recipe (Viral)
  Future<void> shareRecipe({
    required String recipeId,
    required String recipeName,
    required String shareMessage, // New localized param
    required String viewRecipeLabel, // New localized param
  }) async {
    // We add listId=recipe to ensure the link is matched by the OS/Web as a valid app link
    // based on previous successful patterns (ID: 7927).
    final String deepLink = 'https://smart-market-list-82bf7.web.app/share?listId=recipe&recipeId=$recipeId';
    
    const String androidUrl = 'https://play.google.com/store/apps/details?id=com.kepoweb.smart_market_list';
    const String iosUrl = 'https://apps.apple.com/app/id6756240280';
    
    final String message = 
        '$shareMessage\n\n'
        '$viewRecipeLabel: $deepLink\n\n'
        'Ou baixe o app / Or get the app:\n'
        '🤖 Android: $androidUrl\n'
        '🍎 iOS: $iosUrl';

    await Share.share(message);
  }

  // Share List via WhatsApp/System Share
  Future<void> shareList({
    required ShoppingList list,
    required String familyId,
    required String title,
    required String messageBody,
    required String accessLinkLabel,
    required String installAppAdvice,
    required String androidLabel,
    required String iosLabel,
  }) async {
    final String deepLink = 'https://smart-market-list-82bf7.web.app/share?listId=${list.id}&familyId=$familyId&name=${Uri.encodeComponent(list.name)}';
    
    // Construct full message using localized parts
    // Note: We use the same structure as family share for consistency, or keep it custom.
    // The previous structure was: Title \n Link Labels \n Link \n Advice \n Store Links
    
    const String androidUrl = 'https://play.google.com/store/apps/details?id=com.kepoweb.smart_market_list';
    const String iosUrl = 'https://apps.apple.com/app/id6756240280';
    
    final String fullMessage = 
        '$title\n\n'
        '$messageBody\n\n'
        '$accessLinkLabel\n$deepLink\n'
        '$installAppAdvice\n\n'
        '$androidLabel $androidUrl\n'
        '$iosLabel $iosUrl';

    await Share.share(fullMessage);
  }

  // Share Family Access
  // Share Family Access
  Future<void> shareFamilyAccess({
    required String familyId,
    required String title,
    required String messageBody,
    required String accessLinkLabel,
    required String installAppAdvice,
    required String androidLabel,
    required String iosLabel,
  }) async {
    // We revert to 'ensureInviteCode' to keep the link STABLE.
    final inviteCode = await _firestoreService.ensureInviteCode(familyId);
    
    final String deepLink = 'https://smart-market-list-82bf7.web.app/share?listId=invite&familyId=$familyId&action=join_family&inviteCode=$inviteCode';
    
    const String androidUrl = 'https://play.google.com/store/apps/details?id=com.kepoweb.smart_market_list';
    const String iosUrl = 'https://apps.apple.com/app/id6756240280';
    
    final String fullMessage = 
        '$title\n\n'
        '$messageBody\n\n'
        '$accessLinkLabel\n$deepLink\n'
        '$installAppAdvice\n\n'
        '$androidLabel $androidUrl\n'
        '$iosLabel $iosUrl';

    await Share.share(fullMessage);
  }

  // Legacy Share Message for Lists
  Future<void> _shareMessage(String title, String deepLink) async {
    const String androidUrl = 'https://play.google.com/store/apps/details?id=com.kepoweb.smart_market_list';
    const String iosUrl = 'https://apps.apple.com/app/id6756240280';
    
    final String message = 
        '$title\n\n'
        '🔗 *Link de Acesso:*\n$deepLink\n'
        '_(Se não funcionar, instale o app primeiro)_\n\n'
        '🤖 *Android:* $androidUrl\n'
        '🍎 *iOS:* $iosUrl';

    await Share.share(message);
  }

  // Join List Logic
  Future<void> joinList(String listId, String familyId, String userId) async {
    try {
      await _firestoreService.addMemberToList(familyId, listId, userId);
      print('✅ Joined list $listId via Deep Link');
    } catch (e) {
      print('❌ Error joining list: $e');
      rethrow;
    }
  }

  // Join Family Logic
  Future<void> joinFamily(String familyId, String userId, {String? inviteCode}) async {
    try {
      await _firestoreService.joinFamily(familyId, userId, inviteCode: inviteCode);
      print('✅ Joined Family $familyId via Deep Link');
    } catch (e) {
      print('❌ Error joining family: $e');
      rethrow;
    }
  }
}
