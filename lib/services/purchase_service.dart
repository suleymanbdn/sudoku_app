import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'auth_service.dart';

const kProProductId = 'unlock_full_game';
const _secureKey = 'is_pro_unlocked';

enum StoreStatus {
  loading,
  storeUnavailable,
  productNotFound,
  queryError,
  ready,
}

class PurchaseService {
  PurchaseService({AuthService? authService}) : _authService = authService;

  final AuthService? _authService;

  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions());

  final InAppPurchase _iap = InAppPurchase.instance;
  ProductDetails? _product;

  bool _isPro = false;
  bool _initialized = false;
  StoreStatus _storeStatus = StoreStatus.loading;
  String? _lastError;

  bool get isPro => _isPro;
  String? get productPrice => _product?.price;
  bool get canPurchase => _product != null;
  StoreStatus get storeStatus => _storeStatus;
  String? get lastError => _lastError;

  late final Stream<bool> purchaseStream = _iap.purchaseStream
      .asyncMap((updates) async {
        await _handleUpdates(updates);
        return _isPro;
      })
      .asBroadcastStream();

  StreamSubscription<bool>? _keepAlive;

  /// Safe to call multiple times. Pass [force]=true to re-query the store.
  Future<void> initialize({bool force = false}) async {
    if (_initialized && !force) return;
    _initialized = true;
    _storeStatus = StoreStatus.loading;
    _lastError = null;

    // 1. Local cache
    final stored = await _storage.read(key: _secureKey);
    _isPro = stored == 'true';

    // 2. Cloud backup — if signed in with Google and not already pro
    if (!_isPro && _authService != null) {
      final cloudPro = await _authService.fetchProFromCloud();
      if (cloudPro) {
        _isPro = true;
        await _storage.write(key: _secureKey, value: 'true');
        if (kDebugMode) debugPrint('PurchaseService: isPro restored from Firestore');
      }
    }

    _keepAlive ??= purchaseStream.listen((_) {});

    final available = await _iap.isAvailable();
    if (!available) {
      _storeStatus = StoreStatus.storeUnavailable;
      _lastError = 'Play Store kullanılamıyor (isAvailable=false)';
      if (kDebugMode) debugPrint('IAP: $_lastError');
      return;
    }

    for (var attempt = 1; attempt <= 3; attempt++) {
      final response = await _iap.queryProductDetails({kProProductId});

      if (response.error != null) {
        _lastError = 'Sorgu hatası: ${response.error}';
        if (kDebugMode) debugPrint('IAP attempt $attempt — $_lastError');
        _storeStatus = StoreStatus.queryError;
      }

      if (response.notFoundIDs.isNotEmpty) {
        _lastError = 'Ürün bulunamadı: ${response.notFoundIDs}';
        if (kDebugMode) debugPrint('IAP attempt $attempt — $_lastError');
        _storeStatus = StoreStatus.productNotFound;
      }

      if (response.productDetails.isNotEmpty) {
        _product = response.productDetails.first;
        _storeStatus = StoreStatus.ready;
        _lastError = null;
        if (kDebugMode) debugPrint('IAP: ürün yüklendi ($attempt. deneme)');
        return;
      }

      if (attempt < 3) {
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }
    }
  }

  Future<void> retryLoadProduct() async {
    _product = null;
    _initialized = false;
    await initialize(force: true);
  }

  Future<void> buyPro() async {
    if (_product == null) return;
    await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: _product!),
    );
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  Future<void> _handleUpdates(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != kProProductId) continue;

      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        _isPro = true;
        await _storage.write(key: _secureKey, value: 'true');

        // Notify server to verify purchase via Play Developer API.
        // Server writes isPro to Firestore after verification.
        if (p.verificationData.serverVerificationData.isNotEmpty) {
          await _authService?.notifyPurchaseToServer(
            purchaseToken: p.verificationData.serverVerificationData,
            productId: p.productID,
          );
        }
        if (kDebugMode) debugPrint('PurchaseService: isPro saved locally');
      }

      if (p.status == PurchaseStatus.error) {
        if (kDebugMode) debugPrint('IAP purchase error: ${p.error}');
      }

      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
  }

  void dispose() {
    _keepAlive?.cancel();
  }
}
