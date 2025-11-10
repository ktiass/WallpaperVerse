import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../utils/logger.dart';

part 'storage_service.g.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get download URL
  Future<String> getDownloadUrl(String path) async {
    try {
      return await _storage.ref(path).getDownloadURL();
    } catch (e) {
      AppLogger.error('Get download URL error', error: e);
      rethrow;
    }
  }

  // Download file to local storage
  Future<File> downloadFile(String storagePath, String fileName) async {
    try {
      final ref = _storage.ref(storagePath);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');

      await ref.writeToFile(file);
      return file;
    } catch (e) {
      AppLogger.error('Download file error', error: e);
      rethrow;
    }
  }

  // Download and save to gallery
  Future<bool> saveToGallery(String storagePath) async {
    try {
      final url = await getDownloadUrl(storagePath);
      final dir = await getTemporaryDirectory();
      final fileName = storagePath.split('/').last;
      final filePath = '${dir.path}/$fileName';

      // Download file
      final ref = _storage.ref(storagePath);
      final file = File(filePath);
      await ref.writeToFile(file);

      // Save to gallery
      final result = await GallerySaver.saveImage(filePath);

      // Clean up temp file
      if (file.existsSync()) {
        await file.delete();
      }

      return result ?? false;
    } catch (e) {
      AppLogger.error('Save to gallery error', error: e);
      return false;
    }
  }

  // Upload file
  Future<String> uploadFile(File file, String path) async {
    try {
      final ref = _storage.ref(path);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      AppLogger.error('Upload file error', error: e);
      rethrow;
    }
  }

  // Delete file
  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref(path).delete();
    } catch (e) {
      AppLogger.error('Delete file error', error: e);
      rethrow;
    }
  }
}

@riverpod
StorageService storageService(StorageServiceRef ref) {
  return StorageService();
}
