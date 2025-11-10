class AppConstants {
  // App Info
  static const String appName = 'WallpaperVerse';
  static const String appVersion = '1.0.0';

  // Product IDs
  static const String credits5 = 'credits_5';
  static const String credits20 = 'credits_20';
  static const String credits100 = 'credits_100';
  static const String wallpaperUnlock = 'wallpaper_unlock';
  static const String subMonthlyPlus = 'sub_monthly_plus';

  // Credit Costs
  static const int unlockWallpaperCost = 1;
  static const int generation512x1024Cost = 1;
  static const int generation1024x2048Cost = 2;
  static const int generation1024x1024Cost = 1;

  // AI Generation
  static const Map<String, Map<String, int>> aspectRatios = {
    '9:16': {'width': 1080, 'height': 1920},
    '1:1': {'width': 1024, 'height': 1024},
    '2:3': {'width': 1024, 'height': 1536},
  };

  // UI
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 8.0;

  // Pagination
  static const int wallpapersPerPage = 20;
  static const int generationsPerPage = 10;

  // Cache
  static const int maxCacheSize = 100; // MB
  static const Duration cacheExpiration = Duration(days: 7);

  // Validation
  static const int maxPromptLength = 500;
  static const int minPromptLength = 3;

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration generationTimeout = Duration(minutes: 5);

  // Collections
  static const String usersCollection = 'users';
  static const String wallpapersCollection = 'wallpapers';
  static const String generationsCollection = 'generations';
  static const String receiptsCollection = 'receipts';
  static const String userOwnershipCollection = 'user_ownership';

  // Storage Paths
  static const String publicWallpapersPath = 'public/wallpapers';
  static const String protectedGenerationsPath = 'protected/users';
}
