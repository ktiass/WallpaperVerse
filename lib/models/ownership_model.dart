import 'package:freezed_annotation/freezed_annotation.dart';

part 'ownership_model.freezed.dart';
part 'ownership_model.g.dart';

enum OwnershipType {
  wallpaper,
  generation,
}

enum OwnershipSource {
  purchase,
  subscription,
  promo,
}

@freezed
class OwnershipModel with _$OwnershipModel {
  const factory OwnershipModel({
    required String id,
    required String uid,
    required OwnershipType type,
    required String refId,
    required DateTime createdAt,
    required OwnershipSource source,
    String? receiptId,
  }) = _OwnershipModel;

  factory OwnershipModel.fromJson(Map<String, dynamic> json) =>
      _$OwnershipModelFromJson(json);
}
