import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/constants.dart';
import '../utils/logger.dart';
import 'functions_service.dart';

part 'iap_service.g.dart';

class IAPService {
  final InAppPurchase _iap = InAppPurchase.instance;
  final FunctionsService _functionsService;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  IAPService(this._functionsService);

  // Product IDs
  static const Set<String> _productIds = {
    AppConstants.credits5,
    AppConstants.credits20,
    AppConstants.credits100,
    AppConstants.subMonthlyPlus,
  };

  // Initialize IAP
  Future<bool> initialize({
    required Function(PurchaseDetails) onPurchaseUpdate,
  }) async {
    final available = await _iap.isAvailable();
    if (!available) {
      AppLogger.warning('IAP not available');
      return false;
    }

    // Setup purchase listener
    _subscription = _iap.purchaseStream.listen(
      (purchases) async {
        for (final purchase in purchases) {
          await _handlePurchase(purchase, onPurchaseUpdate);
        }
      },
      onError: (error) {
        AppLogger.error('Purchase stream error', error: error);
      },
    );

    return true;
  }

  // Get products
  Future<List<ProductDetails>> getProducts() async {
    try {
      final response = await _iap.queryProductDetails(_productIds);

      if (response.notFoundIDs.isNotEmpty) {
        AppLogger.warning('Products not found: ${response.notFoundIDs}');
      }

      return response.productDetails;
    } catch (e) {
      AppLogger.error('Get products error', error: e);
      return [];
    }
  }

  // Purchase product
  Future<bool> purchaseProduct(ProductDetails product) async {
    try {
      final purchaseParam = PurchaseParam(productDetails: product);

      if (product.id == AppConstants.subMonthlyPlus) {
        return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        return await _iap.buyConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      AppLogger.error('Purchase error', error: e);
      return false;
    }
  }

  // Restore purchases
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      AppLogger.error('Restore purchases error', error: e);
      rethrow;
    }
  }

  // Handle purchase
  Future<void> _handlePurchase(
    PurchaseDetails purchase,
    Function(PurchaseDetails) onPurchaseUpdate,
  ) async {
    if (purchase.status == PurchaseStatus.pending) {
      AppLogger.info('Purchase pending: ${purchase.productID}');
      onPurchaseUpdate(purchase);
      return;
    }

    if (purchase.status == PurchaseStatus.error) {
      AppLogger.error('Purchase error: ${purchase.error}');
      onPurchaseUpdate(purchase);
      return;
    }

    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      // Verify purchase with server
      final valid = await _verifyPurchase(purchase);

      if (valid) {
        AppLogger.info('Purchase verified: ${purchase.productID}');
        onPurchaseUpdate(purchase);

        // Complete purchase
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      } else {
        AppLogger.error('Purchase verification failed: ${purchase.productID}');
      }
    }
  }

  // Verify purchase with server
  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    try {
      String verificationData;
      String platform;

      if (Platform.isIOS) {
        final iosPurchase = purchase as AppStorePurchaseDetails;
        verificationData = iosPurchase.verificationData.serverVerificationData;
        platform = 'ios';
      } else if (Platform.isAndroid) {
        final androidPurchase = purchase as GooglePlayPurchaseDetails;
        verificationData = androidPurchase.verificationData.serverVerificationData;
        platform = 'android';
      } else {
        return false;
      }

      final result = await _functionsService.validateReceipt(
        raw: verificationData,
        platform: platform,
      );

      return result['validated'] as bool;
    } catch (e) {
      AppLogger.error('Verify purchase error', error: e);
      return false;
    }
  }

  // Get credit amount for product
  int getCreditsForProduct(String productId) {
    switch (productId) {
      case AppConstants.credits5:
        return 5;
      case AppConstants.credits20:
        return 20;
      case AppConstants.credits100:
        return 100;
      case AppConstants.subMonthlyPlus:
        return 50; // Bonus credits on purchase
      default:
        return 0;
    }
  }

  // Dispose
  void dispose() {
    _subscription?.cancel();
  }
}

@riverpod
IAPService iapService(IapServiceRef ref) {
  final functionsService = ref.watch(functionsServiceProvider);
  return IAPService(functionsService);
}
