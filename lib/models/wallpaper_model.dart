import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallpaper_model.freezed.dart';
part 'wallpaper_model.g.dart';

@freezed
class WallpaperModel with _$WallpaperModel {
  const factory WallpaperModel({
    required String id,
    required String title,
    required List<String> tags,
    required List<String> colors,
    required String category,
    required String style,
    required WallpaperResolution resolution,
    required String storagePath,
    required String thumbnailPath,
    required int price,
    @Default(false) bool featured,
    required DateTime createdAt,
    @Default(0) int sales,
    String? description,
    String? authorId,
    String? authorName,
  }) = _WallpaperModel;

  factory WallpaperModel.fromJson(Map<String, dynamic> json) =>
      _$WallpaperModelFromJson(json);
}

@freezed
class WallpaperResolution with _$WallpaperResolution {
  const factory WallpaperResolution({
    required int width,
    required int height,
  }) = _WallpaperResolution;

  factory WallpaperResolution.fromJson(Map<String, dynamic> json) =>
      _$WallpaperResolutionFromJson(json);
}
