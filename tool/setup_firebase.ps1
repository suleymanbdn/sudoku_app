# Re-runs FlutterFire for this repo (uses saved Firebase login). Firestore: firebase deploy --only firestore
# Run: powershell -ExecutionPolicy Bypass -File tool\setup_firebase.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

dart pub global activate flutterfire_cli | Out-Null
dart pub global run flutterfire_cli:flutterfire configure --project=zen-sudoku-no-ads --yes --platforms=android,ios --android-package-name=com.sudokubulmaca.app --ios-bundle-id=com.sudoku.sudoku --overwrite-firebase-options
