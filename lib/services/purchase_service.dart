import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

// ── Constants ────────────────────────────────────────────────────────────────
/// Entitlement identifier (kept for API compatibility).
const kProEntitlement = 'pro';

/// Must match the product identifier in App Store / Play Store.
const kProProductId = 'unlock_full_game_lifetime';

/// Consumable hint pack — 10 hints for $0.99.
const kHintPackProductId = 'hint_pack_10';

/// Number of hints granted per hint pack purchase.
const kHintPackCount = 10;

/// Secure storage key for persisting pro status locally.
const _kIsProKey = 'is_pro_iap_v1';

enum StoreStatus {
  loading,
  storeUnavailable,
  productNotFound,
  queryError,
  ready,
}

class PurchaseService {
  bool _isPro = false;
  bool _initialized = false;
  StoreStatus _storeStatus = StoreStatus.loading;
  ProductDetails? _proProduct;
  ProductDetails? _hintPackProduct;
  String? _lastError;

  // Used to bridge the async purchase stream back to the buyPro() caller.
  Completer<bool>? _buyCompleter;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  final _proStreamCtrl = StreamController<bool>.broadcast();
  final _hintPackStreamCtrl = StreamController<int>.broadcast();
  final _storage = const FlutterSecureStorage();

  bool get isPro => _isPro;
  String? get productPrice => _proProduct?.price;
  String? get hintPackPrice => _hintPackProduct?.price;
  bool get canPurchase => _proProduct != null;
  bool get canPurchaseHintPack => _hintPackProduct != null;
  StoreStatus get storeStatus => _storeStatus;
  String? get lastError => _lastError;

  /// Emits the current `isPro` value whenever it changes.
  Stream<bool> get purchaseStream => _proStreamCtrl.stream;

  /// Emits the number of coins to add after a hint pack purchase.
  Stream<int> get hintPackStream => _hintPackStreamCtrl.stream;

  // ── Initialization ──────────────────────────────────────────────────────────

  Future<void> initialize({bool force = false}) async {
    if (_initialized && !force) return;
    _initialized = true;
    _lastError = null;
    _storeStatus = StoreStatus.loading;

    // Restore persisted pro status instantly (no network).
    final stored = await _storage.read(key: _kIsProKey);
    if (stored == 'true' && !_isPro) {
      _isPro = true;
      _proStreamCtrl.add(true);
    }

    // Check if the store is reachable.
    final available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      _storeStatus = StoreStatus.storeUnavailable;
      _lastError = 'Store not available';
      if (kDebugMode) debugPrint('PurchaseService: store unavailable');
      return;
    }

