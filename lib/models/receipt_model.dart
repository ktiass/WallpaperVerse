import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipt_model.freezed.dart';
part 'receipt_model.g.dart';

enum Store {
  appstore,
  play,
}

enum ProductType {
  consumable,
  subscription,
  nonconsumable,
}

@freezed
class ReceiptModel with _$ReceiptModel {
  const factory ReceiptModel({
    required String id,
    required String uid,
    required Store store,
    required String productId,
    required ProductType type,
    required Map<String, dynamic> raw,
    required bool validated,
    required int creditsGranted,
    required DateTime createdAt,
    String? transactionId,
  }) = _ReceiptModel;

  factory ReceiptModel.fromJson(Map<String, dynamic> json) =>
      _$ReceiptModelFromJson(json);
}
