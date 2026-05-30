import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/purchase_service.dart';
import 'hint_coins_provider.dart';

final Provider<PurchaseService> purchaseServiceProvider =
    Provider<PurchaseService>((ref) {
  final service = PurchaseService();

  // Whenever pro status changes, invalidate isProProvider so widgets rebuild.
  final proSub = service.purchaseStream.listen((_) {
    ref.invalidate(isProProvider);
  });

  // Whenever a hint pack is purchased, add coins to the hint coins provider.
  final hintSub = service.hintPackStream.listen((coins) {
    ref.read(hintCoinsProvider.notifier).addCoins(coins);
  });

  ref.onDispose(() {
    proSub.cancel();
    hintSub.cancel();
    service.dispose();
  });

  return service;
});

/// Resolves after [PurchaseService.initialize] completes.
final FutureProvider<bool> isProProvider = FutureProvider<bool>((ref) async {
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

/// Sync convenience — false while loading.
/// Keeps last known value during re-evaluation to avoid a pro→non-pro flash.
final isProSyncProvider = Provider<bool>((ref) {
  return ref.watch(isProProvider).valueOrNull ?? false;
});
