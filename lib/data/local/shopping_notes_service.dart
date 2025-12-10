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
        // 1. ADD / UPDATE: Sync INCOMING notes from Cloud -> Local
        final cloudNoteIds = <String>{};
        for (var note in cloudNotes) {
          cloudNoteIds.add(note.id);
          await _box.put(note.id, note);
        }

        // 2. DELETE: Sync REMOVALS from Cloud -> Local
        // If a local note is NOT present in the incoming cloud list, it means it was deleted remotely.
        // We must delete it locally to stay in sync.
        final allLocalNotes = _box.values.toList();
        for (var localNote in allLocalNotes) {
          if (!cloudNoteIds.contains(localNote.id)) {
             print('🗑️ Sync Deletion: Removing local note ${localNote.id} (not in cloud)');
             await _box.delete(localNote.id);
          }
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
