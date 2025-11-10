import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';

import '../../../services/firestore_service.dart';
import '../../../services/functions_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/loading_overlay.dart';

class DetailScreen extends ConsumerStatefulWidget {
  final String wallpaperId;

  const DetailScreen({super.key, required this.wallpaperId});

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  bool _isLoading = false;
  bool _isOwned = false;

  @override
  void initState() {
    super.initState();
    _checkOwnership();
  }

  Future<void> _checkOwnership() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final firestoreService = ref.read(firestoreServiceProvider);
    final owned = await firestoreService.checkOwnership(user.uid, widget.wallpaperId);
    setState(() => _isOwned = owned);
  }

  Future<void> _purchaseWallpaper() async {
    setState(() => _isLoading = true);

    try {
      final functionsService = ref.read(functionsServiceProvider);
      final success = await functionsService.purchaseWallpaper(widget.wallpaperId);

      if (success && mounted) {
        setState(() => _isOwned = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wallpaper unlocked successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadWallpaper(String storagePath) async {
    setState(() => _isLoading = true);

    try {
      final storageService = ref.read(storageServiceProvider);
      final success = await storageService.saveToGallery(storagePath);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wallpaper saved to gallery!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save wallpaper'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallpaperAsync = ref.watch(wallpaperProvider(widget.wallpaperId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isOwned)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                final wallpaper = wallpaperAsync.value;
                if (wallpaper != null) {
                  _downloadWallpaper(wallpaper.storagePath);
                }
              },
            ),
        ],
      ),
      body: wallpaperAsync.when(
        data: (wallpaper) {
          if (wallpaper == null) {
            return const Center(
              child: Text('Wallpaper not found'),
            );
          }

          return Stack(
            children: [
              // Full screen image preview
              PhotoView(
                imageProvider: CachedNetworkImageProvider(
                  _isOwned ? wallpaper.storagePath : wallpaper.thumbnailPath,
                ),
                backgroundDecoration: const BoxDecoration(
                  color: AppTheme.backgroundColor,
                ),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              ),

              // Watermark overlay (if not owned)
              if (!_isOwned)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.center,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Opacity(
                          opacity: 0.3,
                          child: Text(
                            'WALLPAPERVERSE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Bottom info panel
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.9),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          wallpaper.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        if (wallpaper.description != null)
                          Text(
                            wallpaper.description!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: wallpaper.tags
                              .map((tag) => Chip(
                                    label: Text(tag),
                                    backgroundColor: AppTheme.cardColor,
                                    labelStyle: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 12,
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                        if (!_isOwned)
                          ElevatedButton(
                            onPressed: _isLoading ? null : _purchaseWallpaper,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star, size: 20),
                                const SizedBox(width: 8),
                                Text('Unlock for ${wallpaper.price} credits'),
                              ],
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () => _downloadWallpaper(wallpaper.storagePath),
                            icon: const Icon(Icons.download),
                            label: const Text('Download'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              if (_isLoading) const LoadingOverlay(),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
