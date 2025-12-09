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

  SharingService(this._firestoreService);

  // Initialize Deep Link Listener
  void initDeepLinks(Function(String listId, String familyId) onJoinList) {
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      print('🔗 Deep Link Received: $uri');
      
      // Accept both Custom Scheme (smartmarketlist) and Universal Link (https)
      if (uri.scheme == 'smartmarketlist' || uri.scheme == 'https') {
        // Format: 
        // 1. smartmarketlist://share?listId=...
        // 2. https://smart-market-list-82bf7.web.app/share?listId=...
        
        final listId = uri.queryParameters['listId'];
        final familyId = uri.queryParameters['familyId'];
        
        if (listId != null && familyId != null) {
          onJoinList(listId, familyId);
        }
      }
    }, onError: (err) {
      print('❌ Deep Link Error: $err');
    });
  }

  void dispose() {
    _linkSubscription?.cancel();
  }

  // Share List via WhatsApp/System Share
  Future<void> shareList(ShoppingList list, String familyId) async {
    // Generate Universal Link (Firebase Hosting)
    // Format: https://smart-market-list-82bf7.web.app/share?listId={id}&familyId={fid}&name={name}
    final String deepLink = 'https://smart-market-list-82bf7.web.app/share?listId=${list.id}&familyId=$familyId&name=${Uri.encodeComponent(list.name)}';
    
    // URL real da Play Store (baseado no applicationId que vi no build.gradle)
    // Para iOS, você precisará do ID numérico gerado pelo App Store Connect (ex: 123456789)
    const String androidUrl = 'https://play.google.com/store/apps/details?id=com.kepoweb.smart_market_list'; // Corrigido para kepoweb
    const String iosUrl = 'https://apps.apple.com/app/id6756240280'; // Substitua pelo ID real
    
    final String message = 
        '🛒 *${list.name}*\n'
        'Entre na minha lista de compras compartilhada!\n\n'
        '🔗 *Link de Acesso (Deep Link):*\n$deepLink\n'
        '_(Se não for clicável, copie e cole no Notas)_\n\n'
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
}
