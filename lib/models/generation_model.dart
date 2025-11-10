import 'package:freezed_annotation/freezed_annotation.dart';

part 'generation_model.freezed.dart';
part 'generation_model.g.dart';

enum GenerationStatus {
  queued,
  running,
  succeeded,
  failed,
}

@freezed
class GenerationModel with _$GenerationModel {
  const factory GenerationModel({
    required String id,
    required String uid,
    required String prompt,
    required GenerationStyle style,
    required GenerationStatus status,
    String? storagePath,
    String? thumbnailPath,
    String? error,
    required int creditCost,
    required DateTime createdAt,
    DateTime? completedAt,
    @Default(false) bool isOwned,
  }) = _GenerationModel;

  factory GenerationModel.fromJson(Map<String, dynamic> json) =>
      _$GenerationModelFromJson(json);
}

@freezed
class GenerationStyle with _$GenerationStyle {
  const factory GenerationStyle({
    required String aspect,
    @Default('realistic') String stylePreset,
    @Default(1.0) double chromatic,
    Map<String, dynamic>? additionalParams,
  }) = _GenerationStyle;

  factory GenerationStyle.fromJson(Map<String, dynamic> json) =>
      _$GenerationStyleFromJson(json);
}
