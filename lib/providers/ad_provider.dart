import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ad_service.dart';

/// Provides the [AdService] singleton.
/// The service self-initializes (preloads first rewarded ad) on first access.
final adServiceProvider = Provider<AdService>((ref) {
  final service = AdService();
  unawaited(service.initialize());
  ref.onDispose(service.dispose);
  return service;
});
