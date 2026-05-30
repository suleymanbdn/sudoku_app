import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Sudoku'**
  String get appTitle;

  /// No description provided for @navPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get navPlay;

  /// No description provided for @navScores.
  ///
  /// In en, this message translates to:
  /// **'Scores'**
  String get navScores;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @preparingPuzzle.
  ///
  /// In en, this message translates to:
  /// **'Preparing puzzle…'**
  String get preparingPuzzle;

  /// No description provided for @okButton.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @whichDifficultyToday.
  ///
  /// In en, this message translates to:
  /// **'Which difficulty will you try today?'**
  String get whichDifficultyToday;

  /// No description provided for @proBadge.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get proBadge;

  /// No description provided for @continueGame.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueGame;

  /// No description provided for @continueProgress.
  ///
  /// In en, this message translates to:
  /// **'{difficulty} · {percent}% complete'**
  String continueProgress(String difficulty, int percent);

  /// No description provided for @startNewGame.
  ///
  /// In en, this message translates to:
  /// **'Start New Game'**
  String get startNewGame;

  /// No description provided for @difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// No description provided for @difficultyExpert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get difficultyExpert;

  /// No description provided for @difficultyEasySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Warm up your mind'**
  String get difficultyEasySubtitle;

  /// No description provided for @difficultyMediumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Solid challenge'**
  String get difficultyMediumSubtitle;

  /// No description provided for @difficultyHardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sharp and demanding'**
  String get difficultyHardSubtitle;

  /// No description provided for @difficultyExpertSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ultra sparse · only for masters'**
  String get difficultyExpertSubtitle;

  /// No description provided for @badgeBronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get badgeBronze;

  /// No description provided for @badgeSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get badgeSilver;

  /// No description provided for @badgeGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get badgeGold;

  /// No description provided for @badgeDiamond.
  ///
  /// In en, this message translates to:
  /// **'Diamond'**
  String get badgeDiamond;

  /// No description provided for @duelRace.
  ///
  /// In en, this message translates to:
  /// **'Duel race'**
  String get duelRace;

  /// No description provided for @duelRaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Same puzzle — first correct finish wins'**
  String get duelRaceSubtitle;

  /// No description provided for @dailyChallenge.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenge'**
  String get dailyChallenge;

  /// No description provided for @playButton.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playButton;

  /// No description provided for @dailyCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed!'**
  String get dailyCompleted;

  /// No description provided for @dailyPerfect.
  ///
  /// In en, this message translates to:
  /// **'Perfect! 🎉'**
  String get dailyPerfect;

  /// No description provided for @goProTitle.
  ///
  /// In en, this message translates to:
  /// **'⚡ Go Pro'**
  String get goProTitle;

  /// No description provided for @goProSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hard, Expert & neon look — one-time purchase'**
  String get goProSubtitle;

  /// No description provided for @buyButton.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buyButton;

  /// No description provided for @myScores.
  ///
  /// In en, this message translates to:
  /// **'My scores'**
  String get myScores;

  /// No description provided for @totalWins.
  ///
  /// In en, this message translates to:
  /// **'total wins'**
  String get totalWins;

  /// No description provided for @dayStreak.
  ///
  /// In en, this message translates to:
  /// **'🔥 day streak'**
  String get dayStreak;

  /// No description provided for @byDifficulty.
  ///
  /// In en, this message translates to:
  /// **'By difficulty'**
  String get byDifficulty;

  /// No description provided for @noWinsYet.
  ///
  /// In en, this message translates to:
  /// **'No wins yet'**
  String get noWinsYet;

  /// No description provided for @noWinsYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Win your first game —\nstats will show up here.'**
  String get noWinsYetSubtitle;

  /// No description provided for @winsLabel.
  ///
  /// In en, this message translates to:
  /// **'wins'**
  String get winsLabel;

  /// No description provided for @noWinsShort.
  ///
  /// In en, this message translates to:
  /// **'no wins yet'**
  String get noWinsShort;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearanceLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceLight;

  /// No description provided for @appearanceDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceDark;

  /// No description provided for @colorTheme.
  ///
  /// In en, this message translates to:
  /// **'Color theme'**
  String get colorTheme;

  /// No description provided for @neonEffects.
  ///
  /// In en, this message translates to:
  /// **'Neon effects'**
  String get neonEffects;

  /// No description provided for @glowAndHighlights.
  ///
  /// In en, this message translates to:
  /// **'Glow & highlights'**
  String get glowAndHighlights;

  /// No description provided for @neonEffectsOn.
  ///
  /// In en, this message translates to:
  /// **'Neon accents on grid lines and cards.'**
  String get neonEffectsOn;

  /// No description provided for @neonEffectsUnlock.
  ///
  /// In en, this message translates to:
  /// **'Tap to unlock Pro'**
  String get neonEffectsUnlock;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @googleAccount.
  ///
  /// In en, this message translates to:
  /// **'Google account'**
  String get googleAccount;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @saveWithAccount.
  ///
  /// In en, this message translates to:
  /// **'Save with your account'**
  String get saveWithAccount;

  /// No description provided for @recoverPremium.
  ///
  /// In en, this message translates to:
  /// **'Recover Premium on new devices'**
  String get recoverPremium;

  /// No description provided for @tapToLink.
  ///
  /// In en, this message translates to:
  /// **'Tap the card or Link on the right'**
  String get tapToLink;

  /// No description provided for @linkButton.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get linkButton;

  /// No description provided for @accountWarning.
  ///
  /// In en, this message translates to:
  /// **'Without signing in you may lose your data on this device. Link your Google account to access it everywhere.'**
  String get accountWarning;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @duelLabel.
  ///
  /// In en, this message translates to:
  /// **'DUEL'**
  String get duelLabel;

  /// No description provided for @notesAction.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesAction;

  /// No description provided for @eraseAction.
  ///
  /// In en, this message translates to:
  /// **'Erase'**
  String get eraseAction;

  /// No description provided for @celebrationDuelWin.
  ///
  /// In en, this message translates to:
  /// **'You win!'**
  String get celebrationDuelWin;

  /// No description provided for @celebrationDailyDone.
  ///
  /// In en, this message translates to:
  /// **'Daily Done!'**
  String get celebrationDailyDone;

  /// No description provided for @celebrationSolo.
  ///
  /// In en, this message translates to:
  /// **'Amazing!'**
  String get celebrationSolo;

  /// No description provided for @duelFinishedFirst.
  ///
  /// In en, this message translates to:
  /// **'You finished first! 🏆'**
  String get duelFinishedFirst;

  /// No description provided for @soloPerfect.
  ///
  /// In en, this message translates to:
  /// **'You completed the Sudoku perfectly ✨'**
  String get soloPerfect;

  /// No description provided for @streakStarted.
  ///
  /// In en, this message translates to:
  /// **'Day 1 streak started!'**
  String get streakStarted;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count} day streak!'**
  String streakDays(int count);

  /// No description provided for @perfectScore.
  ///
  /// In en, this message translates to:
  /// **'Perfect score!'**
  String get perfectScore;

  /// No description provided for @statTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get statTime;

  /// No description provided for @statMistakes.
  ///
  /// In en, this message translates to:
  /// **'Mistakes'**
  String get statMistakes;

  /// No description provided for @statHints.
  ///
  /// In en, this message translates to:
  /// **'Hints'**
  String get statHints;

  /// No description provided for @hintsOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get hintsOff;

  /// No description provided for @hintsUsed.
  ///
  /// In en, this message translates to:
  /// **'{count} used'**
  String hintsUsed(int count);

  /// No description provided for @newGame.
  ///
  /// In en, this message translates to:
  /// **'New Game'**
  String get newGame;

  /// No description provided for @mainMenu.
  ///
  /// In en, this message translates to:
  /// **'Main Menu'**
  String get mainMenu;

  /// No description provided for @gameOver.
  ///
  /// In en, this message translates to:
  /// **'Game Over'**
  String get gameOver;

  /// No description provided for @lostMessage.
  ///
  /// In en, this message translates to:
  /// **'You ran out of mistakes.\nTry again and take your time!'**
  String get lostMessage;

  /// No description provided for @watchAdContinue.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad — Continue'**
  String get watchAdContinue;

  /// No description provided for @watchAdSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get one extra mistake — free'**
  String get watchAdSubtitle;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @getReady.
  ///
  /// In en, this message translates to:
  /// **'Get ready…'**
  String get getReady;

  /// No description provided for @storeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The store is unavailable. Please try again.'**
  String get storeUnavailable;

  /// No description provided for @purchaseNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Purchase could not be confirmed. Please try again.'**
  String get purchaseNotConfirmed;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed. Please try again.'**
  String get purchaseFailed;

  /// No description provided for @appleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple failed. Please try again.'**
  String get appleSignInFailed;

  /// No description provided for @dailyMistakesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} mistake} other{{count} mistakes}}'**
  String dailyMistakesCount(int count);

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @lives.
  ///
  /// In en, this message translates to:
  /// **'Lives'**
  String get lives;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @hintUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Hint (unlimited)'**
  String get hintUnlimited;

  /// No description provided for @hintLeft.
  ///
  /// In en, this message translates to:
  /// **'Hint ({count} left)'**
  String hintLeft(int count);

  /// No description provided for @getMoreHints.
  ///
  /// In en, this message translates to:
  /// **'Get more hints'**
  String get getMoreHints;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @getAHint.
  ///
  /// In en, this message translates to:
  /// **'Get a Hint'**
  String get getAHint;

  /// No description provided for @getAHintSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you\'d like your next hint'**
  String get getAHintSubtitle;

  /// No description provided for @watchShortAd.
  ///
  /// In en, this message translates to:
  /// **'Watch a short ad'**
  String get watchShortAd;

  /// No description provided for @watchShortAdSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Free — takes about 30 seconds'**
  String get watchShortAdSubtitle;

  /// No description provided for @useHintCoin.
  ///
  /// In en, this message translates to:
  /// **'Use a hint coin'**
  String get useHintCoin;

  /// No description provided for @hintCoinsYouHave.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{You have {count} coin} other{You have {count} coins}}'**
  String hintCoinsYouHave(int count);

  /// No description provided for @hintCoinsPack.
  ///
  /// In en, this message translates to:
  /// **'10 hint coins — {price}'**
  String hintCoinsPack(String price);

  /// No description provided for @hintCoinsPackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One-time purchase, use anytime'**
  String get hintCoinsPackSubtitle;

  /// No description provided for @unlockProUnlimitedHints.
  ///
  /// In en, this message translates to:
  /// **'Unlock Pro — Unlimited hints'**
  String get unlockProUnlimitedHints;

  /// No description provided for @unlockProUnlimitedHintsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No ads · Neon effects · Best value'**
  String get unlockProUnlimitedHintsSubtitle;

  /// No description provided for @adNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Ad not available — try again later.'**
  String get adNotAvailable;

  /// No description provided for @opponentLeftYouWin.
  ///
  /// In en, this message translates to:
  /// **'Opponent left the game — you win! 🎉'**
  String get opponentLeftYouWin;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out of your Google account?'**
  String get signOutConfirm;

  /// No description provided for @googleSignInCouldNotFinish.
  ///
  /// In en, this message translates to:
  /// **'Could not finish Google sign-in (canceled or error). Try again; if it keeps failing, check your internet, update the Play Store, and your device date & time settings.'**
  String get googleSignInCouldNotFinish;

  /// No description provided for @premiumRestored.
  ///
  /// In en, this message translates to:
  /// **'Premium restored successfully.'**
  String get premiumRestored;

  /// No description provided for @googleAccountLinked.
  ///
  /// In en, this message translates to:
  /// **'Google account linked: {account}'**
  String googleAccountLinked(String account);

  /// No description provided for @unlockProTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Pro'**
  String get unlockProTitle;

  /// No description provided for @unlockProSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One-time purchase — yours forever.'**
  String get unlockProSubtitle;

  /// No description provided for @featureUnlimitedHints.
  ///
  /// In en, this message translates to:
  /// **'Unlimited hints — never run out'**
  String get featureUnlimitedHints;

  /// No description provided for @featureNoAds.
  ///
  /// In en, this message translates to:
  /// **'No ads — ever'**
  String get featureNoAds;

  /// No description provided for @featureNeonStyle.
  ///
  /// In en, this message translates to:
  /// **'Neon style on every color theme'**
  String get featureNeonStyle;

  /// No description provided for @featureSupportDev.
  ///
  /// In en, this message translates to:
  /// **'Support an indie developer'**
  String get featureSupportDev;

  /// No description provided for @unlockForPrice.
  ///
  /// In en, this message translates to:
  /// **'Unlock for {price}'**
  String unlockForPrice(String price);

  /// No description provided for @loadingPrice.
  ///
  /// In en, this message translates to:
  /// **'Loading price…'**
  String get loadingPrice;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed. Try again.'**
  String get restoreFailed;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signingIn;

  /// No description provided for @signInWithGoogleRecover.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google to recover Premium'**
  String get signInWithGoogleRecover;

  /// No description provided for @tryAgainShort.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgainShort;

  /// No description provided for @loadingShort.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loadingShort;

  /// No description provided for @storeUnavailableAndroid.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the Play Store right now.\nCheck your internet connection.'**
  String get storeUnavailableAndroid;

  /// No description provided for @storeUnavailableIos.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the App Store right now.\nCheck your internet connection.'**
  String get storeUnavailableIos;

  /// No description provided for @productNotFoundAndroid.
  ///
  /// In en, this message translates to:
  /// **'The Premium product is not available in the store yet.\nMake sure you installed the app from Google Play, or try again later.'**
  String get productNotFoundAndroid;

  /// No description provided for @productNotFoundIos.
  ///
  /// In en, this message translates to:
  /// **'The Premium product is not available yet.\nTry again in a moment.'**
  String get productNotFoundIos;

  /// No description provided for @queryErrorAndroid.
  ///
  /// In en, this message translates to:
  /// **'Could not load price info.\nThe app should be installed via the Play Store; check your connection.'**
  String get queryErrorAndroid;

  /// No description provided for @queryErrorIos.
  ///
  /// In en, this message translates to:
  /// **'Could not load price info.\nCheck your internet connection and try again.'**
  String get queryErrorIos;

  /// No description provided for @storeInfoErrorAndroid.
  ///
  /// In en, this message translates to:
  /// **'Could not load store info.\nMake sure you are using the Google Play build of the app.'**
  String get storeInfoErrorAndroid;

  /// No description provided for @storeInfoErrorIos.
  ///
  /// In en, this message translates to:
  /// **'Could not load store info.\nCheck your internet connection and try again.'**
  String get storeInfoErrorIos;

  /// No description provided for @duelDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get duelDifficulty;

  /// No description provided for @duelHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get duelHost;

  /// No description provided for @duelJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get duelJoin;

  /// No description provided for @duelNoHints.
  ///
  /// In en, this message translates to:
  /// **'No Hints'**
  String get duelNoHints;

  /// No description provided for @duelSamePuzzle.
  ///
  /// In en, this message translates to:
  /// **'Same Puzzle'**
  String get duelSamePuzzle;

  /// No description provided for @duelLiveSync.
  ///
  /// In en, this message translates to:
  /// **'Live Sync'**
  String get duelLiveSync;

  /// No description provided for @duelOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get duelOffline;

  /// No description provided for @duelRaceTitle.
  ///
  /// In en, this message translates to:
  /// **'DUEL RACE'**
  String get duelRaceTitle;

  /// No description provided for @duelRaceTagline.
  ///
  /// In en, this message translates to:
  /// **'Same puzzle • First correct finish wins'**
  String get duelRaceTagline;

  /// No description provided for @duelOnlineSyncedStart.
  ///
  /// In en, this message translates to:
  /// **'Online Synced Start'**
  String get duelOnlineSyncedStart;

  /// No description provided for @duelOnlineSyncedStartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Host launches the race for both players simultaneously'**
  String get duelOnlineSyncedStartSubtitle;

  /// No description provided for @duelCreateRoomHint.
  ///
  /// In en, this message translates to:
  /// **'Create a room and share the code with your opponent.'**
  String get duelCreateRoomHint;

  /// No description provided for @duelCreateRoom.
  ///
  /// In en, this message translates to:
  /// **'Create Room'**
  String get duelCreateRoom;

  /// No description provided for @duelStartRaceBoth.
  ///
  /// In en, this message translates to:
  /// **'Start Race — Both Devices'**
  String get duelStartRaceBoth;

  /// No description provided for @duelStartPuzzleOffline.
  ///
  /// In en, this message translates to:
  /// **'Start Puzzle (Offline)'**
  String get duelStartPuzzleOffline;

  /// No description provided for @duelRoomCodeLabelCaps.
  ///
  /// In en, this message translates to:
  /// **'ROOM CODE'**
  String get duelRoomCodeLabelCaps;

  /// No description provided for @duelCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get duelCopyCode;

  /// No description provided for @duelCancelRoom.
  ///
  /// In en, this message translates to:
  /// **'Cancel room'**
  String get duelCancelRoom;

  /// No description provided for @duelJoinHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the room code shared by the host.'**
  String get duelJoinHint;

  /// No description provided for @duelRoomCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Room code'**
  String get duelRoomCodeLabel;

  /// No description provided for @duelJoinRaceOnline.
  ///
  /// In en, this message translates to:
  /// **'Join Race — Online'**
  String get duelJoinRaceOnline;

  /// No description provided for @duelJoinRace.
  ///
  /// In en, this message translates to:
  /// **'Join Race'**
  String get duelJoinRace;

  /// No description provided for @duelJoinedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Joined successfully!'**
  String get duelJoinedSuccessfully;

  /// No description provided for @duelWaitingForHost.
  ///
  /// In en, this message translates to:
  /// **'Waiting for host to start the race…'**
  String get duelWaitingForHost;

  /// No description provided for @duelLeaveRoom.
  ///
  /// In en, this message translates to:
  /// **'Leave Room'**
  String get duelLeaveRoom;

  /// No description provided for @duelCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get duelCodeCopied;

  /// No description provided for @duelInvalidRoomCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid room code'**
  String get duelInvalidRoomCode;

  /// No description provided for @duelConnectError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to server. Check your internet connection.'**
  String get duelConnectError;

  /// No description provided for @duelStartRaceError.
  ///
  /// In en, this message translates to:
  /// **'Could not start the race. Check your connection.'**
  String get duelStartRaceError;

  /// No description provided for @duelRaceAlreadyStarted.
  ///
  /// In en, this message translates to:
  /// **'Race already started — too late to join.'**
  String get duelRaceAlreadyStarted;

  /// No description provided for @duelRoomNotFound.
  ///
  /// In en, this message translates to:
  /// **'Room not found. Check the code and try again.'**
  String get duelRoomNotFound;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateAvailableLater;

  /// No description provided for @updateAvailableBodyBuild.
  ///
  /// In en, this message translates to:
  /// **'A newer version is ready on Google Play (build {build}). Update for the latest fixes and improvements.'**
  String updateAvailableBodyBuild(int build);

  /// No description provided for @updateAvailableBody.
  ///
  /// In en, this message translates to:
  /// **'A newer version is ready on Google Play. Update for the latest fixes and improvements.'**
  String get updateAvailableBody;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @signInCanceled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in canceled.'**
  String get signInCanceled;

  /// No description provided for @googleSignInFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in cannot finish right now. Check your internet connection and try again in a moment.'**
  String get googleSignInFailedRetry;

  /// No description provided for @googleSignInGenericError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect with Google. Please try again later.'**
  String get googleSignInGenericError;

  /// No description provided for @proRestoreNotFoundIos.
  ///
  /// In en, this message translates to:
  /// **'No saved Premium purchase found. Make sure you are signed in with the Apple ID that originally bought Premium, then tap Restore purchases again.'**
  String get proRestoreNotFoundIos;

  /// No description provided for @proRestoreNotFoundAndroid.
  ///
  /// In en, this message translates to:
  /// **'No saved Premium purchase found. In the Play Store, make sure you are signed in with the Google account that bought Premium; in the app, link the same account and tap Restore purchases again.'**
  String get proRestoreNotFoundAndroid;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
