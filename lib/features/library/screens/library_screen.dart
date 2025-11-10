import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/empty_state.dart';
import '../../../models/generation_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in to view your library'),
        ),
      );
    }

    final generationsAsync = ref.watch(userGenerationsProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Library'),
      ),
      body: generationsAsync.when(
        data: (generations) {
          if (generations.isEmpty) {
            return EmptyState(
              icon: Icons.collections,
              title: 'No Generations Yet',
              message: 'Start generating amazing wallpapers!',
              actionLabel: 'Generate Now',
              onAction: () => context.push('/generator'),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 9 / 16,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: generations.length,
            itemBuilder: (context, index) {
              final generation = generations[index];
              return _GenerationCard(generation: generation);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
        error: (error, stack) => EmptyState(
          icon: Icons.error,
          title: 'Error',
          message: error.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.refresh(userGenerationsProvider(user.uid)),
        ),
      ),
    );
  }
}

class _GenerationCard extends StatelessWidget {
  final GenerationModel generation;

  const _GenerationCard({required this.generation});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.cardColor,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Image
            if (generation.thumbnailPath != null)
              AspectRatio(
                aspectRatio: 9 / 16,
                child: CachedNetworkImage(
                  imageUrl: generation.thumbnailPath!,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    color: AppTheme.surfaceColor,
                    child: const Icon(Icons.error, color: AppTheme.errorColor),
                  ),
                ),
              )
            else
              AspectRatio(
                aspectRatio: 9 / 16,
                child: Container(
                  color: AppTheme.surfaceColor,
                  child: Center(
                    child: _buildStatusWidget(),
                  ),
                ),
              ),

            // Status overlay
            if (generation.status != GenerationStatus.succeeded)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: _buildStatusWidget(),
                  ),
                ),
              ),

            // Bottom info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      generation.prompt,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: AppTheme.accentColor,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${generation.creditCost} credits',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                        const Spacer(),
                        if (!generation.isOwned)
                          const Icon(
                            Icons.lock,
                            color: AppTheme.warningColor,
                            size: 12,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusWidget() {
    switch (generation.status) {
      case GenerationStatus.queued:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty, color: AppTheme.textSecondary),
            SizedBox(height: 8),
            Text(
              'Queued',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        );
      case GenerationStatus.running:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            SizedBox(height: 8),
            Text(
              'Generating...',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ],
        );
      case GenerationStatus.failed:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, color: AppTheme.errorColor),
            SizedBox(height: 8),
            Text(
              'Failed',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ],
        );
      case GenerationStatus.succeeded:
        return const SizedBox.shrink();
    }
  }
}
