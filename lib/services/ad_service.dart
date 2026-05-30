import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Manages Google AdMob rewarded ads for the hint system.
///
/// Free users watch a rewarded ad to earn one extra hint.
/// Pro users never see ads.
///
/// ────────────────────────────────────────────────────────────────────────────
/// AdMob setup is complete. Real production IDs are configured below.

class AdService {
  // ── Google official TEST IDs (safe for development) ─────────────────────────
  static const _testAndroidRewardedId = 'ca-app-pub-3940256099942544/5224354917';
  static const _testIosRewardedId = 'ca-app-pub-3940256099942544/1712485313';

  // ── Production IDs ───────────────────────────────────────────────────────────
  static const _prodAndroidRewardedId = 'ca-app-pub-7029430440483366/2345043025';
  static const _prodIosRewardedId = 'ca-app-pub-7029430440483366/7733631302';

  static String get _rewardedAdUnitId {
    if (kDebugMode) {
      return Platform.isIOS ? _testIosRewardedId : _testAndroidRewardedId;
    }
    return Platform.isIOS ? _prodIosRewardedId : _prodAndroidRewardedId;
  }

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  /// Whether a rewarded ad is preloaded and ready to show.
  bool get isReady => _rewardedAd != null;

  /// Initializes the AdMob SDK and preloads the first rewarded ad.
  Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      _loadAd();
    } catch (e) {
      if (kDebugMode) debugPrint('AdService: MobileAds init failed — $e');
    }
  }

  void _loadAd() {
    if (_isLoading) return;
    _isLoading = true;
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          if (kDebugMode) debugPrint('AdService: rewarded ad loaded.');
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          if (kDebugMode) debugPrint('AdService: failed to load — $error');
        },
      ),
    );
  }

  /// Shows the rewarded ad and returns `true` if the user earned a reward.
  /// Returns `false` if no ad is ready or the user dismissed without watching.
  Future<bool> showRewardedAd() async {
    if (_rewardedAd == null) {
      _loadAd(); // try to preload for next time
      return false;
    }

    final completer = Completer<bool>();

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadAd();
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _loadAd();
        if (!completer.isCompleted) completer.complete(false);
        if (kDebugMode) debugPrint('AdService: failed to show — $error');
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        if (!completer.isCompleted) completer.complete(true);
      },
    );

    return completer.future;
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
