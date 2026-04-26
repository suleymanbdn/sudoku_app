/// Google Play listing for this app (must match [applicationId] in Android).
const kPlayStorePackageId = 'com.sudokubulmaca.app';

Uri get playStoreHttpsUri => Uri.parse(
      'https://play.google.com/store/apps/details?id=$kPlayStorePackageId',
    );

Uri get playStoreMarketUri =>
    Uri.parse('market://details?id=$kPlayStorePackageId');
