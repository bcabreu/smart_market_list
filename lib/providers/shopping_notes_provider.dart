import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/local/shopping_notes_service.dart';
import '../data/models/shopping_note.dart';
import '../core/services/firestore_service.dart';
final shoppingNotesBoxProvider = Provider<Box<ShoppingNote>>((ref) {
  return Hive.box<ShoppingNote>('shopping_notes');
});

final shoppingNotesServiceProvider = Provider<ShoppingNotesService>((ref) {
  final box = ref.watch(shoppingNotesBoxProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ShoppingNotesService(box, firestoreService);
});

final shoppingNotesProvider = StreamProvider<List<ShoppingNote>>((ref) {
  final box = ref.watch(shoppingNotesBoxProvider);
  return box.watch().map((event) {
    final notes = box.values.toList();
    notes.sort((a, b) => b.date.compareTo(a.date));
    return notes;
  }).startWith(box.values.toList()..sort((a, b) => b.date.compareTo(a.date)));
});
