import 'package:flutter_test/flutter_test.dart';
import 'package:smart_market_list/core/utils/item_name_formatter.dart';
import 'package:smart_market_list/data/models/shopping_item.dart';
import 'package:smart_market_list/data/models/shopping_list.dart';
import 'package:smart_market_list/data/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('uses only the server effective entitlement fields', () {
      final profile = UserProfile.fromMap('user-1', {
        'email': 'user@example.com',
        'familyId': 'family-1',
        'role': 'guest',
        'isPremium': true,
        'purchasePremium': false,
        'planType': 'premium_family_guest',
        'subscriptionManagementUrl': 'https://example.com/subscription',
      });

      expect(profile.uid, 'user-1');
      expect(profile.isPremium, isTrue);
      expect(profile.hasDirectPremium, isFalse);
      expect(profile.role, 'guest');
      expect(profile.planType, 'premium_family_guest');
      expect(
        profile.subscriptionManagementUrl,
        'https://example.com/subscription',
      );
    });

    test('recognizes an active direct Premium purchase', () {
      final profile = UserProfile.fromMap('user-direct', {
        'email': 'direct@example.com',
        'isPremium': true,
        'purchasePremium': true,
        'planType': 'premium_individual',
        'purchaseExpiresAt': DateTime.now().add(const Duration(days: 1)),
      });

      expect(profile.hasDirectPremium, isTrue);
    });

    test('does not let inherited Family Premium sponsor list sharing', () {
      final profile = UserProfile.fromMap('family-guest', {
        'email': 'guest@example.com',
        'isPremium': true,
        'purchasePremium': true,
        'planType': 'premium_family_guest',
        'effectiveExpiresAt': DateTime.now().add(const Duration(days: 1)),
        'purchaseExpiresAt': DateTime.now().subtract(
          const Duration(minutes: 1),
        ),
      });

      expect(profile.isPremium, isTrue);
      expect(profile.hasDirectPremium, isFalse);
    });

    test('revokes a Family workspace while preserving a direct plan', () {
      final profile = UserProfile.fromMap('family-guest-direct', {
        'email': 'guest-direct@example.com',
        'role': 'guest',
        'isPremium': true,
        'purchasePremium': true,
        'planType': 'premium_individual',
        'effectiveExpiresAt': DateTime.now().add(const Duration(days: 1)),
        'purchaseExpiresAt': DateTime.now().add(const Duration(days: 1)),
        'familyAccessExpiresAt': DateTime.now().subtract(
          const Duration(minutes: 1),
        ),
      });

      expect(profile.isPremium, isTrue);
      expect(profile.hasDirectPremium, isTrue);
      expect(profile.hasActiveFamilyWorkspace, isFalse);
      expect(profile.canSyncCurrentWorkspace, isFalse);
    });

    test('defaults a missing entitlement to Free', () {
      final profile = UserProfile.fromMap('user-2', {
        'email': 'free@example.com',
      });

      expect(profile.isPremium, isFalse);
      expect(profile.planType, 'free');
    });

    test('stops exposing Premium after the effective expiration', () {
      final profile = UserProfile.fromMap('user-3', {
        'email': 'expired@example.com',
        'isPremium': true,
        'planType': 'premium_individual',
        'effectiveExpiresAt': DateTime.now().subtract(
          const Duration(minutes: 1),
        ),
      });

      expect(profile.isPremium, isFalse);
    });
  });

  test('ShoppingList preserves sharing metadata in serialization', () {
    final list = ShoppingList(
      id: 'list-1',
      name: 'Mercado',
      familyId: 'family-1',
      ownerId: 'owner-1',
      members: const ['owner-1', 'guest-1'],
      items: [
        ShoppingItem(
          name: 'Arroz',
          quantity: '2 un',
          unitQuantity: 2,
          price: 10,
        ),
      ],
    );

    final restored = ShoppingList.fromMap(list.toMap());

    expect(restored.familyId, 'family-1');
    expect(restored.ownerId, 'owner-1');
    expect(restored.members, containsAll(['owner-1', 'guest-1']));
    expect(restored.items.single.name, 'Arroz');
  });

  test('formats a new item with an uppercase first letter', () {
    expect(formatItemName('  tomate  '), 'Tomate');
    expect(formatItemName('óleo   de coco'), 'Óleo de coco');
  });

  test('ShoppingItem preserves price history metadata in serialization', () {
    final historyUpdatedAt = DateTime.utc(2026, 7, 24, 12);
    final item = ShoppingItem(
      name: 'Tomate',
      price: 8.75,
      historyUpdatedAt: historyUpdatedAt,
    );

    final restored = ShoppingItem.fromMap(item.toMap());

    expect(restored.price, 8.75);
    expect(
      restored.historyUpdatedAt?.millisecondsSinceEpoch,
      historyUpdatedAt.millisecondsSinceEpoch,
    );
    expect(
      restored.historyTimestamp.millisecondsSinceEpoch,
      historyUpdatedAt.millisecondsSinceEpoch,
    );
  });

  test('ShoppingList can detach a cloud family without losing its items', () {
    final list = ShoppingList(
      name: 'Mercado',
      familyId: 'family-1',
      items: [ShoppingItem(name: 'Tomate', price: 8.75)],
    );

    final localOnly = list.copyWith(clearFamilyId: true);

    expect(localOnly.familyId, isNull);
    expect(localOnly.items.single.price, 8.75);
  });
}
