import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/providers/user_provider.dart';

final iapServiceProvider = Provider<IAPService>((ref) {
  return IAPService(ref);
});

class IAPService {
  final Ref _ref;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  IAPService(this._ref) {
    print('🛒 IAP Service Initialized');
    _initializeStream();
  }

  void _initializeStream() {
    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription?.cancel();
    }, onError: (error) {
      print('Erro no stream de compras: $error');
    });
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Pending...
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          print('Erro na compra: ${purchaseDetails.error}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          verifyPurchase(purchaseDetails);
        }
        
        if (purchaseDetails.pendingCompletePurchase) {
          _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> initialize() async {
    final available = await _iap.isAvailable();
    if (!available) {
      print('Loja não disponível');
      return;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      await _iap.restorePurchases();
      return true;
    } catch (e) {
      print('Erro ao restaurar compras: $e');
      return false;
    }
  }

  // Verification Logic (Simplified for now)
  void verifyPurchase(PurchaseDetails purchase) {
     print('✅ Compra verificada/restaurada: ${purchase.productID} (${purchase.status})');
     if (purchase.status == PurchaseStatus.purchased || 
         purchase.status == PurchaseStatus.restored) {
       _ref.read(premiumSinceProvider.notifier).setPremium(true);
     }
  }
  
  void dispose() {
    _subscription?.cancel();
  }
}
