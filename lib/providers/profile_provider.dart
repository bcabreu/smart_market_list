import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

class ProfileImageNotifier extends StateNotifier<String?> {
  ProfileImageNotifier() : super(null) {
    _loadProfileImage();
  }

  static const _key = 'profile_image_path';

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(_key);
    if (savedPath != null) {
      if (savedPath.startsWith('http')) {
        // It's a network URL
        state = savedPath;
      } else if (await File(savedPath).exists()) {
        // It's a local file
         state = savedPath;
      } else {
         // Cleanup if file no longer exists
         await prefs.remove(_key);
      }
    }
  }

  Future<void> setNetworkImage(String url) async {
    state = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, url);
  }

  Future<void> setImage(String sourcePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final name = 'profile_picture_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newPath = path.join(directory.path, name);

      // Copy the file to the app's document directory
      final savedFile = await File(sourcePath).copy(newPath);
      
      // Delete old image if it exists to save space (and is not a URL)
      if (state != null && !state!.startsWith('http')) {
        final oldFile = File(state!);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }

      state = savedFile.path;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, savedFile.path);
    } catch (e) {
      // Handle error (optional: log it)
      print('Error saving profile image: $e');
    }
  }
}

final profileImageProvider = StateNotifierProvider<ProfileImageNotifier, String?>((ref) {
  return ProfileImageNotifier();
});

final isEditingProfileNameProvider = StateProvider<bool>((ref) => false);
