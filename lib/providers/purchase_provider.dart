import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/purchase_service.dart';
import 'auth_provider.dart';

final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final authService = ref.watch(authServiceProvider);
  final service = PurchaseService(authService: authService);
  ref.onDispose(service.dispose);
  return service;
});

/// Resolves after [PurchaseService.initialize] completes.
final isProProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(purchaseServiceProvider);
  await service.initialize();
  return service.isPro;
});

/// Resolves after initialize — exposes product price string or null.
final productPriceProvider = FutureProvider<String?>((ref) async {
  final service = ref.watch(purchaseServiceProvider);
  await service.initialize();
  return service.productPrice;
});

/// Manually invalidated to trigger a retry of product loading.
final productRetryProvider = StateProvider<int>((ref) => 0);

/// Sync convenience — false while loading.
final isProSyncProvider = Provider<bool>((ref) {
  return ref.watch(isProProvider).valueOrNull ?? false;
});
