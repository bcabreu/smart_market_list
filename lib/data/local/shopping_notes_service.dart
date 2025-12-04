import 'package:hive_flutter/hive_flutter.dart';
import '../models/shopping_note.dart';

class ShoppingNotesService {
  final Box<ShoppingNote> _box;

  ShoppingNotesService(this._box);

  List<ShoppingNote> getAllNotes() {
    return _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> createNote(ShoppingNote note) async {
    await _box.put(note.id, note);
  }

  Future<void> deleteNote(String id) async {
    await _box.delete(id);
  }
}
