import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/shopping_note.dart';
import '../../core/services/firestore_service.dart';

class ShoppingNotesService {
  final Box<ShoppingNote> _box;
  final FirestoreService? _firestoreService;
  
  String? _currentFamilyId;
  StreamSubscription? _cloudSubscription;

  ShoppingNotesService(this._box, [this._firestoreService]);

  Future<void> startSync(String familyId) async {
    if (_currentFamilyId == familyId) return;
    _currentFamilyId = familyId;
    _cloudSubscription?.cancel();

    // 1. Upload Local Notes to Cloud
    if (_firestoreService != null) {
      final localNotes = getAllNotes();
      for (var note in localNotes) {
        await _syncToCloud(note);
      }
    }

    // 2. Listen for Cloud Updates
    if (_firestoreService != null) {
      _cloudSubscription = _firestoreService!.getFamilyNotes(familyId).listen((cloudNotes) async {
        for (var note in cloudNotes) {
          await _box.put(note.id, note);
        }
      });
    }
  }

  void stopSync() {
    _cloudSubscription?.cancel();
    _currentFamilyId = null;
  }

  List<ShoppingNote> getAllNotes() {
    return _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> createNote(ShoppingNote note) async {
    await _box.put(note.id, note);
    await _syncToCloud(note);
  }

  Future<void> deleteNote(String id) async {
    await _box.delete(id);
    if (_currentFamilyId != null && _firestoreService != null) {
      await _firestoreService!.deleteNote(_currentFamilyId!, id);
    }
  }
  
  Future<void> _syncToCloud(ShoppingNote note) async {
    if (_currentFamilyId != null && _firestoreService != null) {
      await _firestoreService!.syncNote(_currentFamilyId!, note);
    }
  }

  Future<void> deleteAllNotes() async {
    await _box.clear();
  }
}
