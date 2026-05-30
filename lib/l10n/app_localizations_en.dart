// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sudoku';

  @override
  String get navPlay => 'Play';

  @override
  String get navScores => 'Scores';

  @override
  String get navSettings => 'Settings';

  @override
  String get preparingPuzzle => 'Preparing puzzle…';

  @override
  String get okButton => 'OK';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get whichDifficultyToday => 'Which difficulty will you try today?';

  @override
  String get proBadge => 'PRO';

  @override
  String get continueGame => 'Continue';

  @override
  String continueProgress(String difficulty, int percent) {
    return '$difficulty · $percent% complete';
  }

  @override
  String get startNewGame => 'Start New Game';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get difficultyExpert => 'Expert';

  @override
  String get difficultyEasySubtitle => 'Warm up your mind';

  @override
  String get difficultyMediumSubtitle => 'Solid challenge';

  @override
  String get difficultyHardSubtitle => 'Sharp and demanding';

  @override
  String get difficultyExpertSubtitle => 'Ultra sparse · only for masters';

  @override
  String get badgeBronze => 'Bronze';

  @override
  String get badgeSilver => 'Silver';

  @override
  String get badgeGold => 'Gold';

  @override
  String get badgeDiamond => 'Diamond';

  @override
  String get duelRace => 'Duel race';

  @override
  String get duelRaceSubtitle => 'Same puzzle — first correct finish wins';

  @override
  String get dailyChallenge => 'Daily Challenge';

  @override
  String get playButton => 'Play';

  @override
  String get dailyCompleted => 'Completed!';

  @override
  String get dailyPerfect => 'Perfect! 🎉';

  @override
  String get goProTitle => '⚡ Go Pro';

  @override
  String get goProSubtitle => 'Hard, Expert & neon look — one-time purchase';

  @override
  String get buyButton => 'Buy';

  @override
  String get myScores => 'My scores';

  @override
  String get totalWins => 'total wins';

  @override
  String get dayStreak => '🔥 day streak';

  @override
  String get byDifficulty => 'By difficulty';

  @override
  String get noWinsYet => 'No wins yet';

  @override
  String get noWinsYetSubtitle =>
      'Win your first game —\nstats will show up here.';

  @override
  String get winsLabel => 'wins';

  @override
  String get noWinsShort => 'no wins yet';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get colorTheme => 'Color theme';

  @override
  String get neonEffects => 'Neon effects';

  @override
  String get glowAndHighlights => 'Glow & highlights';

  @override
  String get neonEffectsOn => 'Neon accents on grid lines and cards.';

  @override
  String get neonEffectsUnlock => 'Tap to unlock Pro';

  @override
  String get account => 'Account';

  @override
  String get googleAccount => 'Google account';

  @override
  String get connected => 'Connected';

  @override
  String get signOut => 'Sign out';

  @override
  String get saveWithAccount => 'Save with your account';

  @override
  String get recoverPremium => 'Recover Premium on new devices';

  @override
  String get tapToLink => 'Tap the card or Link on the right';

  @override
  String get linkButton => 'Link';

  @override
  String get accountWarning =>
      'Without signing in you may lose your data on this device. Link your Google account to access it everywhere.';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get duelLabel => 'DUEL';

  @override
  String get notesAction => 'Notes';

  @override
  String get eraseAction => 'Erase';

  @override
  String get celebrationDuelWin => 'You win!';

  @override
  String get celebrationDailyDone => 'Daily Done!';

  @override
  String get celebrationSolo => 'Amazing!';

  @override
  String get duelFinishedFirst => 'You finished first! 🏆';

  @override
  String get soloPerfect => 'You completed the Sudoku perfectly ✨';

  @override
  String get streakStarted => 'Day 1 streak started!';

  @override
  String streakDays(int count) {
    return '$count day streak!';
  }

  @override
  String get perfectScore => 'Perfect score!';

  @override
  String get statTime => 'Time';

  @override
  String get statMistakes => 'Mistakes';

  @override
  String get statHints => 'Hints';

  @override
  String get hintsOff => 'Off';

  @override
  String hintsUsed(int count) {
    return '$count used';
  }

  @override
  String get newGame => 'New Game';

  @override
  String get mainMenu => 'Main Menu';

  @override
  String get gameOver => 'Game Over';

  @override
  String get lostMessage =>
      'You ran out of mistakes.\nTry again and take your time!';

  @override
  String get watchAdContinue => 'Watch Ad — Continue';

  @override
  String get watchAdSubtitle => 'Get one extra mistake — free';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get getReady => 'Get ready…';

  @override
  String get storeUnavailable => 'The store is unavailable. Please try again.';

  @override
  String get purchaseNotConfirmed =>
      'Purchase could not be confirmed. Please try again.';

  @override
  String get purchaseFailed => 'Purchase failed. Please try again.';

  @override
  String get appleSignInFailed =>
      'Sign in with Apple failed. Please try again.';

  @override
  String dailyMistakesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mistakes',
      one: '$count mistake',
    );
    return '$_temp0';
  }

  @override
  String get complete => 'Complete';

  @override
  String get lives => 'Lives';

  @override
  String get mute => 'Mute';

  @override
  String get unmute => 'Unmute';

  @override
  String get hintUnlimited => 'Hint (unlimited)';

  @override
  String hintLeft(int count) {
    return 'Hint ($count left)';
  }

  @override
  String get getMoreHints => 'Get more hints';

  @override
  String get resume => 'Resume';

  @override
  String get pause => 'Pause';

  @override
  String get getAHint => 'Get a Hint';

  @override
  String get getAHintSubtitle => 'Choose how you\'d like your next hint';

  @override
  String get watchShortAd => 'Watch a short ad';

  @override
  String get watchShortAdSubtitle => 'Free — takes about 30 seconds';

  @override
  String get useHintCoin => 'Use a hint coin';

  @override
  String hintCoinsYouHave(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You have $count coins',
      one: 'You have $count coin',
    );
    return '$_temp0';
  }

  @override
  String hintCoinsPack(String price) {
    return '10 hint coins — $price';
  }

  @override
  String get hintCoinsPackSubtitle => 'One-time purchase, use anytime';

  @override
  String get unlockProUnlimitedHints => 'Unlock Pro — Unlimited hints';

  @override
  String get unlockProUnlimitedHintsSubtitle =>
      'No ads · Neon effects · Best value';

  @override
  String get adNotAvailable => 'Ad not available — try again later.';

  @override
  String get opponentLeftYouWin => 'Opponent left the game — you win! 🎉';

  @override
  String get signOutConfirm =>
      'Are you sure you want to sign out of your Google account?';

  @override
  String get googleSignInCouldNotFinish =>
      'Could not finish Google sign-in (canceled or error). Try again; if it keeps failing, check your internet, update the Play Store, and your device date & time settings.';

  @override
  String get premiumRestored => 'Premium restored successfully.';

  @override
  String googleAccountLinked(String account) {
    return 'Google account linked: $account';
  }

  @override
  String get unlockProTitle => 'Unlock Pro';

  @override
  String get unlockProSubtitle => 'One-time purchase — yours forever.';

  @override
  String get featureUnlimitedHints => 'Unlimited hints — never run out';

  @override
  String get featureNoAds => 'No ads — ever';

  @override
  String get featureNeonStyle => 'Neon style on every color theme';

  @override
  String get featureSupportDev => 'Support an indie developer';

  @override
  String unlockForPrice(String price) {
    return 'Unlock for $price';
  }

  @override
  String get loadingPrice => 'Loading price…';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get restoreFailed => 'Restore failed. Try again.';

  @override
  String get signingIn => 'Signing in…';

  @override
  String get signInWithGoogleRecover =>
      'Sign in with Google to recover Premium';

  @override
  String get tryAgainShort => 'Try again';

  @override
  String get loadingShort => 'Loading…';

  @override
  String get storeUnavailableAndroid =>
      'Cannot reach the Play Store right now.\nCheck your internet connection.';

  @override
  String get storeUnavailableIos =>
      'Cannot reach the App Store right now.\nCheck your internet connection.';

  @override
  String get productNotFoundAndroid =>
      'The Premium product is not available in the store yet.\nMake sure you installed the app from Google Play, or try again later.';

  @override
  String get productNotFoundIos =>
      'The Premium product is not available yet.\nTry again in a moment.';

  @override
  String get queryErrorAndroid =>
      'Could not load price info.\nThe app should be installed via the Play Store; check your connection.';

  @override
  String get queryErrorIos =>
      'Could not load price info.\nCheck your internet connection and try again.';

  @override
  String get storeInfoErrorAndroid =>
      'Could not load store info.\nMake sure you are using the Google Play build of the app.';

  @override
  String get storeInfoErrorIos =>
      'Could not load store info.\nCheck your internet connection and try again.';

  @override
  String get duelDifficulty => 'Difficulty';

  @override
  String get duelHost => 'Host';

  @override
  String get duelJoin => 'Join';

  @override
  String get duelNoHints => 'No Hints';

  @override
  String get duelSamePuzzle => 'Same Puzzle';

  @override
  String get duelLiveSync => 'Live Sync';

  @override
  String get duelOffline => 'Offline';

  @override
  String get duelRaceTitle => 'DUEL RACE';

  @override
  String get duelRaceTagline => 'Same puzzle • First correct finish wins';

  @override
  String get duelOnlineSyncedStart => 'Online Synced Start';

  @override
  String get duelOnlineSyncedStartSubtitle =>
      'Host launches the race for both players simultaneously';

  @override
  String get duelCreateRoomHint =>
      'Create a room and share the code with your opponent.';

  @override
  String get duelCreateRoom => 'Create Room';

  @override
  String get duelStartRaceBoth => 'Start Race — Both Devices';

  @override
  String get duelStartPuzzleOffline => 'Start Puzzle (Offline)';

  @override
  String get duelRoomCodeLabelCaps => 'ROOM CODE';

  @override
  String get duelCopyCode => 'Copy code';

  @override
  String get duelCancelRoom => 'Cancel room';

  @override
  String get duelJoinHint => 'Enter the room code shared by the host.';

  @override
  String get duelRoomCodeLabel => 'Room code';

  @override
  String get duelJoinRaceOnline => 'Join Race — Online';

  @override
  String get duelJoinRace => 'Join Race';

  @override
  String get duelJoinedSuccessfully => 'Joined successfully!';

  @override
  String get duelWaitingForHost => 'Waiting for host to start the race…';

  @override
  String get duelLeaveRoom => 'Leave Room';

  @override
  String get duelCodeCopied => 'Code copied';

  @override
  String get duelInvalidRoomCode => 'Invalid room code';

  @override
  String get duelConnectError =>
      'Could not connect to server. Check your internet connection.';

  @override
  String get duelStartRaceError =>
      'Could not start the race. Check your connection.';

  @override
  String get duelRaceAlreadyStarted =>
      'Race already started — too late to join.';

  @override
  String get duelRoomNotFound =>
      'Room not found. Check the code and try again.';

  @override
  String get updateAvailableTitle => 'Update available';

  @override
  String get updateAvailableLater => 'Later';

  @override
  String updateAvailableBodyBuild(int build) {
    return 'A newer version is ready on Google Play (build $build). Update for the latest fixes and improvements.';
  }

  @override
  String get updateAvailableBody =>
      'A newer version is ready on Google Play. Update for the latest fixes and improvements.';

  @override
  String get updateNow => 'Update now';

  @override
  String get notNow => 'Not now';

  @override
  String get signInCanceled => 'Sign-in canceled.';

  @override
  String get googleSignInFailedRetry =>
      'Google sign-in cannot finish right now. Check your internet connection and try again in a moment.';

  @override
  String get googleSignInGenericError =>
      'Could not connect with Google. Please try again later.';

  @override
  String get proRestoreNotFoundIos =>
      'No saved Premium purchase found. Make sure you are signed in with the Apple ID that originally bought Premium, then tap Restore purchases again.';

  @override
  String get proRestoreNotFoundAndroid =>
      'No saved Premium purchase found. In the Play Store, make sure you are signed in with the Google account that bought Premium; in the app, link the same account and tap Restore purchases again.';
}
