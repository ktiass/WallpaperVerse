import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/constants.dart';
import '../models/wallpaper_model.dart';
import '../models/generation_model.dart';
import '../models/ownership_model.dart';
import '../utils/logger.dart';

part 'firestore_service.g.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Wallpapers
  Stream<List<WallpaperModel>> getFeaturedWallpapers() {
    return _firestore
        .collection(AppConstants.wallpapersCollection)
        .where('featured', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WallpaperModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Stream<List<WallpaperModel>> getTrendingWallpapers() {
    return _firestore
        .collection(AppConstants.wallpapersCollection)
        .orderBy('sales', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WallpaperModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Stream<List<WallpaperModel>> getNewWallpapers() {
    return _firestore
        .collection(AppConstants.wallpapersCollection)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WallpaperModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Stream<List<WallpaperModel>> getWallpapersByCategory(String category) {
    return _firestore
        .collection(AppConstants.wallpapersCollection)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WallpaperModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<List<WallpaperModel>> searchWallpapers(String query) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.wallpapersCollection)
          .where('tags', arrayContains: query.toLowerCase())
          .get();

      return snapshot.docs
          .map((doc) => WallpaperModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      AppLogger.error('Search error', error: e);
      return [];
    }
  }

  Stream<WallpaperModel?> getWallpaper(String id) {
    return _firestore
        .collection(AppConstants.wallpapersCollection)
        .doc(id)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return WallpaperModel.fromJson({...doc.data()!, 'id': doc.id});
    });
  }

  // Generations
  Stream<List<GenerationModel>> getUserGenerations(String uid) {
    return _firestore
        .collection(AppConstants.generationsCollection)
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GenerationModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Stream<GenerationModel?> getGeneration(String id) {
    return _firestore
        .collection(AppConstants.generationsCollection)
        .doc(id)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return GenerationModel.fromJson({...doc.data()!, 'id': doc.id});
    });
  }

  // Ownership
  Stream<List<OwnershipModel>> getUserOwnerships(String uid) {
    return _firestore
        .collection(AppConstants.userOwnershipCollection)
        .doc(uid)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OwnershipModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<bool> checkOwnership(String uid, String refId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.userOwnershipCollection)
          .doc(uid)
          .collection('items')
          .where('refId', isEqualTo: refId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      AppLogger.error('Check ownership error', error: e);
      return false;
    }
  }
}

@riverpod
FirestoreService firestoreService(FirestoreServiceRef ref) {
  return FirestoreService();
}

@riverpod
Stream<List<WallpaperModel>> featuredWallpapers(FeaturedWallpapersRef ref) {
  return ref.watch(firestoreServiceProvider).getFeaturedWallpapers();
}

@riverpod
Stream<List<WallpaperModel>> trendingWallpapers(TrendingWallpapersRef ref) {
  return ref.watch(firestoreServiceProvider).getTrendingWallpapers();
}

@riverpod
Stream<List<WallpaperModel>> newWallpapers(NewWallpapersRef ref) {
  return ref.watch(firestoreServiceProvider).getNewWallpapers();
}

@riverpod
Stream<WallpaperModel?> wallpaper(WallpaperRef ref, String id) {
  return ref.watch(firestoreServiceProvider).getWallpaper(id);
}

@riverpod
Stream<List<GenerationModel>> userGenerations(UserGenerationsRef ref, String uid) {
  return ref.watch(firestoreServiceProvider).getUserGenerations(uid);
}

@riverpod
Stream<GenerationModel?> generation(GenerationRef ref, String id) {
  return ref.watch(firestoreServiceProvider).getGeneration(id);
}

@riverpod
Stream<List<OwnershipModel>> userOwnerships(UserOwnershipsRef ref, String uid) {
  return ref.watch(firestoreServiceProvider).getUserOwnerships(uid);
}
