// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Sudoku';

  @override
  String get navPlay => 'Oyna';

  @override
  String get navScores => 'Skorlar';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get preparingPuzzle => 'Bulmaca hazırlanıyor…';

  @override
  String get okButton => 'Tamam';

  @override
  String get cancelButton => 'İptal';

  @override
  String get whichDifficultyToday => 'Bugün hangi zorluğu denersin?';

  @override
  String get proBadge => 'PRO';

  @override
  String get continueGame => 'Devam Et';

  @override
  String continueProgress(String difficulty, int percent) {
    return '$difficulty · %$percent tamamlandı';
  }

  @override
  String get startNewGame => 'Yeni Oyun';

  @override
  String get difficultyEasy => 'Kolay';

  @override
  String get difficultyMedium => 'Orta';

  @override
  String get difficultyHard => 'Zor';

  @override
  String get difficultyExpert => 'Uzman';

  @override
  String get difficultyEasySubtitle => 'Zihnini ısıt';

  @override
  String get difficultyMediumSubtitle => 'Sağlam meydan okuma';

  @override
  String get difficultyHardSubtitle => 'Keskin ve zorlayıcı';

  @override
  String get difficultyExpertSubtitle => 'Çok seyrek · sadece ustalar için';

  @override
  String get badgeBronze => 'Bronz';

  @override
  String get badgeSilver => 'Gümüş';

  @override
  String get badgeGold => 'Altın';

  @override
  String get badgeDiamond => 'Elmas';

  @override
  String get duelRace => 'Düello yarışı';

  @override
  String get duelRaceSubtitle => 'Aynı bulmaca — ilk doğru bitiren kazanır';

  @override
  String get dailyChallenge => 'Günlük Görev';

  @override
  String get playButton => 'Oyna';

  @override
  String get dailyCompleted => 'Tamamlandı!';

  @override
  String get dailyPerfect => 'Kusursuz! 🎉';

  @override
  String get goProTitle => '⚡ Pro\'ya Geç';

  @override
  String get goProSubtitle => 'Zor, Uzman & neon görünüm — tek seferlik ödeme';

  @override
  String get buyButton => 'Satın Al';

  @override
  String get myScores => 'Skorlarım';

  @override
  String get totalWins => 'toplam galibiyet';

  @override
  String get dayStreak => '🔥 günlük seri';

  @override
  String get byDifficulty => 'Zorluğa göre';

  @override
  String get noWinsYet => 'Henüz galibiyet yok';

  @override
  String get noWinsYetSubtitle =>
      'İlk oyununu kazan —\nistatistikler burada görünecek.';

  @override
  String get winsLabel => 'galibiyet';

  @override
  String get noWinsShort => 'henüz yok';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get appearance => 'Görünüm';

  @override
  String get appearanceLight => 'Açık';

  @override
  String get appearanceDark => 'Koyu';

  @override
  String get colorTheme => 'Renk teması';

  @override
  String get neonEffects => 'Neon efektleri';

  @override
  String get glowAndHighlights => 'Parlama & vurgular';

  @override
  String get neonEffectsOn => 'Izgara çizgileri ve kartlarda neon vurgular.';

  @override
  String get neonEffectsUnlock => 'Pro için dokun';

  @override
  String get account => 'Hesap';

  @override
  String get googleAccount => 'Google hesabı';

  @override
  String get connected => 'Bağlı';

  @override
  String get signOut => 'Çıkış yap';

  @override
  String get saveWithAccount => 'Hesabınla kaydet';

  @override
  String get recoverPremium => 'Premium\'u yeni cihazlarda geri yükle';

  @override
  String get tapToLink => 'Karta dokun veya sağdaki Bağla\'ya bas';

  @override
  String get linkButton => 'Bağla';

  @override
  String get accountWarning =>
      'Giriş yapmazsan bu cihazdaki verilerini kaybedebilirsin. Her yerden erişmek için Google hesabını bağla.';

  @override
  String get privacyPolicy => 'Gizlilik Politikası';

  @override
  String get termsOfUse => 'Kullanım Şartları';

  @override
  String get duelLabel => 'DÜELLO';

  @override
  String get notesAction => 'Notlar';

  @override
  String get eraseAction => 'Sil';

  @override
  String get celebrationDuelWin => 'Kazandın!';

  @override
  String get celebrationDailyDone => 'Günlük Tamam!';

  @override
  String get celebrationSolo => 'Harika!';

  @override
  String get duelFinishedFirst => 'Önce sen bitirdin! 🏆';

  @override
  String get soloPerfect => 'Sudoku\'yu kusursuz çözdün ✨';

  @override
  String get streakStarted => '1 günlük seri başladı!';

  @override
  String streakDays(int count) {
    return '$count günlük seri!';
  }

  @override
  String get perfectScore => 'Kusursuz skor!';

  @override
  String get statTime => 'Süre';

  @override
  String get statMistakes => 'Hata';

  @override
  String get statHints => 'İpucu';

  @override
  String get hintsOff => 'Kapalı';

  @override
  String hintsUsed(int count) {
    return '$count kullanıldı';
  }

  @override
  String get newGame => 'Yeni Oyun';

  @override
  String get mainMenu => 'Ana Menü';

  @override
  String get gameOver => 'Oyun Bitti';

  @override
  String get lostMessage => 'Hata hakkın bitti.\nTekrar dene, acele etme!';

  @override
  String get watchAdContinue => 'Reklam İzle — Devam Et';

  @override
  String get watchAdSubtitle => 'Bir ekstra hata hakkı — ücretsiz';

  @override
  String get tryAgain => 'Tekrar Dene';

  @override
  String get getReady => 'Hazır ol…';

  @override
  String get storeUnavailable =>
      'Mağaza şu an kullanılamıyor. Lütfen tekrar deneyin.';

  @override
  String get purchaseNotConfirmed =>
      'Satın alma onaylanamadı. Lütfen tekrar deneyin.';

  @override
  String get purchaseFailed => 'Satın alma başarısız. Lütfen tekrar deneyin.';

  @override
  String get appleSignInFailed =>
      'Apple ile giriş başarısız. Lütfen tekrar deneyin.';

  @override
  String dailyMistakesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hata',
      one: '$count hata',
    );
    return '$_temp0';
  }

  @override
  String get complete => 'Tamam';

  @override
  String get lives => 'Can';

  @override
  String get mute => 'Sesi kapat';

  @override
  String get unmute => 'Sesi aç';

  @override
  String get hintUnlimited => 'İpucu (sınırsız)';

  @override
  String hintLeft(int count) {
    return 'İpucu ($count kaldı)';
  }

  @override
  String get getMoreHints => 'Daha fazla ipucu al';

  @override
  String get resume => 'Devam et';

  @override
  String get pause => 'Duraklat';

  @override
  String get getAHint => 'İpucu Al';

  @override
  String get getAHintSubtitle => 'Bir sonraki ipucunu nasıl almak istersin?';

  @override
  String get watchShortAd => 'Kısa bir reklam izle';

  @override
  String get watchShortAdSubtitle => 'Ücretsiz — yaklaşık 30 saniye sürer';

  @override
  String get useHintCoin => 'İpucu jetonu kullan';

  @override
  String hintCoinsYouHave(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jetonun var',
      one: '$count jetonun var',
    );
    return '$_temp0';
  }

  @override
  String hintCoinsPack(String price) {
    return '10 ipucu jetonu — $price';
  }

  @override
  String get hintCoinsPackSubtitle =>
      'Tek seferlik satın alma, istediğin zaman kullan';

  @override
  String get unlockProUnlimitedHints => 'Pro\'yu Aç — Sınırsız ipucu';

  @override
  String get unlockProUnlimitedHintsSubtitle =>
      'Reklamsız · Neon efektler · En iyi değer';

  @override
  String get adNotAvailable =>
      'Reklam kullanılamıyor — daha sonra tekrar dene.';

  @override
  String get opponentLeftYouWin => 'Rakip oyundan ayrıldı — kazandın! 🎉';

  @override
  String get signOutConfirm =>
      'Google hesabından çıkış yapmak istediğine emin misin?';

  @override
  String get googleSignInCouldNotFinish =>
      'Google girişi tamamlanamadı (iptal edildi veya hata oluştu). Tekrar dene; sorun sürerse internetini, Play Store güncellemeni ve cihazının tarih & saat ayarlarını kontrol et.';

  @override
  String get premiumRestored => 'Premium başarıyla geri yüklendi.';

  @override
  String googleAccountLinked(String account) {
    return 'Google hesabı bağlandı: $account';
  }

  @override
  String get unlockProTitle => 'Pro\'yu Aç';

  @override
  String get unlockProSubtitle =>
      'Tek seferlik satın alma — sonsuza dek senin.';

  @override
  String get featureUnlimitedHints => 'Sınırsız ipucu — asla tükenmez';

  @override
  String get featureNoAds => 'Reklam yok — hiçbir zaman';

  @override
  String get featureNeonStyle => 'Her renk temasında neon stil';

  @override
  String get featureSupportDev => 'Bağımsız bir geliştiriciyi destekle';

  @override
  String unlockForPrice(String price) {
    return '$price ile aç';
  }

  @override
  String get loadingPrice => 'Fiyat yükleniyor…';

  @override
  String get restorePurchases => 'Satın alımları geri yükle';

  @override
  String get restoreFailed => 'Geri yükleme başarısız. Tekrar dene.';

  @override
  String get signingIn => 'Giriş yapılıyor…';

  @override
  String get signInWithGoogleRecover =>
      'Premium\'u geri yüklemek için Google ile giriş yap';

  @override
  String get tryAgainShort => 'Tekrar dene';

  @override
  String get loadingShort => 'Yükleniyor…';

  @override
  String get storeUnavailableAndroid =>
      'Play Store\'a şu an ulaşılamıyor.\nİnternet bağlantını kontrol et.';

  @override
  String get storeUnavailableIos =>
      'App Store\'a şu an ulaşılamıyor.\nİnternet bağlantını kontrol et.';

  @override
  String get productNotFoundAndroid =>
      'Premium ürünü mağazada henüz mevcut değil.\nUygulamayı Google Play\'den yüklediğinden emin ol veya daha sonra tekrar dene.';

  @override
  String get productNotFoundIos =>
      'Premium ürünü henüz mevcut değil.\nBirazdan tekrar dene.';

  @override
  String get queryErrorAndroid =>
      'Fiyat bilgisi yüklenemedi.\nUygulama Play Store üzerinden yüklenmiş olmalı; bağlantını kontrol et.';

  @override
  String get queryErrorIos =>
      'Fiyat bilgisi yüklenemedi.\nİnternet bağlantını kontrol edip tekrar dene.';

  @override
  String get storeInfoErrorAndroid =>
      'Mağaza bilgisi yüklenemedi.\nUygulamanın Google Play sürümünü kullandığından emin ol.';

  @override
  String get storeInfoErrorIos =>
      'Mağaza bilgisi yüklenemedi.\nİnternet bağlantını kontrol edip tekrar dene.';

  @override
  String get duelDifficulty => 'Zorluk';

  @override
  String get duelHost => 'Kur';

  @override
  String get duelJoin => 'Katıl';

  @override
  String get duelNoHints => 'İpucu Yok';

  @override
  String get duelSamePuzzle => 'Aynı Bulmaca';

  @override
  String get duelLiveSync => 'Canlı Eşitleme';

  @override
  String get duelOffline => 'Çevrimdışı';

  @override
  String get duelRaceTitle => 'DÜELLO YARIŞI';

  @override
  String get duelRaceTagline => 'Aynı bulmaca • İlk doğru bitiren kazanır';

  @override
  String get duelOnlineSyncedStart => 'Çevrimiçi Eşzamanlı Başlangıç';

  @override
  String get duelOnlineSyncedStartSubtitle =>
      'Kuran kişi yarışı iki oyuncu için aynı anda başlatır';

  @override
  String get duelCreateRoomHint => 'Bir oda oluştur ve kodu rakibinle paylaş.';

  @override
  String get duelCreateRoom => 'Oda Oluştur';

  @override
  String get duelStartRaceBoth => 'Yarışı Başlat — Her İki Cihaz';

  @override
  String get duelStartPuzzleOffline => 'Bulmacayı Başlat (Çevrimdışı)';

  @override
  String get duelRoomCodeLabelCaps => 'ODA KODU';

  @override
  String get duelCopyCode => 'Kodu kopyala';

  @override
  String get duelCancelRoom => 'Odayı iptal et';

  @override
  String get duelJoinHint => 'Kuran kişinin paylaştığı oda kodunu gir.';

  @override
  String get duelRoomCodeLabel => 'Oda kodu';

  @override
  String get duelJoinRaceOnline => 'Yarışa Katıl — Çevrimiçi';

  @override
  String get duelJoinRace => 'Yarışa Katıl';

  @override
  String get duelJoinedSuccessfully => 'Başarıyla katıldın!';

  @override
  String get duelWaitingForHost =>
      'Kuran kişinin yarışı başlatması bekleniyor…';

  @override
  String get duelLeaveRoom => 'Odadan Ayrıl';

  @override
  String get duelCodeCopied => 'Kod kopyalandı';

  @override
  String get duelInvalidRoomCode => 'Geçersiz oda kodu';

  @override
  String get duelConnectError =>
      'Sunucuya bağlanılamadı. İnternet bağlantını kontrol et.';

  @override
  String get duelStartRaceError =>
      'Yarış başlatılamadı. Bağlantını kontrol et.';

  @override
  String get duelRaceAlreadyStarted =>
      'Yarış zaten başladı — katılmak için çok geç.';

  @override
  String get duelRoomNotFound =>
      'Oda bulunamadı. Kodu kontrol edip tekrar dene.';

  @override
  String get updateAvailableTitle => 'Güncelleme mevcut';

  @override
  String get updateAvailableLater => 'Sonra';

  @override
  String updateAvailableBodyBuild(int build) {
    return 'Google Play\'de daha yeni bir sürüm hazır (build $build). En son düzeltmeler ve iyileştirmeler için güncelle.';
  }

  @override
  String get updateAvailableBody =>
      'Google Play\'de daha yeni bir sürüm hazır. En son düzeltmeler ve iyileştirmeler için güncelle.';

  @override
  String get updateNow => 'Şimdi güncelle';

  @override
  String get notNow => 'Şimdi değil';

  @override
  String get signInCanceled => 'Giriş iptal edildi.';

  @override
  String get googleSignInFailedRetry =>
      'Google girişi şu an tamamlanamıyor. İnternet bağlantını kontrol edip birazdan tekrar dene.';

  @override
  String get googleSignInGenericError =>
      'Google ile bağlanılamadı. Lütfen daha sonra tekrar dene.';

  @override
  String get proRestoreNotFoundIos =>
      'Kayıtlı bir Premium satın alımı bulunamadı. Premium\'u ilk satın aldığın Apple ID ile giriş yaptığından emin ol, sonra tekrar Satın alımları geri yükle\'ye dokun.';

  @override
  String get proRestoreNotFoundAndroid =>
      'Kayıtlı bir Premium satın alımı bulunamadı. Play Store\'da Premium\'u satın aldığın Google hesabıyla giriş yaptığından emin ol; uygulamada aynı hesabı bağlayıp tekrar Satın alımları geri yükle\'ye dokun.';
}
