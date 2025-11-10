import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../services/firestore_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/credit_badge.dart';
import '../../../widgets/wallpaper_card.dart';
import '../../../widgets/empty_state.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WallpaperVerse'),
        actions: [
          CreditBadge(
            onTap: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Explore'),
            Tab(text: 'Trending'),
            Tab(text: 'New'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeaturedTab(),
          _buildTrendingTab(),
          _buildNewTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              context.push('/generator');
              break;
            case 2:
              context.push('/library');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'Generate',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.collections),
            label: 'Library',
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedTab() {
    final wallpapersAsync = ref.watch(featuredWallpapersProvider);

    return wallpapersAsync.when(
      data: (wallpapers) {
        if (wallpapers.isEmpty) {
          return const EmptyState(
            icon: Icons.wallpaper,
            title: 'No Wallpapers Yet',
            message: 'Check back soon for amazing wallpapers!',
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
          itemCount: wallpapers.length,
          itemBuilder: (context, index) {
            final wallpaper = wallpapers[index];
            return WallpaperCard(
              wallpaper: wallpaper,
              onTap: () => context.push('/detail/${wallpaper.id}'),
            );
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
        onAction: () => ref.refresh(featuredWallpapersProvider),
      ),
    );
  }

  Widget _buildTrendingTab() {
    final wallpapersAsync = ref.watch(trendingWallpapersProvider);

    return wallpapersAsync.when(
      data: (wallpapers) {
        if (wallpapers.isEmpty) {
          return const EmptyState(
            icon: Icons.trending_up,
            title: 'No Trending Wallpapers',
            message: 'Check back soon!',
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
          itemCount: wallpapers.length,
          itemBuilder: (context, index) {
            final wallpaper = wallpapers[index];
            return WallpaperCard(
              wallpaper: wallpaper,
              onTap: () => context.push('/detail/${wallpaper.id}'),
            );
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
        onAction: () => ref.refresh(trendingWallpapersProvider),
      ),
    );
  }

  Widget _buildNewTab() {
    final wallpapersAsync = ref.watch(newWallpapersProvider);

    return wallpapersAsync.when(
      data: (wallpapers) {
        if (wallpapers.isEmpty) {
          return const EmptyState(
            icon: Icons.new_releases,
            title: 'No New Wallpapers',
            message: 'Check back soon!',
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
          itemCount: wallpapers.length,
          itemBuilder: (context, index) {
            final wallpaper = wallpapers[index];
            return WallpaperCard(
              wallpaper: wallpaper,
              onTap: () => context.push('/detail/${wallpaper.id}'),
            );
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
        onAction: () => ref.refresh(newWallpapersProvider),
      ),
    );
  }
}
