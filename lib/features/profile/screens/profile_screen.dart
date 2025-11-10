import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../services/auth_service.dart';
import '../../../services/iap_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/loading_overlay.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  List<ProductDetails> _products = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _initializeIAP();
  }

  Future<void> _initializeIAP() async {
    final iapService = ref.read(iapServiceProvider);
    await iapService.initialize(
      onPurchaseUpdate: _handlePurchaseUpdate,
    );
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final iapService = ref.read(iapServiceProvider);
      final products = await iapService.getProducts();
      setState(() => _products = products);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handlePurchaseUpdate(PurchaseDetails purchase) {
    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase successful!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else if (purchase.status == PurchaseStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase failed: ${purchase.error}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _purchaseProduct(ProductDetails product) async {
    setState(() => _isLoading = true);
    try {
      final iapService = ref.read(iapServiceProvider);
      await iapService.purchaseProduct(product);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);
    try {
      final iapService = ref.read(iapServiceProvider);
      await iapService.restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchases restored'),
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

  Future<void> _signOut() async {
    final authService = ref.read(authServiceProvider);
    await authService.signOut();
    if (mounted) {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(userProfileProvider).value;
    final credits = ref.watch(userCreditsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User info
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.primaryColor,
                        child: Text(
                          user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.displayName ?? 'User',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user?.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Credits card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Available Credits',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '$credits',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Products
                Text(
                  'Buy Credits',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                if (_products.isEmpty && !_isLoading)
                  const Center(
                    child: Text('No products available'),
                  )
                else
                  ..._products.map((product) => _ProductCard(
                        product: product,
                        onPurchase: () => _purchaseProduct(product),
                      )),
                const SizedBox(height: 24),

                // Actions
                OutlinedButton(
                  onPressed: _restorePurchases,
                  child: const Text('Restore Purchases'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _signOut,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                  ),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          ),
          if (_isLoading) const LoadingOverlay(),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductDetails product;
  final VoidCallback onPurchase;

  const _ProductCard({
    required this.product,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.star,
            color: AppTheme.accentColor,
          ),
        ),
        title: Text(product.title),
        subtitle: Text(product.description),
        trailing: ElevatedButton(
          onPressed: onPurchase,
          child: Text(product.price),
        ),
      ),
    );
  }
}
