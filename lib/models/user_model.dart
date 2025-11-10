import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String uid,
    required String email,
    String? displayName,
    String? photoURL,
    @Default(0) int credits,
    required DateTime createdAt,
    required DateTime lastActiveAt,
    UserPlan? plan,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

@freezed
class UserPlan with _$UserPlan {
  const factory UserPlan({
    required String type,
    DateTime? renewalDate,
    @Default(false) bool isActive,
  }) = _UserPlan;

  factory UserPlan.fromJson(Map<String, dynamic> json) =>
      _$UserPlanFromJson(json);
}