    // Subscribe to purchase updates (purchases, restores, errors, cancels).
    await _purchaseSub?.cancel();
    _purchaseSub = InAppPurchase.instance.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object e) {
        if (kDebugMode) debugPrint('PurchaseService: stream error — $e');
      },
    );

    await _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final resp = await InAppPurchase.instance
          .queryProductDetails({kProProductId, kHintPackProductId});

      if (resp.error != null) {
        _storeStatus = StoreStatus.queryError;
        _lastError = resp.error!.message;
        if (kDebugMode) debugPrint('PurchaseService: query error — $_lastError');
        return;
      }

      for (final p in resp.productDetails) {
        if (p.id == kProProductId) _proProduct = p;
        if (p.id == kHintPackProductId) _hintPackProduct = p;
      }

      if (_proProduct == null) {
        _storeStatus = StoreStatus.productNotFound;
        _lastError = 'Product not found: $kProProductId';
        if (kDebugMode) debugPrint('PurchaseService: $_lastError');
        return;
      }

      _storeStatus = StoreStatus.ready;
      _lastError = null;
      if (kDebugMode) {
        debugPrint(
          'PurchaseService: pro=${_proProduct!.price} '
          'hintPack=${_hintPackProduct?.price ?? "not found"}',
        );
      }
    } catch (e) {
      _storeStatus = StoreStatus.queryError;
      _lastError = e.toString();
      if (kDebugMode) debugPrint('PurchaseService: _loadProduct failed — $e');
    }
  }

  // ── Purchase stream handling ─────────────────────────────────────────────────

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    if (purchase.productID != kProProductId &&
        purchase.productID != kHintPackProductId) {
      return;
    }

    switch (purchase.status) {
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        if (purchase.productID == kProProductId) {
          await _setPro(true);
          if (!(_buyCompleter?.isCompleted ?? true)) {
            _buyCompleter!.complete(true);
          }
        } else if (purchase.productID == kHintPackProductId) {
          _hintPackStreamCtrl.add(kHintPackCount);
          if (!(_buyCompleter?.isCompleted ?? true)) {
            _buyCompleter!.complete(true);
          }
        }

      case PurchaseStatus.canceled:
        if (!(_buyCompleter?.isCompleted ?? true)) {
          _buyCompleter!.complete(false);
        }

      case PurchaseStatus.error:
        final err = purchase.error?.message ?? 'Purchase failed';
        if (kDebugMode) debugPrint('PurchaseService: purchase error — $err');
        if (!(_buyCompleter?.isCompleted ?? true)) {
          _buyCompleter!.completeError(Exception(err));
        }

      case PurchaseStatus.pending:
        if (kDebugMode) debugPrint('PurchaseService: purchase pending');
    }

    // Always acknowledge / complete the transaction with StoreKit / Google Play.
    if (purchase.pendingCompletePurchase) {
      await InAppPurchase.instance.completePurchase(purchase);
    }
  }

  Future<void> _setPro(bool value) async {
    _isPro = value;
    _proStreamCtrl.add(value);
    await _storage.write(key: _kIsProKey, value: value.toString());
  }

  // ── Purchase actions ────────────────────────────────────────────────────────

  Future<void> retryLoadProduct() async {
    _proProduct = null;
    _initialized = false;
    await initialize(force: true);
  }

  /// Initiates a purchase. Awaits until the StoreKit/Play dialog resolves.
  /// Returns normally on success or cancel; throws on error.
  Future<void> buyPro() async {
    if (_proProduct == null) {
      throw Exception('Product not loaded');
    }

    _buyCompleter = Completer<bool>();

    try {
      final param = PurchaseParam(productDetails: _proProduct!);
      final initiated =
          await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);

      if (!initiated) {
        _buyCompleter!.complete(false);
      }

      // Wait for the purchase stream to resolve the Completer.
      await _buyCompleter!.future;
    } catch (e) {
      if (!(_buyCompleter?.isCompleted ?? true)) {
        _buyCompleter!.completeError(e);
      }
      rethrow;
    } finally {
      _buyCompleter = null;
    }
  }

  /// Purchases a hint pack (consumable).
  /// Returns `true` if coins were successfully granted, `false` if the user
  /// cancelled or the purchase could not be initiated. Throws on error.
  Future<bool> buyHintPack() async {
    if (_hintPackProduct == null) {
      throw Exception('Hint pack product not loaded');
    }

    _buyCompleter = Completer<bool>();

    try {
      final param = PurchaseParam(productDetails: _hintPackProduct!);
      final initiated =
          await InAppPurchase.instance.buyConsumable(purchaseParam: param);

      if (!initiated) {
        _buyCompleter!.complete(false);
      }

      // Returns true only when _handlePurchase confirms PurchaseStatus.purchased.
      return await _buyCompleter!.future;
    } catch (e) {
      if (!(_buyCompleter?.isCompleted ?? true)) {
        _buyCompleter!.completeError(e);
      }
      rethrow;
    } finally {
      _buyCompleter = null;
    }
  }

  Future<void> restorePurchases() async {
    await InAppPurchase.instance.restorePurchases();
    // Results arrive via purchaseStream → _handlePurchase → _setPro.
  }

  // ── Account linking (no-ops — RevenueCat removed) ───────────────────────────

  /// No-op: kept for API compatibility.
  Future<void> loginUser(String userId) async {}

  /// No-op: kept for API compatibility.
  Future<void> logoutUser() async {}

  // ── Cleanup ──────────────────────────────────────────────────────────────────

  void dispose() {
    _purchaseSub?.cancel();
    _proStreamCtrl.close();
    _hintPackStreamCtrl.close();
  }
}
